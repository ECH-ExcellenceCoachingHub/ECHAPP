import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/widgets/analytics/dashboard_charts.dart';

/// Super admin analytics: every platform KPI for a chosen period, compared
/// with the previous period of the same length, with trends and breakdowns.
/// Data: GET /admin/analytics/overview?days=7|30|90|365.
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  /// Replaces the API call; for tests.
  @visibleForTesting
  final Future<Map<String, dynamic>> Function(int days)? loader;

  const AdminAnalyticsScreen({super.key, this.loader});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

// ----------------------------------------------------------- json helpers
Map<String, dynamic> _m(dynamic x) => x is Map ? x.cast<String, dynamic>() : <String, dynamic>{};
List _l(dynamic x) => x is List ? x : const [];
double _d(dynamic x) => x is num ? x.toDouble() : 0;
int _i(dynamic x) => x is num ? x.toInt() : 0;
List<double> _vals(dynamic series) => [for (final p in _l(series)) _d(_m(p)['value'])];
List<String> _keys(dynamic series) => [for (final p in _l(series)) '${_m(p)['date']}'];

const _periods = [(7, '7D', 'last 7 days'), (30, '30D', 'last 30 days'), (90, '90D', 'last 90 days'), (365, '12M', 'last 12 months')];

const _prettyLabels = {
  'mtn_momo': 'MTN MoMo',
  'airtel_money': 'Airtel Money',
  'card': 'Card',
  'free': 'Free',
  'course': 'Courses',
  'teacher_guide': 'Teacher guides',
  'school_term': 'School terms',
  'student': 'Students',
  'instructor': 'Teachers',
  'parent': 'Parents',
  'school_admin': 'School admins',
  'admin': 'Admins',
  'in-progress': 'In progress',
  'admin_review': 'Awaiting review',
  'government_aided': 'Government aided',
  'tvet': 'TVET',
  'unknown': 'Not set',
};

String _pretty(String raw) {
  if (_prettyLabels.containsKey(raw)) return _prettyLabels[raw]!;
  final s = raw.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  return s.isEmpty ? 'Not set' : s[0].toUpperCase() + s.substring(1);
}

class _Tab {
  final String key;
  final String label;
  final IconData icon;
  const _Tab(this.key, this.label, this.icon);
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  int _days = 30;
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;
  String _tab = 'overview';
  DateTime? _loadedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await (widget.loader?.call(_days) ?? _adminService.getAnalyticsOverview(days: _days));
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _loadedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _setPeriod(int days) {
    if (days == _days) return;
    setState(() => _days = days);
    _load();
  }

  String get _periodText => _periods.firstWhere((p) => p.$1 == _days, orElse: () => _periods[1]).$3;

  Map<String, dynamic> get _people => _m(_data?['people']);
  Map<String, dynamic> get _eng => _m(_data?['engagement']);
  Map<String, dynamic> get _learn => _m(_data?['learning']);
  Map<String, dynamic> get _exams => _m(_data?['exams']);
  Map<String, dynamic> get _rev => _m(_data?['revenue']);
  Map<String, dynamic> get _schools => _m(_data?['schools']);
  Map<String, dynamic> get _live => _m(_data?['live']);
  Map<String, dynamic> get _labs => _m(_data?['labs']);
  Map<String, dynamic> get _feedback => _m(_data?['feedback']);
  String get _cur => (_rev['currency'] as String?) ?? 'RWF';

  List<_Tab> get _tabs => [
        const _Tab('overview', 'Overview', Icons.dashboard_rounded),
        if (_data?['revenue'] != null) const _Tab('revenue', 'Revenue', Icons.payments_rounded),
        if (_data?['learning'] != null) const _Tab('learning', 'Learning', Icons.school_rounded),
        if (_data?['people'] != null) const _Tab('people', 'People', Icons.groups_rounded),
        if (_data?['schools'] != null) const _Tab('schools', 'Schools', Icons.apartment_rounded),
      ];

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final pal = DashPalette.of(context);
    return Scaffold(
      backgroundColor: pal.page,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: LayoutBuilder(builder: (context, c) {
            final pad = c.maxWidth < 600 ? 14.0 : 28.0;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pad, pad * 0.8, pad, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(pal, c.maxWidth < 700),
                      const SizedBox(height: 18),
                      if (_data != null) ...[
                        _tabBar(pal),
                        const SizedBox(height: 18),
                        if (_data!['partial'] == true) _partialBanner(pal),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Column(
                            key: ValueKey('$_tab-$_days'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _tabBody(pal),
                          ),
                        ),
                      ] else if (_error != null)
                        _errorState(pal)
                      else
                        _skeleton(pal),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _tabBody(DashPalette pal) {
    final key = _tabs.any((t) => t.key == _tab) ? _tab : 'overview';
    final sections = switch (key) {
      'revenue' => _revenueTab(pal),
      'learning' => _learningTab(pal),
      'people' => _peopleTab(pal),
      'schools' => _schoolsTab(pal),
      _ => _overviewTab(pal),
    };
    return [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: 18),
        sections[i],
      ],
    ];
  }

  // ------------------------------------------------------------------- hero
  Widget _hero(DashPalette pal, bool compact) {
    final canPop = context.canPop() || GoRouterState.of(context).uri.path != '/admin';
    final headline = <String>[
      if (_data?['revenue'] != null) '${money(_d(_m(_rev['total'])['value']), currency: _cur)} revenue',
      if (_data?['engagement'] != null) '${compactNumber(_d(_m(_eng['mau'])['value']))} active learners',
      if (_data?['learning'] != null) '${compactNumber(_d(_m(_learn['newEnrollments'])['value']))} new enrollments',
    ];

    final periodPicker = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final p in _periods)
          GestureDetector(
            onTap: () => _setPeriod(p.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _days == p.$1 ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(p.$2,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _days == p.$1 ? const Color(0xFF047857) : Colors.white,
                  )),
            ),
          ),
      ]),
    );

    final actions = Row(mainAxisSize: MainAxisSize.min, children: [
      _heroButton(Icons.refresh_rounded, 'Refresh', _loading ? null : _load),
      const SizedBox(width: 8),
      _heroButton(Icons.download_rounded, 'Copy report (CSV)', _data == null ? null : _exportCsv),
    ]);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF047857).withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          Positioned(right: -60, top: -80, child: _glow(220)),
          Positioned(right: 120, bottom: -110, child: _glow(180)),
          Padding(
            padding: EdgeInsets.all(compact ? 18 : 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (canPop) ...[
                  _heroButton(Icons.arrow_back_rounded, 'Back', () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/admin');
                    }
                  }),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Color(0xFF6EE7B7), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _loadedAt == null ? 'Loading…' : 'Updated ${DateFormat('HH:mm').format(_loadedAt!)}',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
                const Spacer(),
                if (!compact) actions,
              ]),
              SizedBox(height: compact ? 16 : 22),
              Text('Platform Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 24 : 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  )),
              const SizedBox(height: 6),
              Text(
                headline.isEmpty
                    ? 'Revenue, learning, people and schools in one place'
                    : '${headline.join('  ·  ')} in the $_periodText',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: compact ? 13 : 15, height: 1.4),
              ),
              SizedBox(height: compact ? 16 : 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  periodPicker,
                  if (compact) actions,
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _glow(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [Colors.white.withOpacity(0.16), Colors.white.withOpacity(0)]),
        ),
      );

  Widget _heroButton(IconData icon, String tooltip, VoidCallback? onTap) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, color: Colors.white.withOpacity(onTap == null ? 0.4 : 1), size: 20),
            ),
          ),
        ),
      );

  Widget _tabBar(DashPalette pal) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: pal.border),
        ),
        child: Row(children: [
          for (final t in _tabs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: _tab == t.key ? DashPalette.emerald.withOpacity(pal.dark ? 0.22 : 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  key: ValueKey('analytics-tab-${t.key}'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _tab = t.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Icon(t.icon, size: 18, color: _tab == t.key ? DashPalette.emerald : pal.muted),
                      const SizedBox(width: 8),
                      Text(t.label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: _tab == t.key ? FontWeight.w800 : FontWeight.w600,
                            color: _tab == t.key ? pal.text : pal.muted,
                          )),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------- overview
  List<Widget> _overviewTab(DashPalette pal) {
    final hasRev = _data?['revenue'] != null;
    final hasLearn = _data?['learning'] != null;
    final hasPeople = _data?['people'] != null;
    final hasSchools = _data?['schools'] != null;

    final kpis = <Widget>[
      if (hasRev)
        _kpi(pal, 'Revenue', Icons.payments_rounded, DashPalette.emerald, _m(_rev['total']),
            fmt: (v) => money(v, currency: _cur), spark: _vals(_rev['series']), onTap: () => setState(() => _tab = 'revenue')),
      if (hasPeople)
        _kpi(pal, 'New students', Icons.person_add_alt_1_rounded, DashPalette.blue, _m(_people['newStudents']),
            spark: _vals(_people['studentSignupSeries']), onTap: () => setState(() => _tab = 'people')),
      if (hasPeople)
        _kpi(pal, 'Active learners', Icons.bolt_rounded, DashPalette.amber, _m(_eng['mau']),
            caption: '${_d(_eng['activeRate']).toStringAsFixed(0)}% of students · 30d',
            spark: _vals(_eng['lastActiveSeries'])),
      if (hasLearn)
        _kpi(pal, 'New enrollments', Icons.how_to_reg_rounded, DashPalette.violet, _m(_learn['newEnrollments']),
            spark: _vals(_learn['enrollmentSeries']), onTap: () => setState(() => _tab = 'learning')),
      if (hasLearn)
        _kpi(pal, 'Course completions', Icons.task_alt_rounded, DashPalette.cyan, _m(_learn['completions']),
            spark: _vals(_learn['completionSeries'])),
      if (hasLearn)
        _kpi(pal, 'Exam submissions', Icons.quiz_rounded, DashPalette.rose, _m(_exams['submissions']),
            spark: _vals(_exams['series'])),
      if (hasLearn)
        _kpi(pal, 'Certificates issued', Icons.workspace_premium_rounded, DashPalette.lime, _m(_learn['certificates']),
            caption: '${compactNumber(_d(_m(_learn['certificates'])['total']))} all time'),
      if (hasSchools)
        _kpi(pal, 'New schools', Icons.apartment_rounded, DashPalette.slate, _m(_schools['newSchools']),
            caption: '${compactNumber(_d(_schools['total']))} schools in total', onTap: () => setState(() => _tab = 'schools')),
    ];

    return [
      _kpiGrid(kpis),
      if (hasLearn || hasPeople)
        _split([
          _panel(
            pal,
            'Growth',
            'New students and enrollments, ${_bucketWord()}',
            icon: Icons.trending_up_rounded,
            child: TrendChart(
              labels: _keys(hasLearn ? _learn['enrollmentSeries'] : _people['studentSignupSeries']),
              series: [
                if (hasLearn) ChartSeries(name: 'Enrollments', color: DashPalette.violet, values: _vals(_learn['enrollmentSeries'])),
                if (hasPeople) ChartSeries(name: 'New students', color: DashPalette.blue, values: _vals(_people['studentSignupSeries'])),
                if (hasLearn)
                  ChartSeries(
                      name: 'Completions', color: DashPalette.emerald, values: _vals(_learn['completionSeries']), filled: false),
              ],
              height: 270,
            ),
            legend: [
              if (hasLearn) ('Enrollments', DashPalette.violet),
              if (hasPeople) ('New students', DashPalette.blue),
              if (hasLearn) ('Completions', DashPalette.emerald),
            ],
          ),
          _healthPanel(pal),
        ], flex: const [3, 2]),
      _split([
        if (hasRev)
          _panel(
            pal,
            'Revenue trend',
            'Paid and approved payments, ${_bucketWord()}',
            icon: Icons.show_chart_rounded,
            child: TrendChart(
              labels: _keys(_rev['series']),
              series: [ChartSeries(name: 'Revenue', color: DashPalette.emerald, values: _vals(_rev['series']))],
              format: (v) => money(v, currency: _cur),
              height: 240,
            ),
          ),
        _attentionPanel(pal),
      ], flex: hasRev ? const [3, 2] : const [1]),
      _split([
        if (hasLearn)
          _panel(
            pal,
            'Most enrolled courses',
            'New enrollments in the $_periodText',
            icon: Icons.local_fire_department_rounded,
            action: ('All courses', () => context.push('/admin/courses')),
            child: RankedBars(
              color: DashPalette.violet,
              items: [
                for (final c in _l(_learn['topCourses']).take(6))
                  RankedItem(
                    '${_m(c)['title']}',
                    _d(_m(c)['enrollments']),
                    sub: '${_i(_m(c)['completed'])} completed · ${_d(_m(c)['avgProgress']).toStringAsFixed(0)}% avg progress',
                    onTap: () => context.push('/admin/courses/${_m(c)['id']}/analytics'),
                  ),
              ],
            ),
          ),
        if (hasPeople)
          _panel(
            pal,
            'Users by role',
            '${compactNumber(_d(_people['totalUsers']))} accounts in total',
            icon: Icons.donut_large_rounded,
            child: DonutChart(
              centerLabel: 'Users',
              slices: [
                for (var i = 0; i < _l(_people['byRole']).length; i++)
                  DonutSlice(_pretty('${_m(_l(_people['byRole'])[i])['label']}'),
                      _d(_m(_l(_people['byRole'])[i])['value']), DashPalette.at(i)),
              ],
            ),
          ),
      ], flex: const [3, 2]),
    ];
  }

  Widget _healthPanel(DashPalette pal) {
    final gauges = <Widget>[
      if (_data?['learning'] != null)
        RingGauge(
            percent: _d(_learn['completionRate']),
            color: DashPalette.emerald,
            label: 'Completion rate',
            caption: '${compactNumber(_d(_learn['completedTotal']))} of ${compactNumber(_d(_learn['enrollments']))}'),
      if (_data?['learning'] != null)
        RingGauge(
            percent: _d(_exams['passRate']),
            color: DashPalette.violet,
            label: 'Exam pass rate',
            caption: '${compactNumber(_d(_exams['passed']))} of ${compactNumber(_d(_exams['total']))}'),
      if (_data?['revenue'] != null)
        RingGauge(
            percent: _d(_rev['successRate']),
            color: DashPalette.blue,
            label: 'Payment success',
            caption: '${compactNumber(_d(_rev['failed']))} failed'),
      if (_data?['engagement'] != null)
        RingGauge(
            percent: _d(_eng['stickiness']),
            color: DashPalette.amber,
            label: 'Stickiness',
            caption: 'Daily ÷ monthly active'),
    ];
    return _panel(
      pal,
      'Platform health',
      'Rates across all time unless noted',
      icon: Icons.monitor_heart_rounded,
      child: gauges.isEmpty
          ? const EmptyChart()
          : LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth > 360 ? 2 : 1;
              final w = (c.maxWidth - 16 * (cols - 1)) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 22,
                children: [for (final g in gauges) SizedBox(width: w, child: Center(child: g))],
              );
            }),
    );
  }

  Widget _attentionPanel(DashPalette pal) {
    final pending = _m(_rev['pending']);
    final review = _m(_rev['awaitingReview']);
    final items = <(IconData, Color, String, String, String?)>[
      if (_data?['revenue'] != null)
        (Icons.fact_check_rounded, DashPalette.amber, 'Payments awaiting review',
            '${_i(review['count'])} · ${money(_d(review['total']), currency: _cur)}', '/admin/payments'),
      if (_data?['revenue'] != null)
        (Icons.hourglass_top_rounded, DashPalette.blue, 'Payments pending',
            '${_i(pending['count'])} · ${money(_d(pending['total']), currency: _cur)}', '/admin/payments'),
      if (_data?['revenue'] != null)
        (Icons.error_outline_rounded, DashPalette.rose, 'Failed or cancelled payments',
            '${_i(_rev['failed'])} in the $_periodText', '/admin/payments'),
      if (_data?['feedback'] != null)
        (Icons.mark_email_unread_rounded, DashPalette.violet, 'Unread feedback',
            '${_i(_feedback['unread'])} unread · ${_i(_feedback['inRange'])} new', '/admin/user-feedback'),
      if (_data?['live'] != null)
        (Icons.videocam_rounded, DashPalette.emerald, 'Live classes',
            '${_i(_live['liveNow'])} live now · ${_i(_live['upcoming'])} upcoming', '/admin/live-sessions'),
      if (_data?['people'] != null)
        (Icons.person_off_rounded, DashPalette.slate, 'Deactivated accounts', '${_i(_people['inactiveAccounts'])}',
            '/admin/students'),
      if (_data?['learning'] != null && _i(_learn['draftCourses']) > 0)
        (Icons.edit_note_rounded, DashPalette.cyan, 'Unpublished courses', '${_i(_learn['draftCourses'])} drafts',
            '/admin/courses'),
    ];
    return _panel(
      pal,
      'Needs attention',
      'Queues and items to follow up',
      icon: Icons.notifications_active_rounded,
      child: Column(children: [
        for (final it in items)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: it.$5 == null ? null : () => context.push(it.$5!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: it.$2.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
                  child: Icon(it.$1, color: it.$2, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(it.$3, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pal.text)),
                    Text(it.$4, style: TextStyle(fontSize: 12, color: pal.muted)),
                  ]),
                ),
                if (it.$5 != null) Icon(Icons.chevron_right_rounded, color: pal.faint),
              ]),
            ),
          ),
      ]),
    );
  }

  // ----------------------------------------------------------------- revenue
  List<Widget> _revenueTab(DashPalette pal) {
    String fmtMoney(double v) => money(v, currency: _cur);
    final pending = _m(_rev['pending']);
    final review = _m(_rev['awaitingReview']);
    return [
      _kpiGrid([
        _kpi(pal, 'Revenue', Icons.payments_rounded, DashPalette.emerald, _m(_rev['total']),
            fmt: fmtMoney, spark: _vals(_rev['series'])),
        _kpi(pal, 'Paid transactions', Icons.receipt_long_rounded, DashPalette.blue, _m(_rev['transactions']),
            spark: _vals(_rev['countSeries'])),
        _kpi(pal, 'Average order', Icons.shopping_bag_rounded, DashPalette.violet, {'value': _rev['averageOrder']},
            fmt: fmtMoney, caption: 'Per paid transaction'),
        _kpi(pal, 'Revenue per payer', Icons.person_pin_rounded, DashPalette.amber, {'value': _rev['arpu']},
            fmt: fmtMoney, caption: '${_i(_rev['payingUsers'])} paying users'),
        _kpi(pal, 'All-time revenue', Icons.account_balance_wallet_rounded, DashPalette.cyan, {'value': _rev['allTime']},
            fmt: fmtMoney, caption: '${compactNumber(_d(_rev['paidPayments']))} paid payments'),
        _kpi(pal, 'Payment success', Icons.verified_rounded, DashPalette.lime, {'value': _rev['successRate']},
            fmt: (v) => '${v.toStringAsFixed(1)}%', caption: '${_i(_rev['failed'])} failed or cancelled'),
      ]),
      _panel(
        pal,
        'Revenue over time',
        'Paid and approved payments, ${_bucketWord()}',
        icon: Icons.show_chart_rounded,
        action: ('Open payments', () => context.push('/admin/payments')),
        child: TrendChart(
          labels: _keys(_rev['series']),
          series: [ChartSeries(name: 'Revenue', color: DashPalette.emerald, values: _vals(_rev['series']))],
          format: fmtMoney,
          height: 290,
        ),
      ),
      _split([
        _panel(
          pal,
          'Transactions',
          'Number of paid payments, ${_bucketWord()}',
          icon: Icons.bar_chart_rounded,
          child: TrendChart(
            labels: _keys(_rev['countSeries']),
            series: [ChartSeries(name: 'Transactions', color: DashPalette.blue, values: _vals(_rev['countSeries']))],
            bars: true,
            height: 230,
          ),
        ),
        _panel(
          pal,
          'Payment pipeline',
          'Open queues right now and outcomes in the $_periodText',
          icon: Icons.account_tree_rounded,
          child: Column(children: [
            _pipelineRow(pal, 'Awaiting admin review', _i(review['count']), money(_d(review['total']), currency: _cur),
                DashPalette.amber),
            _pipelineRow(pal, 'Pending at gateway', _i(pending['count']), money(_d(pending['total']), currency: _cur),
                DashPalette.blue),
            _pipelineRow(pal, 'Paid', _i(_m(_rev['transactions'])['value']),
                money(_d(_m(_rev['total'])['value']), currency: _cur), DashPalette.emerald),
            _pipelineRow(pal, 'Failed or cancelled', _i(_rev['failed']), '', DashPalette.rose),
          ]),
        ),
      ], flex: const [3, 2]),
      _split([
        _panel(
          pal,
          'By payment method',
          'Revenue share in the $_periodText',
          icon: Icons.credit_card_rounded,
          child: DonutChart(
            centerLabel: 'Revenue',
            format: (v) => NumberFormat.compact().format(v),
            slices: [
              for (var i = 0; i < _l(_rev['byMethod']).length; i++)
                DonutSlice(_pretty('${_m(_l(_rev['byMethod'])[i])['label']}'), _d(_m(_l(_rev['byMethod'])[i])['value']),
                    _methodColor('${_m(_l(_rev['byMethod'])[i])['label']}', i)),
            ],
          ),
        ),
        _panel(
          pal,
          'By product',
          'What people paid for in the $_periodText',
          icon: Icons.category_rounded,
          child: DonutChart(
            centerLabel: 'Revenue',
            format: (v) => NumberFormat.compact().format(v),
            slices: [
              for (var i = 0; i < _l(_rev['byPurpose']).length; i++)
                DonutSlice(_pretty('${_m(_l(_rev['byPurpose'])[i])['label']}'),
                    _d(_m(_l(_rev['byPurpose'])[i])['value']), DashPalette.at(i + 1)),
            ],
          ),
        ),
      ]),
      _split([
        _panel(
          pal,
          'Top earning courses',
          'Revenue in the $_periodText',
          icon: Icons.emoji_events_rounded,
          child: RankedBars(
            color: DashPalette.emerald,
            format: fmtMoney,
            items: [
              for (final c in _l(_rev['topCourses']))
                RankedItem('${_m(c)['title']}', _d(_m(c)['revenue']),
                    sub: '${_i(_m(c)['sales'])} sales',
                    onTap: () => context.push('/admin/courses/${_m(c)['id']}/analytics')),
            ],
          ),
        ),
        _panel(
          pal,
          'Latest payments',
          'Most recent paid transactions',
          icon: Icons.receipt_rounded,
          child: _recentPayments(pal),
        ),
      ]),
    ];
  }

  Color _methodColor(String m, int i) => switch (m) {
        'mtn_momo' => const Color(0xFFEAB308),
        'airtel_money' => DashPalette.rose,
        'card' => DashPalette.blue,
        'free' => DashPalette.slate,
        _ => DashPalette.at(i),
      };

  Widget _pipelineRow(DashPalette pal, String label, int count, String amount, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Container(width: 4, height: 34, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pal.text)),
              if (amount.isNotEmpty) Text(amount, style: TextStyle(fontSize: 11.5, color: pal.muted)),
            ]),
          ),
          Text(compactNumber(count), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: pal.text)),
        ]),
      );

  Widget _recentPayments(DashPalette pal) {
    final list = _l(_rev['recent']);
    if (list.isEmpty) return const EmptyChart(height: 120, message: 'No payments yet');
    return Column(children: [
      for (final raw in list)
        Builder(builder: (context) {
          final p = _m(raw);
          final date = DateTime.tryParse('${p['date']}')?.toLocal();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: _methodColor('${p['method']}', 0).withOpacity(0.15),
                child: Icon(
                  p['method'] == 'card' ? Icons.credit_card_rounded : Icons.phone_iphone_rounded,
                  size: 16,
                  color: _methodColor('${p['method']}', 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${p['user']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pal.text)),
                  Text('${p['item']} · ${_pretty('${p['method']}')}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: pal.muted)),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(money(_d(p['amount']), currency: '${p['currency'] ?? _cur}', compact: false),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DashPalette.emerald)),
                if (date != null)
                  Text(DateFormat('MMM d, HH:mm').format(date), style: TextStyle(fontSize: 11, color: pal.faint)),
              ]),
            ]),
          );
        }),
    ]);
  }

  // ---------------------------------------------------------------- learning
  List<Widget> _learningTab(DashPalette pal) {
    final status = {for (final s in _l(_learn['completionStatus'])) '${_m(s)['label']}': _d(_m(s)['value'])};
    final total = _d(_learn['enrollments']);
    final started = (status['in-progress'] ?? 0) + (status['completed'] ?? 0);
    return [
      _kpiGrid([
        _kpi(pal, 'Courses', Icons.menu_book_rounded, DashPalette.emerald, {'value': _learn['courses']},
            caption: '${_i(_learn['publishedCourses'])} published · ${_i(_learn['draftCourses'])} drafts'),
        _kpi(pal, 'New enrollments', Icons.how_to_reg_rounded, DashPalette.violet, _m(_learn['newEnrollments']),
            spark: _vals(_learn['enrollmentSeries'])),
        _kpi(pal, 'Completions', Icons.task_alt_rounded, DashPalette.cyan, _m(_learn['completions']),
            spark: _vals(_learn['completionSeries'])),
        _kpi(pal, 'Learners', Icons.people_alt_rounded, DashPalette.blue, {'value': _learn['learners']},
            caption: '${_d(_learn['enrollmentsPerLearner']).toStringAsFixed(1)} courses each on average'),
        _kpi(pal, 'Average progress', Icons.speed_rounded, DashPalette.amber, {'value': _learn['avgProgress']},
            fmt: (v) => '${v.toStringAsFixed(1)}%', caption: 'Across ${compactNumber(total)} enrollments'),
        _kpi(pal, 'Course rating', Icons.star_rounded, const Color(0xFFEAB308), {'value': _m(_learn['rating'])['average']},
            fmt: (v) => v == 0 ? '—' : '${v.toStringAsFixed(1)} / 5', caption: '${_i(_m(_learn['rating'])['count'])} ratings'),
      ]),
      _split([
        _panel(
          pal,
          'Enrollments vs completions',
          _bucketWord(capital: true),
          icon: Icons.stacked_line_chart_rounded,
          legend: const [('Enrollments', DashPalette.violet), ('Completions', DashPalette.emerald)],
          child: TrendChart(
            labels: _keys(_learn['enrollmentSeries']),
            series: [
              ChartSeries(name: 'Enrollments', color: DashPalette.violet, values: _vals(_learn['enrollmentSeries'])),
              ChartSeries(name: 'Completions', color: DashPalette.emerald, values: _vals(_learn['completionSeries'])),
            ],
            height: 270,
          ),
        ),
        _panel(
          pal,
          'Learning funnel',
          'All enrollments, all time',
          icon: Icons.filter_alt_rounded,
          child: FunnelChart(
            colors: const [DashPalette.violet, DashPalette.blue, DashPalette.emerald],
            stages: [
              RankedItem('Enrolled', total),
              RankedItem('Started', started),
              RankedItem('Completed', status['completed'] ?? 0),
            ],
          ),
        ),
      ], flex: const [3, 2]),
      _split([
        _panel(
          pal,
          'Top courses',
          'By new enrollments in the $_periodText',
          icon: Icons.local_fire_department_rounded,
          action: ('All courses', () => context.push('/admin/courses')),
          child: RankedBars(
            color: DashPalette.violet,
            items: [
              for (final c in _l(_learn['topCourses']))
                RankedItem(
                  '${_m(c)['title']}',
                  _d(_m(c)['enrollments']),
                  sub: '${_i(_m(c)['completed'])} completed · ${_d(_m(c)['avgProgress']).toStringAsFixed(0)}% avg progress'
                      '${_d(_m(c)['price']) > 0 ? ' · ${money(_d(_m(c)['price']), currency: _cur, compact: false)}' : ' · Free'}',
                  onTap: () => context.push('/admin/courses/${_m(c)['id']}/analytics'),
                ),
            ],
          ),
        ),
        _panel(
          pal,
          'Catalogue mix',
          'Courses by level',
          icon: Icons.layers_rounded,
          child: DonutChart(
            centerLabel: 'Courses',
            slices: [
              for (var i = 0; i < _l(_learn['levelMix']).length; i++)
                DonutSlice(_pretty('${_m(_l(_learn['levelMix'])[i])['label']}'),
                    _d(_m(_l(_learn['levelMix'])[i])['value']), DashPalette.at(i)),
            ],
          ),
        ),
      ], flex: const [3, 2]),
      _split([
        _panel(
          pal,
          'Courses by category',
          'Where the catalogue is concentrated',
          icon: Icons.category_rounded,
          child: RankedBars(
            color: DashPalette.blue,
            items: [for (final c in _l(_learn['categoryMix'])) RankedItem('${_m(c)['label']}', _d(_m(c)['value']))],
          ),
        ),
        _panel(
          pal,
          'Exams & quizzes',
          '${compactNumber(_d(_m(_exams['submissions'])['value']))} submissions in the $_periodText',
          icon: Icons.quiz_rounded,
          child: Column(children: [
            Wrap(alignment: WrapAlignment.spaceEvenly, spacing: 12, runSpacing: 16, children: [
              RingGauge(
                  percent: _d(_exams['passRate']),
                  color: DashPalette.violet,
                  label: 'Pass rate',
                  caption: 'All time',
                  size: 84),
              RingGauge(
                  percent: _d(_exams['passRateInRange']),
                  color: DashPalette.emerald,
                  label: 'Pass rate',
                  caption: 'This period',
                  size: 84),
              RingGauge(
                  percent: _d(_exams['avgScore']),
                  color: DashPalette.amber,
                  label: 'Average score',
                  caption: 'All time',
                  size: 84),
            ]),
            const SizedBox(height: 18),
            TrendChart(
              labels: _keys(_exams['series']),
              series: [
                ChartSeries(name: 'Submitted', color: DashPalette.violet, values: _vals(_exams['series'])),
                ChartSeries(name: 'Passed', color: DashPalette.emerald, values: _vals(_exams['passedSeries'])),
              ],
              bars: true,
              height: 170,
            ),
          ]),
        ),
      ]),
      _split([
        _panel(
          pal,
          'Live classes & virtual labs',
          'Sessions scheduled and lab attempts in the $_periodText',
          icon: Icons.science_rounded,
          action: ('Live sessions', () => context.push('/admin/live-sessions')),
          child: _miniStats(pal, [
            ('Live now', compactNumber(_d(_live['liveNow'])), DashPalette.rose),
            ('Upcoming', compactNumber(_d(_live['upcoming'])), DashPalette.blue),
            ('Scheduled this period', compactNumber(_d(_live['inRange'])), DashPalette.violet),
            ('Lab attempts', compactNumber(_d(_labs['attempts'])), DashPalette.cyan),
            ('Lab learners', compactNumber(_d(_labs['learners'])), DashPalette.amber),
            ('Labs completed', '${_d(_labs['completionRate']).toStringAsFixed(0)}%', DashPalette.emerald),
            ('Labs passed', compactNumber(_d(_labs['passed'])), DashPalette.lime),
            ('Avg lab score', _d(_labs['avgScore']).toStringAsFixed(0), DashPalette.slate),
          ]),
        ),
        _panel(
          pal,
          'Top learners',
          'Most completed courses, all time',
          icon: Icons.emoji_events_rounded,
          action: ('All students', () => context.push('/admin/students')),
          child: _topStudents(pal),
        ),
      ]),
    ];
  }

  Widget _topStudents(DashPalette pal) {
    final list = _l(_learn['topStudents']);
    if (list.isEmpty) return const EmptyChart(height: 120);
    return Column(children: [
      for (var i = 0; i < list.length; i++)
        Builder(builder: (context) {
          final s = _m(list[i]);
          final name = '${s['name']}';
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.push('/admin/students/${s['id']}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
              child: Row(children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: i < 3 ? const Color(0xFFEAB308).withOpacity(0.18) : pal.cardAlt,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: i < 3 ? const Color(0xFFB45309) : pal.muted, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pal.text)),
                    Text('${_i(s['completed'])} of ${_i(s['enrollments'])} courses completed',
                        style: TextStyle(fontSize: 11.5, color: pal.muted)),
                  ]),
                ),
                SizedBox(
                  width: 70,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${_d(s['avgProgress']).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DashPalette.emerald)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (_d(s['avgProgress']) / 100).clamp(0, 1),
                        minHeight: 4,
                        backgroundColor: pal.grid,
                        valueColor: const AlwaysStoppedAnimation(DashPalette.emerald),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          );
        }),
    ]);
  }

  // ------------------------------------------------------------------ people
  List<Widget> _peopleTab(DashPalette pal) {
    final students = _d(_people['students']);
    final total = _d(_people['totalUsers']);
    return [
      _kpiGrid([
        _kpi(pal, 'Total users', Icons.groups_rounded, DashPalette.emerald, {'value': total},
            caption: '${total == 0 ? 0 : (_d(_people['verified']) / total * 100).toStringAsFixed(0)}% verified'),
        _kpi(pal, 'New users', Icons.person_add_rounded, DashPalette.blue, _m(_people['newUsers']),
            spark: _vals(_people['signupSeries'])),
        _kpi(pal, 'Students', Icons.backpack_rounded, DashPalette.violet, {'value': students},
            caption: '${_i(_people['schoolStudents'])} in schools · ${_i(_people['privateStudents'])} private'),
        _kpi(pal, 'Teachers', Icons.co_present_rounded, DashPalette.amber, {'value': _people['teachers']},
            caption: students == 0 || _d(_people['teachers']) == 0
                ? 'No teachers yet'
                : '1 per ${(students / _d(_people['teachers'])).toStringAsFixed(0)} students',
            onTap: () => context.push('/admin/teachers')),
        _kpi(pal, 'Parents', Icons.family_restroom_rounded, DashPalette.cyan, {'value': _people['parents']},
            caption: '${_i(_people['schoolAdmins'])} school admins'),
        _kpi(pal, 'Monthly active', Icons.bolt_rounded, DashPalette.rose, _m(_eng['mau']),
            caption: 'Students active in last 30 days'),
      ]),
      _split([
        _panel(
          pal,
          'Sign-ups',
          'New accounts, ${_bucketWord()}',
          icon: Icons.trending_up_rounded,
          legend: const [('All users', DashPalette.emerald), ('Students', DashPalette.blue)],
          child: TrendChart(
            labels: _keys(_people['signupSeries']),
            series: [
              ChartSeries(name: 'All users', color: DashPalette.emerald, values: _vals(_people['signupSeries'])),
              ChartSeries(name: 'Students', color: DashPalette.blue, values: _vals(_people['studentSignupSeries'])),
            ],
            height: 270,
          ),
        ),
        _panel(
          pal,
          'Users by role',
          '${compactNumber(total)} accounts',
          icon: Icons.donut_large_rounded,
          child: DonutChart(
            centerLabel: 'Users',
            slices: [
              for (var i = 0; i < _l(_people['byRole']).length; i++)
                DonutSlice(_pretty('${_m(_l(_people['byRole'])[i])['label']}'),
                    _d(_m(_l(_people['byRole'])[i])['value']), DashPalette.at(i)),
            ],
          ),
        ),
      ], flex: const [3, 2]),
      _split([
        _panel(
          pal,
          'Engagement',
          'Students active in the app',
          icon: Icons.insights_rounded,
          child: Column(children: [
            _miniStats(pal, [
              ('Daily active', compactNumber(_d(_eng['dau'])), DashPalette.emerald),
              ('Weekly active', compactNumber(_d(_eng['wau'])), DashPalette.blue),
              ('Monthly active', compactNumber(_d(_m(_eng['mau'])['value'])), DashPalette.violet),
              ('Study hours', compactNumber(_d(_eng['totalStudyHours'])), DashPalette.amber),
              ('Avg session', '${_i(_eng['avgSessionMinutes'])} min', DashPalette.cyan),
              ('Sessions', compactNumber(_d(_eng['totalSessions'])), DashPalette.rose),
            ]),
            const SizedBox(height: 18),
            _activeBars(pal, students),
          ]),
        ),
        _panel(
          pal,
          'Last seen',
          'Students by the day they were last active',
          icon: Icons.history_rounded,
          child: TrendChart(
            labels: _keys(_eng['lastActiveSeries']),
            series: [ChartSeries(name: 'Students', color: DashPalette.amber, values: _vals(_eng['lastActiveSeries']))],
            bars: true,
            height: 270,
          ),
        ),
      ]),
      _split([
        _panel(
          pal,
          'Private vs school students',
          'How students joined',
          icon: Icons.account_tree_rounded,
          child: DonutChart(
            centerLabel: 'Students',
            slices: [
              DonutSlice('Private learners', _d(_people['privateStudents']), DashPalette.blue),
              DonutSlice('School students', _d(_people['schoolStudents']), DashPalette.emerald),
            ],
          ),
        ),
        _panel(
          pal,
          'Gender',
          'Students with gender on record',
          icon: Icons.wc_rounded,
          child: DonutChart(
            centerLabel: 'Students',
            slices: [
              for (var i = 0; i < _l(_people['gender']).length; i++)
                DonutSlice(_pretty('${_m(_l(_people['gender'])[i])['label']}'), _d(_m(_l(_people['gender'])[i])['value']),
                    switch ('${_m(_l(_people['gender'])[i])['label']}') {
                      'female' => DashPalette.rose,
                      'male' => DashPalette.blue,
                      'other' => DashPalette.violet,
                      _ => DashPalette.slate,
                    }),
            ],
          ),
        ),
        _panel(
          pal,
          'Students by province',
          'From student addresses',
          icon: Icons.map_rounded,
          child: RankedBars(
            color: DashPalette.emerald,
            items: [for (final p in _l(_people['provinces'])) RankedItem('${_m(p)['label']}', _d(_m(p)['value']))],
          ),
        ),
      ]),
    ];
  }

  Widget _activeBars(DashPalette pal, double students) {
    final rows = [
      ('Today', _d(_eng['dau']), DashPalette.emerald),
      ('Last 7 days', _d(_eng['wau']), DashPalette.blue),
      ('Last 30 days', _d(_m(_eng['mau'])['value']), DashPalette.violet),
    ];
    return Column(children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 92, child: Text(r.$1, style: TextStyle(fontSize: 12, color: pal.muted))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: students == 0 ? 0 : (r.$2 / students).clamp(0, 1),
                  minHeight: 10,
                  backgroundColor: pal.grid,
                  valueColor: AlwaysStoppedAnimation(r.$3),
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(students == 0 ? '0%' : '${(r.$2 / students * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pal.text)),
            ),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: Text('Share of all students', style: TextStyle(fontSize: 11, color: pal.faint)),
      ),
    ]);
  }

  // ----------------------------------------------------------------- schools
  List<Widget> _schoolsTab(DashPalette pal) {
    return [
      _kpiGrid([
        _kpi(pal, 'Schools', Icons.apartment_rounded, DashPalette.emerald, {'value': _schools['total']},
            caption: '${_i(_schools['active'])} active', onTap: () => context.push('/admin/schools')),
        _kpi(pal, 'New schools', Icons.add_business_rounded, DashPalette.blue, _m(_schools['newSchools'])),
        _kpi(pal, 'School students', Icons.backpack_rounded, DashPalette.violet, {'value': _schools['students']},
            caption: '${_d(_schools['avgStudentsPerSchool']).toStringAsFixed(1)} per school'),
        _kpi(pal, 'Active classes', Icons.meeting_room_rounded, DashPalette.amber, {'value': _schools['classrooms']},
            caption: _d(_schools['classrooms']) == 0
                ? 'No classes yet'
                : '${(_d(_schools['students']) / _d(_schools['classrooms'])).toStringAsFixed(1)} students per class'),
      ]),
      _split([
        _panel(
          pal,
          'Schools by plan',
          'Subscription plan',
          icon: Icons.workspace_premium_rounded,
          child: DonutChart(
            centerLabel: 'Schools',
            slices: [
              for (var i = 0; i < _l(_schools['byPlan']).length; i++)
                DonutSlice(_pretty('${_m(_l(_schools['byPlan'])[i])['label']}'),
                    _d(_m(_l(_schools['byPlan'])[i])['value']),
                    switch ('${_m(_l(_schools['byPlan'])[i])['label']}') {
                      'premium' => DashPalette.violet,
                      'basic' => DashPalette.blue,
                      'free' => DashPalette.slate,
                      _ => DashPalette.at(i),
                    }),
            ],
          ),
        ),
        _panel(
          pal,
          'Schools by type',
          'Level of education',
          icon: Icons.school_rounded,
          child: RankedBars(
            color: DashPalette.emerald,
            items: [
              for (final t in _l(_schools['byType'])) RankedItem(_pretty('${_m(t)['label']}'), _d(_m(t)['value'])),
            ],
          ),
        ),
      ]),
      _panel(
        pal,
        'Largest schools',
        'By number of students on the platform',
        icon: Icons.leaderboard_rounded,
        action: ('All schools', () => context.push('/admin/schools')),
        child: RankedBars(
          color: DashPalette.violet,
          items: [
            for (final s in _l(_schools['top']))
              RankedItem('${_m(s)['name']}', _d(_m(s)['students']),
                  sub: [
                    _pretty('${_m(s)['plan'] ?? 'free'}'),
                    if ('${_m(s)['district'] ?? ''}'.isNotEmpty) '${_m(s)['district']}',
                  ].join(' · ')),
          ],
        ),
      ),
    ];
  }

  // ------------------------------------------------------------ components
  String _bucketWord({bool capital = false}) {
    final w = _m(_data?['range'])['bucket'] == 'month' ? 'by month' : 'by day';
    return capital ? w[0].toUpperCase() + w.substring(1) : w;
  }

  Widget _kpiGrid(List<Widget> tiles) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      var cols = w >= 1180 ? 4 : (w >= 760 ? 3 : 2);
      if (tiles.length == 6 && w >= 1180) cols = 3;
      if (tiles.length <= 4 && w >= 760) cols = tiles.length;
      const gap = 14.0;
      final tileW = (w - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final t in tiles) SizedBox(width: tileW, child: t)],
      );
    });
  }

  Widget _kpi(
    DashPalette pal,
    String label,
    IconData icon,
    Color color,
    Map<String, dynamic> metric, {
    String Function(double)? fmt,
    List<double>? spark,
    String? caption,
    VoidCallback? onTap,
  }) {
    final value = _d(metric['value']);
    final hasPrev = metric.containsKey('previous');
    final prev = _d(metric['previous']);
    final f = fmt ?? (v) => compactNumber(v);

    Widget? badge;
    if (hasPrev) {
      String text;
      Color c;
      IconData? arrow;
      if (prev == 0 && value == 0) {
        text = 'No change';
        c = pal.faint;
      } else if (prev == 0) {
        text = 'New';
        c = DashPalette.emerald;
        arrow = Icons.arrow_upward_rounded;
      } else {
        final pct = (value - prev) / prev * 100;
        text = '${pct.abs() >= 1000 ? '999+' : pct.abs().toStringAsFixed(pct.abs() < 10 ? 1 : 0)}%';
        c = pct > 0 ? DashPalette.emerald : (pct < 0 ? DashPalette.rose : pal.faint);
        arrow = pct > 0 ? Icons.arrow_upward_rounded : (pct < 0 ? Icons.arrow_downward_rounded : null);
      }
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (arrow != null) Icon(arrow, size: 12, color: c),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c)),
        ]),
      );
    }

    final sub = caption ?? (hasPrev ? 'vs ${f(prev)} previous ${_periods.firstWhere((p) => p.$1 == _days).$2}' : null);
    final hasSpark = spark != null && spark.length > 1 && spark.any((v) => v > 0);

    return Material(
      color: pal.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: pal.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: pal.muted)),
              ),
            ]),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(f(value),
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: pal.text, letterSpacing: -0.8)),
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 6), badge],
            ]),
            if (sub != null)
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: pal.faint)),
            const SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: hasSpark
                  ? Sparkline(values: spark, color: color, height: 28)
                  : Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        height: 3,
                        width: 40,
                        decoration: BoxDecoration(color: color.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Side-by-side panels on wide screens, stacked on narrow ones.
  Widget _split(List<Widget> children, {List<int> flex = const []}) {
    if (children.length == 1) return children.first;
    return LayoutBuilder(builder: (context, c) {
      final minEach = children.length >= 3 ? 330.0 : 440.0;
      if (c.maxWidth < minEach * children.length) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            children[i],
          ],
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 18),
          Expanded(flex: i < flex.length ? flex[i] : 1, child: children[i]),
        ],
      ]);
    });
  }

  Widget _panel(
    DashPalette pal,
    String title,
    String subtitle, {
    required Widget child,
    IconData? icon,
    (String, VoidCallback)? action,
    List<(String, Color)> legend = const [],
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pal.border),
        boxShadow: pal.dark
            ? null
            : [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: DashPalette.emerald),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: pal.text)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: pal.muted)),
            ]),
          ),
          if (action != null)
            TextButton(
              onPressed: action.$2,
              style: TextButton.styleFrom(
                foregroundColor: DashPalette.emerald,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(action.$1),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ]),
            ),
        ]),
        if (legend.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 6, children: [
            for (final l in legend)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 14, height: 3, decoration: BoxDecoration(color: l.$2, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Text(l.$1, style: TextStyle(fontSize: 11.5, color: pal.muted)),
              ]),
          ]),
        ],
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _miniStats(DashPalette pal, List<(String, String, Color)> stats) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 520 ? 4 : (c.maxWidth > 300 ? 3 : 2);
      const gap = 10.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final s in stats)
          Container(
            width: w,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pal.cardAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: s.$3, width: 3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(s.$2, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pal.text)),
              ),
              const SizedBox(height: 2),
              Text(s.$1,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: pal.muted)),
            ]),
          ),
      ]);
    });
  }

  Widget _partialBanner(DashPalette pal) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DashPalette.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashPalette.amber.withOpacity(0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: DashPalette.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Some sections could not be loaded. The numbers shown are correct; refresh to try the rest again.',
                style: TextStyle(fontSize: 12.5, color: pal.text)),
          ),
        ]),
      );

  Widget _errorState(DashPalette pal) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pal.border),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: DashPalette.rose),
          const SizedBox(height: 12),
          Text('Could not load analytics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: pal.text)),
          const SizedBox(height: 6),
          Text(_error ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: pal.muted)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(backgroundColor: DashPalette.emerald),
          ),
        ]),
      );

  Widget _skeleton(DashPalette pal) {
    Widget box(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: pal.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: pal.border),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _kpiGrid([for (var i = 0; i < 8; i++) box(160)]),
      const SizedBox(height: 18),
      _split([box(330), box(330)], flex: const [3, 2]),
    ]);
  }

  // ------------------------------------------------------------------ export
  Future<void> _exportCsv() async {
    final rows = <List<String>>[
      ['Section', 'Metric', 'Value', 'Previous period'],
    ];
    void add(String section, String metric, dynamic value, [dynamic previous]) {
      rows.add([section, metric, '${value ?? ''}', previous == null ? '' : '$previous']);
    }

    void addKpi(String section, String metric, dynamic kpi) {
      final k = _m(kpi);
      add(section, metric, k['value'], k['previous']);
    }

    final range = _m(_data?['range']);
    add('Report', 'Period', _periodText);
    add('Report', 'From', range['from']);
    add('Report', 'To', range['to']);
    if (_data?['revenue'] != null) {
      addKpi('Revenue', 'Revenue ($_cur)', _rev['total']);
      addKpi('Revenue', 'Paid transactions', _rev['transactions']);
      add('Revenue', 'Average order ($_cur)', _rev['averageOrder']);
      add('Revenue', 'Revenue per payer ($_cur)', _rev['arpu']);
      add('Revenue', 'Paying users', _rev['payingUsers']);
      add('Revenue', 'Payment success rate (%)', _rev['successRate']);
      add('Revenue', 'Failed or cancelled', _rev['failed']);
      add('Revenue', 'All-time revenue ($_cur)', _rev['allTime']);
      for (final m in _l(_rev['byMethod'])) {
        add('Revenue by method', _pretty('${_m(m)['label']}'), _m(m)['value']);
      }
      for (final m in _l(_rev['byPurpose'])) {
        add('Revenue by product', _pretty('${_m(m)['label']}'), _m(m)['value']);
      }
    }
    if (_data?['people'] != null) {
      add('People', 'Total users', _people['totalUsers']);
      add('People', 'Students', _people['students']);
      add('People', 'Teachers', _people['teachers']);
      add('People', 'Parents', _people['parents']);
      addKpi('People', 'New users', _people['newUsers']);
      addKpi('People', 'New students', _people['newStudents']);
      add('Engagement', 'Daily active students', _eng['dau']);
      add('Engagement', 'Weekly active students', _eng['wau']);
      addKpi('Engagement', 'Monthly active students', _eng['mau']);
      add('Engagement', 'Stickiness (%)', _eng['stickiness']);
      add('Engagement', 'Study hours (all time)', _eng['totalStudyHours']);
      add('Engagement', 'Average session (min)', _eng['avgSessionMinutes']);
    }
    if (_data?['learning'] != null) {
      add('Learning', 'Courses', _learn['courses']);
      add('Learning', 'Published courses', _learn['publishedCourses']);
      add('Learning', 'Enrollments (all time)', _learn['enrollments']);
      addKpi('Learning', 'New enrollments', _learn['newEnrollments']);
      addKpi('Learning', 'Completions', _learn['completions']);
      add('Learning', 'Completion rate (%)', _learn['completionRate']);
      add('Learning', 'Average progress (%)', _learn['avgProgress']);
      addKpi('Learning', 'Certificates issued', _learn['certificates']);
      add('Learning', 'Average rating', _m(_learn['rating'])['average']);
      addKpi('Exams', 'Submissions', _exams['submissions']);
      add('Exams', 'Pass rate all time (%)', _exams['passRate']);
      add('Exams', 'Average score (%)', _exams['avgScore']);
      for (final c in _l(_learn['topCourses'])) {
        add('Top courses (new enrollments)', '${_m(c)['title']}', _m(c)['enrollments']);
      }
    }
    if (_data?['schools'] != null) {
      add('Schools', 'Schools', _schools['total']);
      add('Schools', 'Active schools', _schools['active']);
      addKpi('Schools', 'New schools', _schools['newSchools']);
      add('Schools', 'School students', _schools['students']);
      add('Schools', 'Active classes', _schools['classrooms']);
    }

    String cell(String s) => s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    final csv = rows.map((r) => r.map(cell).join(',')).join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report copied as CSV (${rows.length - 1} rows). Paste it into Excel or Google Sheets.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF047857),
      ),
    );
  }
}
