import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../widgets/school/school_ui.dart';
import '../school_admin_dashboard_screen.dart';

/// Where and when students may use ECH: anywhere, school only with a class
/// code, or school only on the school's internet.
class AccessSection extends StatefulWidget {
  const AccessSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<AccessSection> createState() => _AccessSectionState();
}

class _AccessSectionState extends State<AccessSection> {
  late Map<String, dynamic> _p = Map<String, dynamic>.from(widget.c.school['studentAccess'] as Map? ?? {});
  late final List<String> _ips = [...((_p['allowedIps'] as List?) ?? const []).map((e) => '$e')];
  late Set<String> _pinless = {...((_p['pinlessLevels'] as List?) ?? const ['N1', 'N2', 'N3', 'P1', 'P2', 'P3']).map((e) => '$e')};
  final _ipInput = TextEditingController();
  String? _myIp;
  String? _suggested; // rule to save for this connection (IPv6: the /64 network)
  bool _usable = true;
  bool? _onNetwork;
  bool _detecting = false;
  String? _detectError;
  bool _busy = false;

  String get _mode => (_p['mode'] as String?) ?? 'anywhere';

  @override
  void initState() {
    super.initState();
    _detect();
  }

  /// Asks the server which internet address this device is using right now.
  Future<void> _detect() async {
    setState(() { _detecting = true; _detectError = null; });
    try {
      final r = await widget.c.svc.myIp();
      if (!mounted) return;
      setState(() {
        _myIp = r['ip'] as String?;
        _suggested = (r['suggestedRule'] as String?) ?? _myIp;
        _usable = r['usable'] != false;
        _onNetwork = r['onSchoolNetwork'] as bool?;
      });
    } catch (e) {
      if (mounted) setState(() => _detectError = e.toString());
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  bool get _thisConnectionSaved => _onNetwork == true || (_suggested != null && _ips.contains(_suggested));

  /// Adds the detected connection and saves right away (admins forget "Save").
  Future<void> _useThisConnection() async {
    final rule = _suggested;
    if (rule == null) return;
    if (!_ips.contains(rule)) setState(() => _ips.add(rule));
    await _save(message: 'This connection is now a school internet');
    if (mounted) setState(() => _onNetwork = true);
  }

  @override
  void dispose() {
    _ipInput.dispose();
    super.dispose();
  }

  Future<void> _save({String message = 'Sign-in rules saved'}) async {
    if (_mode == 'network' && _ips.isEmpty) {
      // Offer the connection we detected instead of asking for an address.
      if (_suggested != null && _usable) {
        final yes = await confirm(
          context,
          title: 'Are you at school now?',
          message: 'You are connected through $_suggested. If this device is on the school Wi-Fi or lab network right now, we use it as the school internet.',
          confirmLabel: 'Yes, use it',
        );
        if (!yes || !mounted) return;
        setState(() => _ips.add(_suggested!));
      } else {
        return showSnack(context, 'Open this page on the school Wi-Fi and tap "Use this connection" first, otherwise no student can sign in.', error: true);
      }
    }
    setState(() => _busy = true);
    try {
      final s = await widget.c.svc.updateSchool(widget.c.schoolId, {
        'studentAccess': {
          'mode': _mode,
          'codeMinutes': _p['codeMinutes'] ?? 60,
          'dayStartsAt': _p['dayStartsAt'] ?? '06:00',
          'dayEndsAt': _p['dayEndsAt'] ?? '17:00',
          'maxSessionHours': _p['maxSessionHours'] ?? 9,
          'allowedIps': _ips,
          'pinlessLevels': _pinless.toList(),
        },
      });
      _p = Map<String, dynamic>.from(s['studentAccess'] as Map? ?? _p);
      await widget.c.reloadSchool();
      if (mounted) showSnack(context, message);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addIp(String ip) {
    final v = ip.trim();
    if (v.isEmpty || _ips.contains(v)) return;
    setState(() => _ips.add(v));
    _ipInput.clear();
  }

  Widget _detectCard() {
    final muted = AppTheme.getSecondaryTextColor(context);
    final saved = _thisConnectionSaved;
    final tone = _detectError != null || !_usable ? Tone.warn : saved ? Tone.good : Tone.info;
    final c = toneColor(context, tone);
    Widget step(String n, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Text(n, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
            ),
            const SizedBox(width: 8),
            Expanded(child: T(text, style: TextStyle(fontSize: 13, color: muted))),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(saved ? Icons.verified_rounded : Icons.wifi_find_rounded, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              T(
                _detecting
                    ? 'Detecting your connection…'
                    : _detectError != null
                        ? 'Could not detect your connection'
                        : saved
                            ? 'This connection is a school internet'
                            : 'Your connection now',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (!_detecting && _suggested != null)
                SelectableText(_suggested!, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppTheme.getTextColor(context))),
            ]),
          ),
          IconButton(tooltip: trSchool(context, 'Detect again'), onPressed: _detecting ? null : _detect, icon: _detecting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh)),
        ]),
        if (!_usable && !_detecting) ...[
          const SizedBox(height: 6),
          T('This is a local address, so it cannot identify the school. Open ECH from the internet (not a local test server).', style: TextStyle(fontSize: 12.5, color: c)),
        ],
        if (!saved && _usable && _suggested != null && !_detecting) ...[
          const SizedBox(height: 10),
          step('1', 'Connect this phone or computer to the school Wi-Fi or lab network (not mobile data).'),
          step('2', 'Tap "Detect again" if you just changed network, then "Use this connection".'),
          step('3', 'Repeat on each school network (lab, staff room Wi-Fi…).'),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: _busy ? null : _useThisConnection,
            icon: const Icon(Icons.add_link),
            label: const T('Use this connection as school internet'),
          ),
        ],
        if (_detectError != null && !_detecting) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _detect, icon: const Icon(Icons.refresh), label: const T('Try again')),
        ],
      ]),
    );
  }

  Widget _timeButton(String key, String fallback, String label, IconData icon) => OutlinedButton.icon(
        icon: Icon(icon),
        label: T('$label ${_p[key] ?? fallback}'),
        onPressed: () async {
          final parts = '${_p[key] ?? fallback}'.split(':');
          final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
          if (t != null) setState(() => _p[key] = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
        },
      );

  Widget _modeCard(String value, IconData icon, String title, String text) {
    final selected = _mode == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _p['mode'] = value),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppTheme.primary : AppTheme.getBorderColor(context).withValues(alpha: 0.6), width: selected ? 1.6 : 1),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppTheme.primary : null),
              const SizedBox(width: 10),
              Icon(icon, color: AppTheme.getSecondaryTextColor(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(text, style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context))),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.getSecondaryTextColor(context);
    final schoolOnly = _mode != 'anywhere';
    return SchoolPage(maxWidth: 820, children: [
      SectionCard(
        title: 'Where can students sign in?',
        subtitle: 'Parents and teachers are not affected; they can always sign in.',
        child: Column(children: [
          _modeCard('anywhere', Icons.public, 'Anywhere', 'Student code + PIN at school and at home. Students can do homework and ECH courses at home.'),
          _modeCard('code', Icons.pin_outlined, 'At school only — with a class code',
              'Student code + PIN + the class code the teacher shows in class (changes every ${_p['codeMinutes'] ?? 60} min). Computers on the school internet below do not need the code.'),
          _modeCard('network', Icons.wifi, 'At school only — school internet',
              'Only from the school Wi-Fi or computer lab. ECH stops working as soon as the device leaves the school network. Needs a fixed school internet address.'),
        ]),
      ),
      if (schoolOnly)
        SectionCard(
          title: 'School day',
          subtitle: 'Students can only sign in during these hours, and their sessions end automatically. Boarding schools with evening prep: set a later end time.',
          child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _timeButton('dayStartsAt', '06:00', 'Students can sign in from', Icons.wb_twilight),
            _timeButton('dayEndsAt', '17:00', 'Sessions end at', Icons.schedule),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int>(
                initialValue: (_p['maxSessionHours'] as num?)?.toInt() ?? 9,
                decoration: const InputDecoration(labelText: 'At most, after sign-in', isDense: true),
                items: [for (final h in [2, 4, 6, 8, 9, 10, 12]) DropdownMenuItem(value: h, child: T('$h hours'))],
                onChanged: (v) => setState(() => _p['maxSessionHours'] = v ?? 9),
              ),
            ),
            if (_mode == 'code')
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int>(
                  initialValue: (_p['codeMinutes'] as num?)?.toInt() ?? 60,
                  decoration: const InputDecoration(labelText: 'Class code changes every', isDense: true),
                  items: [for (final m in [30, 45, 60, 90]) DropdownMenuItem(value: m, child: T('$m minutes'))],
                  onChanged: (v) => setState(() => _p['codeMinutes'] = v ?? 60),
                ),
              ),
          ]),
        ),
      SectionCard(
        icon: Icons.wifi_rounded,
        title: 'School internet',
        subtitle: _mode == 'network'
            ? 'Required: students can only sign in from these connections.'
            : _mode == 'code'
                ? 'Optional: devices on these connections sign in without a class code (e.g. the computer lab).'
                : 'Used only when you choose an "at school only" mode.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _detectCard(),
          const SizedBox(height: 14),
          if (_ips.isEmpty)
            T('No school internet saved yet.', style: TextStyle(color: muted))
          else ...[
            T('Saved school connections', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (var i = 0; i < _ips.length; i++) ...[
              if (i > 0) const RowDivider(),
              EntityTile(
                dense: true,
                leading: Icon(Icons.router_outlined, color: _ips[i] == _suggested ? AppTheme.successColor : muted),
                title: _ips[i],
                subtitle: _ips[i] == _suggested ? 'The connection you are using now' : (_ips[i].contains(':') ? 'IPv6 network' : 'Internet address'),
                trailing: IconButton(
                  tooltip: trSchool(context, 'Remove'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() {
                    _ips.removeAt(i);
                    if (_onNetwork == true && !_ips.contains(_suggested)) _onNetwork = false;
                  }),
                ),
              ),
            ],
          ],
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: T('Enter an address by hand', style: TextStyle(fontSize: 14, color: muted)),
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ipInput,
                      decoration: const InputDecoration(labelText: 'Address', hintText: 'e.g. 41.186.12.34 or 41.186.12.0/24', isDense: true),
                      onSubmitted: _addIp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => _addIp(_ipInput.text), child: const T('Add')),
                ]),
                const SizedBox(height: 8),
              ],
            ),
          ),
          T('If your internet provider changes the address often, use the class-code mode instead.', style: TextStyle(fontSize: 12, color: muted)),
        ]),
      ),
      if (_mode == 'code')
        SectionCard(
          title: 'Young pupils (no PIN)',
          subtitle: 'In these levels pupils type the class code and tap their name. The teacher sees who signed in.',
          child: ChipPicker(options: const ['N1', 'N2', 'N3', 'P1', 'P2', 'P3', 'P4'], selected: _pinless, onChanged: (v) => setState(() => _pinless = v)),
        ),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
        if (_mode == 'code')
          OutlinedButton.icon(
            onPressed: () => context.push('/school/code${widget.c.superAdmin ? '?schoolId=${widget.c.schoolId}' : ''}'),
            icon: const Icon(Icons.qr_code_2),
            label: const T('Show school code (lab)'),
          ),
        FilledButton.icon(onPressed: _busy ? null : _save, icon: const Icon(Icons.save_outlined), label: const T('Save rules')),
      ]),
      Text(
        'Teachers show a class code from their class page ("Class code"). Students who leave the school are signed out at the end of the day; in "school internet" mode they are signed out as soon as they leave the network.',
        style: TextStyle(fontSize: 12.5, color: muted),
      ),
    ]);
  }
}
