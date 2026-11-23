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
  bool? _onNetwork;
  bool _busy = false;

  String get _mode => (_p['mode'] as String?) ?? 'anywhere';

  @override
  void initState() {
    super.initState();
    widget.c.svc.myIp().then((r) {
      if (mounted) setState(() { _myIp = r['ip'] as String?; _onNetwork = r['onSchoolNetwork'] as bool?; });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _ipInput.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_mode == 'network' && _ips.isEmpty) {
      return showSnack(context, 'Add the school\'s internet address first, otherwise no student can sign in.', error: true);
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
      if (mounted) showSnack(context, 'Sign-in rules saved');
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
        title: 'School internet',
        subtitle: _mode == 'network'
            ? 'Required: only these addresses can use student accounts.'
            : _mode == 'code'
                ? 'Optional: devices on these addresses sign in without a class code (e.g. the computer lab).'
                : 'Used only when you choose an "at school only" mode.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_myIp != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppTheme.infoColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.router_outlined, color: AppTheme.infoColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This device is on $_myIp${_onNetwork == true ? ' — already allowed.' : '. If you are at school on the school internet now, add it.'}',
                  ),
                ),
                if (_onNetwork != true && !_ips.contains(_myIp)) TextButton(onPressed: () => _addIp(_myIp!), child: const T('Add')),
              ]),
            ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final ip in _ips) InputChip(label: Text(ip), onDeleted: () => setState(() => _ips.remove(ip))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ipInput,
                decoration: const InputDecoration(labelText: 'Add address', hintText: 'e.g. 41.186.12.34 or 41.186.12.0/24', isDense: true),
                onSubmitted: _addIp,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () => _addIp(_ipInput.text), child: const T('Add')),
          ]),
          const SizedBox(height: 8),
          T('Tip: open this page on a school computer and press "Add". If your internet provider changes the address often, use the class-code mode instead.', style: TextStyle(fontSize: 12, color: muted)),
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
