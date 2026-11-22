import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/forms/password_field.dart';
import '../../../../widgets/school/pickers.dart';
import '../../../../widgets/school/school_ui.dart';
import '../school_admin_dashboard_screen.dart';

/// Teachers and school admins, what they teach, their activity.
class StaffSection extends StatefulWidget {
  const StaffSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<StaffSection> createState() => _StaffSectionState();
}

class _StaffSectionState extends State<StaffSection> {
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();
  bool _showInactive = false;

  Future<void> _add(String role) async {
    final r = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(builder: (_) => StaffFormScreen(c: widget.c, role: role)));
    if (r == null || !mounted) return;
    final cr = Map<String, dynamic>.from(r['credentials'] as Map);
    await showCredentialsDialog(context, title: '${(r['user'] as Map)['fullName']} can now sign in', rows: [
      if (cr['email'] != null) MapEntry('Email', '${cr['email']}'),
      if (cr['phone'] != null) MapEntry('Phone', '${cr['phone']}'),
      MapEntry('Password', '${cr['password']}'),
    ], note: cr['email'] != null
        ? 'They sign in with "Email". Ask them to change the password after the first sign-in. It is not shown again.'
        : 'They sign in with "Email" using the phone number and this password. It is not shown again.');
    _key.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      key: _key,
      load: () => widget.c.svc.staff(widget.c.schoolId, active: _showInactive ? 'all' : 'true'),
      builder: (context, d, reload) {
        final staff = SchoolService.list(d['staff']);
        final admins = staff.where((s) => s['role'] == 'school_admin').toList();
        final teachers = staff.where((s) => s['role'] == 'instructor').toList();
        return SchoolPage(onRefresh: reload, children: [
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            FilledButton.icon(onPressed: () => _add('instructor'), icon: const Icon(Icons.person_add_alt_1_outlined), label: const T('Add teacher')),
            OutlinedButton.icon(onPressed: () => _add('school_admin'), icon: const Icon(Icons.admin_panel_settings_outlined), label: const T('Add school admin')),
            FilterChip(label: const T('Show removed'), selected: _showInactive, onSelected: (v) { setState(() => _showInactive = v); _key.currentState?.reload(); }),
          ]),
          SectionCard(
            title: 'Teachers (${teachers.length})',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: teachers.isEmpty
                ? const EmptyState(icon: Icons.co_present_outlined, title: 'No teachers yet', message: 'Add your teachers with their address, subjects and the classes they teach.')
                : Column(children: [for (final t in teachers) _tile(t, reload)]),
          ),
          SectionCard(
            title: 'School admins (${admins.length})',
            subtitle: 'Head teacher, director of studies, bursar…',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(children: [for (final a in admins) _tile(a, reload)]),
          ),
        ]);
      },
    );
  }

  Widget _tile(Map<String, dynamic> t, Future<void> Function() reload) {
    final teaches = SchoolService.list(t['teaches']);
    final classOf = SchoolService.list(t['classTeacherOf']);
    final isMain = widget.c.school['admin'] is Map ? (widget.c.school['admin'] as Map)['_id'] == t['id'] : widget.c.school['admin'] == t['id'];
    final lines = <String>[
      if (classOf.isNotEmpty) 'Class teacher of ${classOf.map((c) => c['name']).join(', ')}',
      if (teaches.isNotEmpty) teaches.map((s) => '${s['subject']} ${s['className']}').join(', '),
      if (teaches.isEmpty && classOf.isEmpty && t['role'] == 'instructor') 'Not teaching any class yet',
      [t['email'], t['phone']].where((e) => e != null).join(' · '),
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(initialsOf(t['fullName']))),
      title: Row(children: [
        Flexible(child: T('${t['fullName']}', overflow: TextOverflow.ellipsis)),
        if (isMain) const Padding(padding: EdgeInsets.only(left: 6), child: StatusPill('Main admin', tone: Tone.info)),
        if (t['isActive'] == false) const Padding(padding: EdgeInsets.only(left: 6), child: StatusPill('Removed', tone: Tone.bad)),
      ]),
      subtitle: Text(lines.where((l) => l.isNotEmpty).join('\n')),
      isThreeLine: lines.where((l) => l.isNotEmpty).length > 1,
      onTap: () => context.push('/school-admin/teachers/${t['id']}?school=${widget.c.schoolId}'),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          final svc = widget.c.svc;
          try {
            if (v == 'edit') {
              final ok = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(builder: (_) => StaffFormScreen(c: widget.c, role: '${t['role']}', existing: t)));
              if (ok != null) reload();
            } else if (v == 'password') {
              if (!await confirm(context, title: 'New password for ${t['fullName']}?', message: 'The old password stops working.', confirmLabel: 'Create password')) return;
              final r = await svc.resetCredentials(widget.c.schoolId, '${t['id']}');
              final cr = Map<String, dynamic>.from(r['credentials'] as Map);
              if (mounted) await showCredentialsDialog(context, title: 'New password', rows: [if (cr['email'] != null) MapEntry('Email', '${cr['email']}'), MapEntry('Password', '${cr['password']}')]);
            } else if (v == 'main') {
              await svc.setMainAdmin(widget.c.schoolId, '${t['id']}');
              await widget.c.reloadSchool();
              reload();
            } else if (v == 'toggle') {
              final active = t['isActive'] != false;
              if (active && !await confirm(context, title: 'Remove ${t['fullName']}?', message: 'They can no longer sign in and are removed from their classes and subjects. History is kept.', confirmLabel: 'Remove', destructive: true)) return;
              await svc.updateMember(widget.c.schoolId, '${t['id']}', {'isActive': !active});
              reload();
            }
          } catch (e) {
            if (mounted) showSnack(context, e.toString(), error: true);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: T('Edit details')),
          const PopupMenuItem(value: 'password', child: T('New password')),
          if (widget.c.superAdmin && t['role'] == 'school_admin' && !isMain) const PopupMenuItem(value: 'main', child: T('Make main admin')),
          PopupMenuItem(value: 'toggle', child: Text(t['isActive'] == false ? 'Reactivate' : 'Remove from school')),
        ],
      ),
    );
  }
}

/// Add or edit a teacher / school admin (address, subjects, levels, qualification).
class StaffFormScreen extends StatefulWidget {
  const StaffFormScreen({super.key, required this.c, required this.role, this.existing});
  final SchoolCtx c;
  final String role;
  final Map<String, dynamic>? existing;

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?['fullName'] ?? '');
  late final _email = TextEditingController(text: widget.existing?['email'] ?? '');
  late final _phone = TextEditingController(text: widget.existing?['phone'] ?? '');
  final _password = TextEditingController();
  late final _qualification = TextEditingController(text: widget.existing?['teacherProfile']?['qualification'] ?? '');
  late final _years = TextEditingController(text: '${widget.existing?['teacherProfile']?['yearsExperience'] ?? ''}');
  String? _gender;
  Map<String, String> _address = {};
  Set<String> _subjects = {};
  Set<String> _levels = {};
  bool _busy = false;

  bool get _editing => widget.existing != null;
  bool get _teacher => widget.role == 'instructor';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _gender = e['gender'] as String?;
      _address = Map<String, String>.from(((e['address'] as Map?) ?? {}).map((k, v) => MapEntry('$k', '$v')));
      _subjects = {...((e['teacherProfile']?['subjects'] as List?) ?? const []).map((s) => '$s')};
      _levels = {...((e['teacherProfile']?['levels'] as List?) ?? const []).map((s) => '$s')};
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _qualification, _years]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final profile = {
      'qualification': _qualification.text.trim(),
      'yearsExperience': int.tryParse(_years.text.trim()),
      'subjects': _subjects.toList(),
      'levels': _levels.toList(),
    };
    try {
      final svc = widget.c.svc;
      Map<String, dynamic> r;
      if (_editing) {
        r = await svc.updateMember(widget.c.schoolId, '${widget.existing!['id']}', {
          'fullName': _name.text.trim(),
          'phone': _phone.text.trim(),
          'gender': _gender,
          'address': _address,
          'teacherProfile': profile,
        });
      } else {
        final body = {
          'fullName': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          if (_password.text.isNotEmpty) 'password': _password.text,
          'gender': _gender,
          'address': _address,
          'teacherProfile': profile,
        };
        r = _teacher ? await svc.addTeacher(widget.c.schoolId, body) : await svc.addSchoolAdmin(widget.c.schoolId, body);
      }
      if (mounted) Navigator.pop(context, r);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing ? 'Edit ${_teacher ? 'teacher' : 'school admin'}' : (_teacher ? 'Add teacher' : 'Add school admin');
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _save,
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
            label: Text(_editing ? 'Save' : 'Add'),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: SchoolPage(maxWidth: 720, children: [
          SectionCard(
            title: 'Identity and sign-in',
            child: Column(children: [
              TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v == null || v.trim().length < 3) ? 'Enter the full name' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [DropdownMenuItem(value: 'female', child: T('Female')), DropdownMenuItem(value: 'male', child: T('Male'))],
                onChanged: (v) => _gender = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_editing,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', helperText: 'Used to sign in. Email or phone is required.', prefixIcon: Icon(Icons.alternate_email)),
                validator: (v) {
                  if (_editing) return null;
                  final e = v?.trim() ?? '';
                  if (e.isEmpty && _phone.text.trim().isEmpty) return 'Enter an email or a phone number';
                  if (e.isNotEmpty && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(e)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', hintText: '07XX XXX XXX', prefixIcon: Icon(Icons.phone_outlined))),
              if (!_editing) ...[
                const SizedBox(height: 12),
                PasswordField(
                  controller: _password,
                  showGenerate: true,
                  helper: 'Leave empty and ECH creates a strong password. It is shown once after saving.',
                  validator: (v) => (v != null && v.isNotEmpty && v.length < 8) ? 'At least 8 characters' : null,
                ),
              ],
            ]),
          ),
          SectionCard(title: 'Home address', child: AddressFields(value: _address, onChanged: (v) => _address = v)),
          SectionCard(
            title: 'Teaching profile',
            subtitle: _teacher ? 'Classes and subjects they teach are assigned on each class (Classes → class → Subjects).' : null,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              T('Subjects', style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context))),
              const SizedBox(height: 6),
              ChipPicker(options: commonSubjects.take(14).toList(), selected: _subjects, allowCustom: true, customLabel: 'Other subject', onChanged: (v) => setState(() => _subjects = v)),
              const SizedBox(height: 14),
              T('Levels', style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context))),
              const SizedBox(height: 6),
              ChipPicker(options: ((widget.c.school['levels'] as List?)?.isNotEmpty == true ? (widget.c.school['levels'] as List).map((e) => '$e').toList() : schoolLevels), selected: _levels, onChanged: (v) => setState(() => _levels = v)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(controller: _qualification, decoration: const InputDecoration(labelText: 'Qualification', hintText: 'e.g. A0 Education, Biology'))),
                const SizedBox(width: 12),
                SizedBox(width: 150, child: TextFormField(controller: _years, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Years teaching'))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
