import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/school/pickers.dart';
import '../../../widgets/school/school_ui.dart';

/// Register (or edit) a student with class, parents and address.
/// Duplicates are checked by the server; the user confirms before a second
/// record is ever created. After registering, code + PIN are shown once.
class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({super.key, required this.schoolId, this.fixedClass, this.classes, this.existing});
  final String schoolId;
  /// Class the student goes into (class teacher flow).
  final Map<String, dynamic>? fixedClass;
  /// Classes to choose from (school admin flow).
  final List<Map<String, dynamic>>? classes;
  /// Student being edited.
  final Map<String, dynamic>? existing;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _Guardian {
  _Guardian({String name = '', String phone = '', String relationship = 'Parent'})
      : name = TextEditingController(text: name),
        phone = TextEditingController(text: phone),
        relationship = relationship;
  final TextEditingController name;
  final TextEditingController phone;
  String relationship;
  void dispose() {
    name.dispose();
    phone.dispose();
  }
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = SchoolService();
  late final _name = TextEditingController(text: widget.existing?['fullName'] ?? '');
  String? _gender;
  DateTime? _dob;
  String? _classId;
  Map<String, String> _address = {};
  final List<_Guardian> _guardians = [];
  bool _busy = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _classId = widget.fixedClass?['id'] as String? ?? e?['classroomId'] as String?;
    if (e != null) {
      _gender = e['gender'] as String?;
      _dob = parseDate(e['dateOfBirth']);
      _address = Map<String, String>.from(((e['address'] as Map?) ?? {}).map((k, v) => MapEntry('$k', '$v')));
      for (final g in (e['guardians'] as List?) ?? const []) {
        _guardians.add(_Guardian(name: '${g['name'] ?? ''}', phone: '${g['phone'] ?? ''}', relationship: '${g['relationship'] ?? 'Parent'}'));
      }
    }
    if (_guardians.isEmpty) _guardians.add(_Guardian());
  }

  @override
  void dispose() {
    _name.dispose();
    for (final g in _guardians) {
      g.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _body({bool confirmNew = false}) => {
        'fullName': _name.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dob?.toIso8601String().substring(0, 10),
        if (!_editing) 'classroomId': _classId,
        'address': _address,
        'guardians': [
          for (final g in _guardians)
            if (g.name.text.trim().isNotEmpty || g.phone.text.trim().isNotEmpty)
              {'name': g.name.text.trim(), 'phone': g.phone.text.trim(), 'relationship': g.relationship},
        ],
        if (confirmNew) 'confirmNew': true,
      };

  Future<void> _save({bool confirmNew = false}) async {
    if (!_form.currentState!.validate()) return;
    if (_classId == null) return showSnack(context, 'Choose the class', error: true);
    setState(() => _busy = true);
    try {
      if (_editing) {
        final r = await _svc.updateMember(widget.schoolId, '${widget.existing!['id']}', _body());
        if (!mounted) return;
        await _showParentPins(SchoolService.list(r['parents']), (r['warnings'] as List?)?.cast<String>() ?? const []);
        if (mounted) Navigator.pop(context, true);
        return;
      }
      final r = await _svc.addStudent(widget.schoolId, _body(confirmNew: confirmNew));
      if (!mounted) return;
      final c = Map<String, dynamic>.from(r['credentials'] as Map);
      final parents = SchoolService.list(r['parents']);
      await showCredentialsDialog(
        context,
        title: '${_name.text.trim()} is registered',
        rows: [
          MapEntry('Student code', '${c['studentCode']}'),
          MapEntry('PIN', '${c['pin']}'),
          for (final p in parents.where((p) => p['pin'] != null)) ...[
            MapEntry('Parent ${p['name']} — phone', '${p['phone']}'),
            MapEntry('Parent ${p['name']} — PIN', '${p['pin']}'),
          ],
        ],
        extra: [
          for (final p in parents.where((p) => p['existing'] == true))
            Padding(padding: const EdgeInsets.only(bottom: 6), child: T('${p['name']} already has a parent account; this child was added to it.', style: const TextStyle(fontSize: 12.5))),
          for (final w in (r['warnings'] as List?) ?? const [])
            Padding(padding: const EdgeInsets.only(bottom: 6), child: T('$w', style: const TextStyle(fontSize: 12.5, color: AppTheme.warningColor))),
        ],
        note: 'Students sign in with "School code & PIN". Write the code and PIN on a card for the student (and the parent PIN for the parent). They are not shown again; you can create a new PIN any time.',
      );
      if (mounted) Navigator.pop(context, true);
    } on SchoolApiError catch (e) {
      if (!mounted) return;
      if (e.code == 'POSSIBLE_DUPLICATE') {
        await _handleDuplicate(e.candidates);
      } else {
        showSnack(context, e.message, error: true);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showParentPins(List<Map<String, dynamic>> parents, List<String> warnings) async {
    final created = parents.where((p) => p['pin'] != null).toList();
    if (created.isEmpty && warnings.isEmpty) return;
    await showCredentialsDialog(
      context,
      title: 'Parent accounts',
      rows: [for (final p in created) MapEntry('${p['name']} (${p['phone']})', '${p['pin']}')],
      extra: [for (final w in warnings) Text(w, style: const TextStyle(color: AppTheme.warningColor))],
    );
  }

  Future<void> _handleDuplicate(List<Map<String, dynamic>> candidates) async {
    final choice = await showDialog<Object>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const T('Is this the same student?'),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            T('These students already exist in your school. Registering the same child twice gives them two accounts.', style: TextStyle(color: AppTheme.getSecondaryTextColor(ctx))),
            const SizedBox(height: 10),
            for (final c in candidates)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(initialsOf(c['fullName']))),
                  title: T('${c['fullName']}'),
                  subtitle: Text([
                    '${c['studentCode'] ?? ''}',
                    c['classroom']?['name'] ?? 'No class',
                    if (c['dateOfBirth'] != null) 'Born ${fmtDate(c['dateOfBirth'])}',
                    if (c['strong'] == true) 'Very likely the same',
                  ].where((e) => '$e'.isNotEmpty).join(' · ')),
                  trailing: TextButton(onPressed: () => Navigator.pop(ctx, c), child: const T('Same')),
                ),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const T('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'new'), child: const T('Different student — register')),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'new') return _save(confirmNew: true);
    final c = choice as Map<String, dynamic>;
    final inThisClass = c['classroomId'] == _classId;
    if (inThisClass) {
      showSnack(context, '${c['fullName']} is already in this class');
      Navigator.pop(context, false);
      return;
    }
    try {
      await _svc.enrollStudent(widget.schoolId, '${c['id']}', _classId!);
      if (mounted) {
        showSnack(context, '${c['fullName']} added to the class — no new account created');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = widget.classes ?? const [];
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: Text(_editing ? 'Edit student' : 'Register student')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : () => _save(),
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
            label: Text(_editing ? 'Save' : 'Register'),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: SchoolPage(maxWidth: 720, children: [
          SectionCard(
            title: 'Student',
            child: Column(children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name *', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Enter the full name' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'female', child: T('Female')),
                      DropdownMenuItem(value: 'male', child: T('Male')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(context: context, firstDate: DateTime(now.year - 40), lastDate: now, initialDate: _dob ?? DateTime(now.year - 12));
                      if (d != null) setState(() => _dob = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date of birth', prefixIcon: Icon(Icons.cake_outlined)),
                      child: Text(_dob == null ? 'Choose' : fmtDate(_dob)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (widget.fixedClass != null)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.meeting_room_outlined)),
                  child: T('${widget.fixedClass!['name']}'),
                )
              else if (!_editing)
                DropdownButtonFormField<String>(
                  initialValue: _classId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Class *', prefixIcon: Icon(Icons.meeting_room_outlined)),
                  items: [for (final c in classes) DropdownMenuItem(value: '${c['id']}', child: T('${c['name']}  (${c['studentCount'] ?? 0} students)'))],
                  onChanged: (v) => setState(() => _classId = v),
                  validator: (v) => v == null ? 'Choose the class' : null,
                ),
            ]),
          ),
          SectionCard(
            title: 'Parents / guardians',
            subtitle: 'Each parent with a phone number gets a parent account (phone + PIN) to follow homework and results.',
            child: Column(children: [
              for (var i = 0; i < _guardians.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                Row(children: [
                  Expanded(child: TextFormField(controller: _guardians[i].name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)))),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      initialValue: ['Parent', 'Mother', 'Father', 'Guardian', 'Sibling', 'Other'].contains(_guardians[i].relationship) ? _guardians[i].relationship : 'Parent',
                      decoration: const InputDecoration(labelText: 'Relationship'),
                      items: [for (final r in ['Parent', 'Mother', 'Father', 'Guardian', 'Sibling', 'Other']) DropdownMenuItem(value: r, child: Text(r))],
                      onChanged: (v) => _guardians[i].relationship = v ?? 'Parent',
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _guardians[i].phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone', hintText: '07XX XXX XXX', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty || v.replaceAll(RegExp(r'\D'), '').length >= 9) ? null : 'Phone number is too short',
                    ),
                  ),
                  if (_guardians.length > 1)
                    IconButton(tooltip: 'Remove', icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _guardians.removeAt(i).dispose())),
                ]),
              ],
              if (_guardians.length < 3)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(onPressed: () => setState(() => _guardians.add(_Guardian())), icon: const Icon(Icons.add), label: const T('Add another parent')),
                ),
            ]),
          ),
          SectionCard(title: 'Home address', child: AddressFields(value: _address, onChanged: (v) => _address = v)),
        ]),
      ),
    );
  }
}
