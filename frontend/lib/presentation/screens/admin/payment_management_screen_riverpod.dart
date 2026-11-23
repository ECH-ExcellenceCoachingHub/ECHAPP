import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/payment.dart';
import '../../../models/payment_status.dart';
import '../../../services/api/admin_payments_service.dart';
import '../../../services/api/checkout_service.dart';
import '../../../services/api/payment_api_service.dart';
import 'payments/payment_presentation.dart';

/// Super-admin payments: revenue at a glance, what needs attention, and every
/// payment (courses, teacher's guides, school terms; online via iTechPay or
/// manual) with search, filters and the right action for each one.
///
/// All filtering and search run on the server, so they cover every payment,
/// not just the page on screen.
class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key, this.service, this.paymentApi, this.checkout});

  /// Injectable for tests.
  final AdminPaymentsService? service;
  final PaymentApiService? paymentApi;
  final CheckoutService? checkout;

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  static const _pageSize = 25;

  late final AdminPaymentsService _svc = widget.service ?? AdminPaymentsService();
  late final PaymentApiService _payApi = widget.paymentApi ?? PaymentApiService();
  late final CheckoutService _checkout = widget.checkout ?? CheckoutService();

  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  Timer? _autoRefresh;

  AdminPaymentsQuery _query = const AdminPaymentsQuery();
  PaymentsOverview? _overview;
  String? _overviewError;
  final List<Payment> _items = [];
  int _total = 0;
  int _page = 0;
  int _totalPages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  DateTime? _updatedAt;
  final Set<String> _busy = {};
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reload();
    // Quiet background refresh while the screen is open (no pop-ups).
    _autoRefresh = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted || _loadingMore || _busy.isNotEmpty) return;
      _loadOverview();
      if (_page <= 1 && (_scroll.hasClients ? _scroll.offset < 400 : true)) _loadList(silent: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autoRefresh?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _reload() => Future.wait([_loadOverview(), _loadList()]);

  Future<void> _loadOverview() async {
    try {
      final o = await _svc.overview();
      if (mounted) {
        setState(() {
          _overview = o;
          _overviewError = null;
        });
      }
    } catch (e) {
      // The list still works without the overview; say so instead of loading forever.
      if (mounted) setState(() => _overviewError = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _loadList({bool silent = false}) async {
    final token = ++_loadToken;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final r = await _svc.list(_query, page: 1, limit: _pageSize);
      if (!mounted || token != _loadToken) return;
      setState(() {
        _items
          ..clear()
          ..addAll(r.payments);
        _total = r.total;
        _page = 1;
        _totalPages = r.totalPages;
        _loading = false;
        _error = null;
        _updatedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loading = false;
        if (!silent) _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _page >= _totalPages) return;
    final token = _loadToken;
    setState(() => _loadingMore = true);
    try {
      final r = await _svc.list(_query, page: _page + 1, limit: _pageSize);
      if (!mounted || token != _loadToken) return;
      final seen = _items.map((p) => p.id).toSet();
      setState(() {
        _items.addAll(r.payments.where((p) => !seen.contains(p.id)));
        _page = r.page;
        _totalPages = r.totalPages;
        _total = r.total;
      });
    } catch (e) {
      if (mounted) _snack('Could not load more: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _loadMore();
  }

  void _setQuery(AdminPaymentsQuery q) {
    setState(() => _query = q);
    _loadList();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _setQuery(_query.copyWith(search: v)));
  }

  void _clearFilters() {
    _search.clear();
    _setQuery(const AdminPaymentsQuery());
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _snack(String text, {bool error = false, bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? Colors.red.shade700
            : success
                ? Colors.green.shade700
                : null,
      ));
  }

  Future<void> _run(Payment p, Future<void> Function() action) async {
    setState(() => _busy.add(p.id));
    try {
      await action();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
    if (mounted) _reload();
  }

  Future<void> _recheck(Payment p) => _run(p, () async {
        final s = await _checkout.recheck(p.id);
        if (!mounted) return;
        _snack(s.isPaid ? 'iTechPay confirmed it. Access was granted.' : 'iTechPay: ${s.message ?? s.status}', success: s.isPaid);
      });

  Future<void> _decide(Payment p, {required bool approve}) async {
    final notes = TextEditingController();
    final look = statusLook(p);
    final unconfirmedOnline = approve && p.isOnline && p.status == PaymentStatus.pending;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: Icon(approve ? Icons.verified_outlined : Icons.block, color: approve ? Colors.green : Colors.red, size: 36),
        title: Text(approve ? 'Approve this payment?' : 'Reject this payment?'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${customerName(p)} · ${rwf(p.amount)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(itemTitle(p)),
            const SizedBox(height: 12),
            if (approve) _Callout(_grantText(p), Icons.lock_open_outlined, Colors.green),
            if (unconfirmedOnline)
              const _Callout(
                  'iTechPay has not confirmed this payment. Approve only if you have proof the money arrived.', Icons.warning_amber_rounded, Colors.orange),
            if (!approve && look.hint != null) _Callout(look.hint!, look.icon, look.color),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: approve ? 'Note (optional)' : 'Reason (sent to the customer)',
                border: const OutlineInputBorder(),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: approve ? Colors.green.shade700 : Colors.red.shade700),
            onPressed: () => Navigator.pop(c, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(p, () async {
      await _payApi.verifyPayment(
        paymentId: p.id,
        status: approve ? PaymentStatus.approved : PaymentStatus.failed,
        adminNotes: notes.text.trim(),
      );
      if (mounted) _snack(approve ? 'Approved. ${_grantedText(p)}' : 'Payment rejected.', success: approve);
    });
  }

  String _grantText(Payment p) => switch (purposeOf(p)) {
        'teacher_guide' => 'The teacher gets this course\'s guide and teaching tools.',
        'school_term' => 'The term is marked paid and ${p.seats ?? 0} student places are added.',
        _ => 'The student is enrolled in the course.',
      };

  String _grantedText(Payment p) => switch (purposeOf(p)) {
        'teacher_guide' => 'Guide unlocked.',
        'school_term' => 'Term marked paid.',
        _ => 'Student enrolled.',
      };

  Future<void> _delete(Payment p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 36),
        title: const Text('Delete this payment?'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${customerName(p)} · ${rwf(p.amount)} · ${itemTitle(p)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _Callout(
              [
                'The record is removed permanently.',
                if (isPaid(p) && purposeOf(p) == 'course') 'The student loses the enrollment it paid for.',
                if (isPaid(p) && purposeOf(p) == 'teacher_guide') 'The teacher loses access to this guide.',
                if (isPaid(p) && purposeOf(p) == 'school_term') 'The school term stays marked paid: change it in the school\'s billing if needed.',
                if (p.isOnline) 'Money paid through iTechPay is NOT refunded by deleting.',
              ].join('\n'),
              Icons.warning_amber_rounded,
              Colors.red,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700), onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(p, () async {
      await _payApi.deletePayment(p.id);
      if (mounted) _snack('Payment deleted.');
    });
  }

  Future<void> _invoice(Payment p) => _run(p, () async {
        _snack('Preparing invoice…');
        await _payApi.downloadInvoice(p.id);
        if (mounted) _snack('Invoice downloaded.', success: true);
      });

  void _open(Payment p) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final content = _PaymentDetails(
      payment: p,
      actions: _actionsFor(p, closeFirst: true),
    );
    if (wide) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760), child: content),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => FractionallySizedBox(heightFactor: 0.9, child: content),
      );
    }
  }

  /// The actions that make sense for this payment, most important first.
  List<_Action> _actionsFor(Payment p, {bool closeFirst = false}) {
    void Function() wrap(void Function() f) => () {
          if (closeFirst) Navigator.of(context).pop();
          f();
        };
    return [
      if (canRecheck(p)) _Action('Check with iTechPay', Icons.sync, wrap(() => _recheck(p)), primary: true, short: 'Recheck'),
      if (canDecide(p)) _Action('Approve', Icons.check, wrap(() => _decide(p, approve: true)), primary: !canRecheck(p), color: Colors.green.shade700),
      if (canDecide(p)) _Action('Reject', Icons.close, wrap(() => _decide(p, approve: false)), color: Colors.red.shade700),
      if (isPaid(p)) _Action('Invoice', Icons.receipt_long_outlined, wrap(() => _invoice(p))),
      _Action('Delete', Icons.delete_outline, wrap(() => _delete(p)), color: Colors.red.shade700, overflow: true),
    ];
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pad = width >= 900 ? 24.0 : 16.0;
    final cs = Theme.of(context).colorScheme;
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? cs.surface : const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => router != null ? router.pop() : Navigator.of(context).pop(),
                tooltip: 'Back')
            : null,
        titleSpacing: canPop ? 0 : null,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Payments', style: TextStyle(fontWeight: FontWeight.w800)),
          if (_updatedAt != null)
            Text('Updated ${DateFormat('HH:mm').format(_updatedAt!)} · refreshes every minute',
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400)),
        ]),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Centered(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if ((_overview?.needsAttention ?? 0) > 0 && !_query.attention) ...[
                    _AttentionBanner(count: _overview!.needsAttention, onTap: () => _setQuery(const AdminPaymentsQuery(attention: true))),
                    const SizedBox(height: 12),
                  ],
                  if (_overview == null && _overviewError != null) ...[
                    _Notice(
                      icon: Icons.error_outline,
                      color: Colors.red.shade700,
                      text: 'The revenue summary could not be loaded: $_overviewError',
                      action: TextButton(onPressed: _loadOverview, child: const Text('Retry')),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_overview?.partial == true) ...[
                    _Notice(
                      icon: Icons.info_outline,
                      color: const Color(0xFF2563EB),
                      text: 'Showing basic totals only. The monthly figures, chart and breakdowns appear once the latest backend is deployed.',
                    ),
                    const SizedBox(height: 12),
                  ],
                  _Kpis(overview: _overview, failed: _overviewError != null && _overview == null, onAttention: () => _setQuery(const AdminPaymentsQuery(attention: true))),
                  const SizedBox(height: 12),
                  if (_overview != null && !_overview!.partial)
                    _Insights(
                      overview: _overview!,
                      onPurpose: (v) => _setQuery(_query.copyWith(purpose: v, status: 'completed,approved', attention: false)),
                      onMethod: (v) => _setQuery(_query.copyWith(method: v, status: 'completed,approved', attention: false)),
                    ),
                  const SizedBox(height: 20),
                  _FilterBar(
                    query: _query,
                    overview: _overview,
                    search: _search,
                    onSearch: _onSearch,
                    onChanged: _setQuery,
                    onClear: _clearFilters,
                    total: _loading ? null : _total,
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            ..._listSlivers(pad, width),
          ],
        ),
      ),
    );
  }

  List<Widget> _listSlivers(double pad, double width) {
    if (_loading && _items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _Centered(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(children: List.generate(6, (_) => const _SkeletonRow())),
          ),
        ),
      ];
    }
    if (_error != null && _items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _Empty(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load payments',
              text: _error!,
              action: FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Try again'))),
        ),
      ];
    }
    if (_items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _Empty(
            icon: _query.attention ? Icons.task_alt : Icons.receipt_long_outlined,
            title: _query.attention ? 'Nothing needs your attention' : 'No payments found',
            text: _query.isFiltered ? 'Try another search or clear the filters.' : 'Payments will appear here.',
            action: _query.isFiltered ? OutlinedButton(onPressed: _clearFilters, child: const Text('Clear filters')) : null,
          ),
        ),
      ];
    }

    final table = width >= 1000;
    return [
      if (table) SliverToBoxAdapter(child: _Centered(padding: EdgeInsets.symmetric(horizontal: pad), child: const _TableHeader())),
      SliverList.builder(
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final p = _items[i];
          final actions = _actionsFor(p);
          final busy = _busy.contains(p.id);
          return _Centered(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: table
                ? _TableRow(payment: p, actions: actions, busy: busy, onTap: () => _open(p), first: i == 0, last: i == _items.length - 1)
                : _PaymentCard(payment: p, actions: actions, busy: busy, onTap: () => _open(p)),
          );
        },
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Center(
            child: _loadingMore
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                : _page < _totalPages
                    ? OutlinedButton(onPressed: _loadMore, child: Text('Load more (${_total - _items.length} left)'))
                    : Text('${_items.length} of $_total shown', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          ),
        ),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Layout pieces
// ═══════════════════════════════════════════════════════════════════════════

class _Centered extends StatelessWidget {
  const _Centered({required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(padding: padding, child: child),
        ),
      );
}

BoxDecoration _card(BuildContext context, {Color? border}) {
  final cs = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border ?? cs.outlineVariant.withValues(alpha: 0.6)),
  );
}

class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFFEA580C);
    return Material(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            const Icon(Icons.notifications_active_outlined, color: c),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count payment${count == 1 ? ' needs' : 's need'} your attention',
                style: const TextStyle(fontWeight: FontWeight.w700, color: c),
              ),
            ),
            const Text('Review', style: TextStyle(fontWeight: FontWeight.w700, color: c)),
            const Icon(Icons.chevron_right, color: c),
          ]),
        ),
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.overview, required this.onAttention, this.failed = false});
  final PaymentsOverview? overview;
  /// The summary could not be loaded: show "—" instead of loading placeholders.
  final bool failed;
  final VoidCallback onAttention;

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final change = o == null || o.partial ? null : o.monthChange;
    // "—" when the summary failed, or for figures a partial summary doesn't have.
    String? v(String? Function(PaymentsOverview o) f, {bool needsFull = false}) =>
        o == null ? (failed ? '—' : null) : (needsFull && o.partial ? '—' : f(o));
    final tiles = [
      _Kpi(
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF10B981),
        label: 'Total revenue',
        value: v((o) => compactRwf(o.total.revenue)),
        caption: o == null ? null : '${o.total.count} paid payments',
      ),
      _Kpi(
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF0EA5E9),
        label: 'This month',
        value: v((o) => compactRwf(o.thisMonth.revenue), needsFull: true),
        caption: o == null || o.partial
            ? (o?.partial == true ? 'Needs backend update' : null)
            : change == null
                ? '${o.thisMonth.count} payments'
                : '${change >= 0 ? '+' : '−'}${change.abs().toStringAsFixed(0)}% vs last month',
        captionColor: change == null
            ? null
            : change >= 0
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
      ),
      _Kpi(
        icon: Icons.bolt_outlined,
        color: const Color(0xFF8B5CF6),
        label: 'Paid online',
        value: v((o) => '${(o.onlineShare * 100).toStringAsFixed(0)}%', needsFull: true),
        caption: o == null || o.partial
            ? (o?.partial == true ? 'Needs backend update' : null)
            : o.online30Started == 0
                ? 'of revenue via iTechPay'
                : '${o.online30Started - o.online30NotPaid}/${o.online30Started} done · 30 days',
      ),
      _Kpi(
        icon: Icons.pending_actions_outlined,
        color: (o?.needsAttention ?? 0) > 0 ? const Color(0xFFEA580C) : const Color(0xFF64748B),
        label: 'Needs attention',
        value: v((o) => '${o.needsAttention}'),
        caption: 'To approve or check',
        onTap: onAttention,
      ),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 4 : 2;
      const gap = 12.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
    });
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.color, required this.label, this.value, this.caption, this.captionColor, this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final String? value;
  final String? caption;
  final Color? captionColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: _card(context),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 10),
            value == null
                ? Container(height: 24, width: 90, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)))
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ),
            const SizedBox(height: 4),
            Text(caption ?? ' ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: captionColor ?? cs.onSurfaceVariant, fontWeight: captionColor != null ? FontWeight.w700 : null)),
          ]),
        ),
      ),
    );
  }
}

class _Insights extends StatelessWidget {
  const _Insights({required this.overview, required this.onPurpose, required this.onMethod});
  final PaymentsOverview overview;
  final ValueChanged<String> onPurpose;
  final ValueChanged<String> onMethod;

  @override
  Widget build(BuildContext context) {
    final chart = _RevenueChart(daily: overview.daily);
    final breakdown = _Breakdown(overview: overview, onPurpose: onPurpose, onMethod: onMethod);
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 900) {
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(flex: 3, child: chart),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: breakdown),
          ]),
        );
      }
      return Column(children: [chart, const SizedBox(height: 12), breakdown]);
    });
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.daily});
  final List<DailyRevenue> daily;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = daily.fold<num>(0, (a, d) => a + d.revenue);
    final max = daily.fold<num>(0, (a, d) => d.revenue > a ? d.revenue : a);
    final fmt = DateFormat('d MMM');
    return Container(
      decoration: _card(context),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Last 30 days', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
          Text(rwf(total), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        Text('Money received per day', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: max == 0
              ? Center(child: Text('No payments in the last 30 days', style: TextStyle(color: cs.onSurfaceVariant)))
              : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (final d in daily)
                    Expanded(
                      child: Tooltip(
                        message: '${fmt.format(d.date)} · ${rwf(d.revenue)} · ${d.count} payment${d.count == 1 ? '' : 's'}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Container(
                            height: d.revenue == 0 ? 3 : (d.revenue / max * 126).clamp(4, 126).toDouble(),
                            decoration: BoxDecoration(
                              color: d.revenue == 0 ? cs.outlineVariant.withValues(alpha: 0.5) : const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
        ),
        const SizedBox(height: 8),
        if (daily.isNotEmpty)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final d in [daily.first, daily[daily.length ~/ 2], daily.last])
              Text(fmt.format(d.date), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ]),
        if (max > 0) ...[
          const SizedBox(height: 14),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final best = daily.reduce((a, b) => b.revenue > a.revenue ? b : a);
            final count = daily.fold<int>(0, (a, d) => a + d.count);
            final active = daily.where((d) => d.revenue > 0).length;
            Widget stat(String label, String value) => Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
                  ]),
                );
            final a = [stat('Payments', '$count'), stat('Per day (avg)', compactRwf(total / 30))];
            final b = [stat('Best day · ${fmt.format(best.date)}', compactRwf(best.revenue)), stat('Days with sales', '$active / 30')];
            // Two columns on phones, four in a row elsewhere.
            if (MediaQuery.sizeOf(context).width < 600) {
              return Column(children: [Row(children: a), const SizedBox(height: 10), Row(children: b)]);
            }
            return Row(children: [...a, ...b]);
          }),
        ],
      ]),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.overview, required this.onPurpose, required this.onMethod});
  final PaymentsOverview overview;
  final ValueChanged<String> onPurpose;
  final ValueChanged<String> onMethod;

  @override
  Widget build(BuildContext context) {
    final total = overview.total.revenue;
    Widget section(String title, List<(String key, String label, Color color, MoneyCount mc)> rows, ValueChanged<String> onTap) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        for (final r in rows)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onTap(r.$1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(children: [
                Row(children: [
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: r.$3, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.$2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  Text(compactRwf(r.$4.revenue), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : (r.$4.revenue / total).toDouble(),
                    minHeight: 5,
                    color: r.$3,
                    backgroundColor: r.$3.withValues(alpha: 0.12),
                  ),
                ),
              ]),
            ),
          ),
      ]);
    }

    final purposes = [
      for (final k in purposeLabels.keys) (k, purposeLabels[k]!, purposeColors[k]!, overview.byPurpose[k] ?? MoneyCount.zero),
    ];
    final methods = [
      for (final k in const ['mtn_momo', 'airtel_money', 'card'])
        if ((overview.byMethod[k]?.count ?? 0) > 0 || k != 'card') (k, methodLabels[k]!, methodColors[k]!, overview.byMethod[k] ?? MoneyCount.zero),
    ];
    return Container(
      decoration: _card(context),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Where the money comes from', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 12),
        section('BY SERVICE', purposes, onPurpose),
        const SizedBox(height: 12),
        section('BY METHOD', methods, onMethod),
      ]),
    );
  }
}

// ── Filters ─────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.query,
    required this.overview,
    required this.search,
    required this.onSearch,
    required this.onChanged,
    required this.onClear,
    required this.total,
  });
  final AdminPaymentsQuery query;
  final PaymentsOverview? overview;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final ValueChanged<AdminPaymentsQuery> onChanged;
  final VoidCallback onClear;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sc = overview?.statusCounts ?? const {};
    int count(List<String> s) => s.fold(0, (a, k) => a + (sc[k] ?? 0));

    final statuses = <(String label, String? status, bool attention, int? n)>[
      ('All', null, false, overview?.allCount),
      ('Needs attention', null, true, overview?.needsAttention),
      ('Paid', 'completed,approved', false, overview == null ? null : count(['completed', 'approved'])),
      ('Pending', 'pending', false, overview == null ? null : count(['pending'])),
      ('In review', 'admin_review', false, overview == null ? null : count(['admin_review'])),
      ('Failed', 'failed', false, overview == null ? null : count(['failed'])),
      ('Cancelled', 'cancelled', false, overview == null ? null : count(['cancelled'])),
    ];

    final searchField = TextField(
      controller: search,
      onChanged: onSearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search name, phone, course, school, ref',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder(
          valueListenable: search,
          builder: (_, v, __) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear search',
                  onPressed: () {
                    search.clear();
                    onSearch('');
                  }),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      ),
    );

    final serviceChips = [
      for (final e in [(null, 'All services'), ...purposeLabels.entries.map((e) => (e.key, e.value))])
        ChoiceChip(
          label: Text(e.$2),
          avatar: e.$1 == null ? null : Icon(purposeIcons[e.$1], size: 16),
          selected: query.purpose == e.$1,
          showCheckmark: false,
          onSelected: (_) => onChanged(query.copyWith(purpose: e.$1)),
        ),
    ];

    final more = PopupMenuButton<String>(
      tooltip: 'More filters',
      onSelected: (v) {
        final parts = v.split(':');
        if (parts[0] == 'channel') onChanged(query.copyWith(channel: parts[1] == 'all' ? null : parts[1]));
        if (parts[0] == 'method') onChanged(query.copyWith(method: parts[1] == 'all' ? null : parts[1]));
      },
      itemBuilder: (_) => [
        const PopupMenuItem(enabled: false, height: 30, child: Text('CHANNEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
        CheckedPopupMenuItem(value: 'channel:all', checked: query.channel == null, child: const Text('Online and manual')),
        CheckedPopupMenuItem(value: 'channel:online', checked: query.channel == 'online', child: const Text('Online (iTechPay)')),
        CheckedPopupMenuItem(value: 'channel:manual', checked: query.channel == 'manual', child: const Text('Manual (admin approval)')),
        const PopupMenuDivider(),
        const PopupMenuItem(enabled: false, height: 30, child: Text('METHOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
        CheckedPopupMenuItem(value: 'method:all', checked: query.method == null, child: const Text('All methods')),
        for (final m in methodLabels.entries) CheckedPopupMenuItem(value: 'method:${m.key}', checked: query.method == m.key, child: Text(m.value)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: (query.channel != null || query.method != null) ? cs.primary.withValues(alpha: 0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.tune, size: 18),
          const SizedBox(width: 6),
          Text(
            [if (query.channel != null) query.channel == 'online' ? 'Online' : 'Manual', if (query.method != null) methodLabel(query.method!)]
                .join(' · ')
                .ifEmpty('Filters'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (wide)
          Row(children: [
            Expanded(child: searchField),
            const SizedBox(width: 12),
            Wrap(spacing: 8, children: serviceChips),
            const SizedBox(width: 12),
            more,
          ])
        else ...[
          searchField,
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final w in serviceChips) Padding(padding: const EdgeInsets.only(right: 8), child: w),
              more,
            ]),
          ),
        ],
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final s in statuses)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(s.$4 == null ? s.$1 : '${s.$1}  ${s.$4}'),
                  selected: s.$3 ? query.attention : (!query.attention && query.status == s.$2),
                  showCheckmark: false,
                  selectedColor: s.$3 ? const Color(0xFFEA580C).withValues(alpha: 0.16) : null,
                  onSelected: (_) => onChanged(query.copyWith(status: s.$2, attention: s.$3)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text(total == null ? 'Loading…' : '$total payment${total == 1 ? '' : 's'}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (query.isFiltered)
            TextButton.icon(onPressed: onClear, icon: const Icon(Icons.filter_alt_off_outlined, size: 16), label: const Text('Clear filters')),
        ]),
      ]);
    });
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

// ── Rows & cards ────────────────────────────────────────────────────────────

class _Action {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool overflow;
  final Color? color;

  /// Shorter label for the table's action column.
  final String? short;
  const _Action(this.label, this.icon, this.onTap, {this.primary = false, this.overflow = false, this.color, this.short});
}

class _Actions extends StatelessWidget {
  const _Actions({required this.actions, required this.busy, this.compact = false});
  final List<_Action> actions;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (busy) return const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    final primary = actions.where((a) => a.primary).toList();
    final rest = actions.where((a) => !a.primary).toList();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final a in primary)
        compact
            ? IconButton.filled(
                tooltip: a.label,
                onPressed: a.onTap,
                icon: Icon(a.icon, size: 18),
                style: IconButton.styleFrom(backgroundColor: a.color, foregroundColor: Colors.white),
              )
            : Tooltip(
                message: a.label,
                child: FilledButton.icon(
                  onPressed: a.onTap,
                  icon: Icon(a.icon, size: 16),
                  label: Text(a.short ?? a.label),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: a.color, foregroundColor: Colors.white),
                ),
              ),
      if (rest.isNotEmpty)
        PopupMenuButton<int>(
          tooltip: 'More actions',
          icon: const Icon(Icons.more_vert),
          onSelected: (i) => rest[i].onTap(),
          itemBuilder: (_) => [
            for (var i = 0; i < rest.length; i++)
              PopupMenuItem(
                value: i,
                child: Row(children: [
                  Icon(rest[i].icon, size: 18, color: rest[i].color),
                  const SizedBox(width: 10),
                  Text(rest[i].label, style: TextStyle(color: rest[i].color)),
                ]),
              ),
          ],
        ),
    ]);
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        Expanded(flex: 26, child: Text('CUSTOMER', style: style)),
        Expanded(flex: 25, child: Text('FOR', style: style)),
        Expanded(flex: 14, child: Text('AMOUNT', style: style, textAlign: TextAlign.right)),
        const SizedBox(width: 20),
        Expanded(flex: 21, child: Text('METHOD', style: style)),
        Expanded(flex: 18, child: Text('STATUS', style: style)),
        Expanded(flex: 11, child: Text('DATE', style: style)),
        const SizedBox(width: 200),
      ]),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.payment, required this.actions, required this.busy, required this.onTap, required this.first, required this.last});
  final Payment payment;
  final List<_Action> actions;
  final bool busy;
  final VoidCallback onTap;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: cs.onSurfaceVariant);
    final radius = BorderRadius.vertical(top: Radius.circular(first ? 16 : 0), bottom: Radius.circular(last ? 16 : 0));
    final attention = needsAttention(p);
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border(
              left: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
              right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
              top: first ? BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)) : BorderSide.none,
              bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(0, 10, 16, 10),
          child: Row(children: [
            // Accent strip for payments an admin has to act on.
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 13),
              decoration: BoxDecoration(
                color: attention ? const Color(0xFFEA580C) : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
              ),
            ),
            Expanded(
              flex: 26,
              child: Row(children: [
                Initials(customerName(p), size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(customerName(p), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(p.user?.email ?? p.contactInfo, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
                  ]),
                ),
              ]),
            ),
            Expanded(
              flex: 25,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(itemTitle(p), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Tag(itemSubtitle(p).toUpperCase(), purposeColors[purposeOf(p)]!, icon: purposeIcons[purposeOf(p)]),
                ]),
              ),
            ),
            Expanded(flex: 14, child: Text(rwf(p.amount), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))),
            const SizedBox(width: 20),
            Expanded(flex: 21, child: Align(alignment: Alignment.centerLeft, child: MethodLine(p))),
            Expanded(flex: 18, child: Align(alignment: Alignment.centerLeft, child: StatusPill(statusLook(p), dense: true))),
            Expanded(flex: 11, child: Tooltip(message: fullDate(p.createdAt), child: Text(relativeDate(p.createdAt), style: muted))),
            SizedBox(width: 200, child: Align(alignment: Alignment.centerRight, child: _Actions(actions: actions, busy: busy))),
          ]),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.actions, required this.busy, required this.onTap});
  final Payment payment;
  final List<_Action> actions;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final cs = Theme.of(context).colorScheme;
    final attention = needsAttention(p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: _card(context, border: attention ? const Color(0xFFEA580C).withValues(alpha: 0.5) : null),
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Initials(customerName(p), size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(customerName(p), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(itemTitle(p), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ]),
                ),
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(right: 8), child: StatusPill(statusLook(p), dense: true)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text(rwf(p.amount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Flexible(child: Tag(purposeLabels[purposeOf(p)]!.toUpperCase(), purposeColors[purposeOf(p)]!, icon: purposeIcons[purposeOf(p)])),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      MethodLine(p),
                      Text(relativeDate(p.createdAt), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                _Actions(actions: actions, busy: busy, compact: true),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _card(context),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(140, 12), const SizedBox(height: 8), bar(220, 10)])),
        bar(70, 14),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.text, this.action});
  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(children: [
        Icon(icon, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    );
  }
}

/// One-line message above the summary, with an optional action.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text, this.action});
  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35)))),
          if (action != null) action!,
        ]),
      );
}

class _Callout extends StatelessWidget {
  const _Callout(this.text, this.icon, this.color);
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35))),
        ]),
      );
}

// ── Details ─────────────────────────────────────────────────────────────────

class _PaymentDetails extends StatelessWidget {
  const _PaymentDetails({required this.payment, required this.actions});
  final Payment payment;
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final look = statusLook(p);
    final cs = Theme.of(context).colorScheme;
    final approval = p.adminApproval;

    Widget row(String label, String? value, {bool copy = false}) {
      if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
          Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
          if (copy)
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied'), behavior: SnackBarBehavior.floating));
              },
              child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.copy_rounded, size: 16, color: cs.onSurfaceVariant)),
            ),
        ]),
      );
    }

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            ...children,
          ]),
        );

    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), children: [
          Row(children: [
            Tag(purposeLabels[purposeOf(p)]!.toUpperCase(), purposeColors[purposeOf(p)]!, icon: purposeIcons[purposeOf(p)]),
            const SizedBox(width: 6),
            Tag(p.isOnline ? 'ONLINE · iTechPay' : 'MANUAL', p.isOnline ? const Color(0xFF059669) : cs.onSurfaceVariant),
          ]),
          const SizedBox(height: 10),
          Text(rwf(p.amount), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(itemTitle(p), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: look.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(look.icon, color: look.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(look.label, style: TextStyle(fontWeight: FontWeight.w800, color: look.color)),
                  if (look.hint != null)
                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(look.hint!, style: const TextStyle(fontSize: 13, height: 1.3))),
                ]),
              ),
            ]),
          ),
          section('CUSTOMER', [
            row('Name', customerName(p)),
            row('Email', p.user?.email, copy: true),
            row('Phone', p.user?.phone, copy: true),
            row('Contact given', p.contactInfo),
          ]),
          section('WHAT WAS BOUGHT', [
            row('Service', purposeLabels[purposeOf(p)]),
            if (p.isSchoolTerm) ...[
              row('School', p.schoolName),
              row('Term', p.termLabel),
              row('Student places', '${p.seats ?? 0}'),
            ] else
              row('Course', p.course?.title),
          ]),
          section('PAYMENT', [
            row('Method', methodLabel(p.paymentMethod)),
            row('Transaction ID', p.transactionId, copy: true),
            if (p.isOnline) ...[
              row('iTechPay reference', p.gatewayReference, copy: true),
              row('iTechPay status', p.gatewayStatus),
              if (p.failureReason != null) row('Note', p.failureReason),
            ],
            row('Started', fullDate(p.createdAt)),
            if (p.paymentDate != null) row('Paid on', fullDate(p.paymentDate!)),
          ]),
          if (approval != null)
            section('ADMIN', [
              row('By', approval.approvedByName ?? approval.approvedBy),
              row('At', fullDate(approval.approvedAt)),
              row('Note', approval.adminNotes),
            ]),
        ]),
      ),
      if (actions.isNotEmpty)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)))),
          child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
            for (final a in actions.reversed)
              a.primary
                  ? FilledButton.icon(
                      onPressed: a.onTap, icon: Icon(a.icon, size: 18), label: Text(a.label), style: FilledButton.styleFrom(backgroundColor: a.color))
                  : OutlinedButton.icon(
                      onPressed: a.onTap, icon: Icon(a.icon, size: 18), label: Text(a.label), style: OutlinedButton.styleFrom(foregroundColor: a.color)),
          ]),
        ),
    ]);
  }
}
