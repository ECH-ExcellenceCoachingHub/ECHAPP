import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../widgets/school/school_ui.dart';
import '../../../../widgets/school/combinations.dart';
import '../school_admin_dashboard_screen.dart';

/// School details ECH needs: names, contacts, address, levels, combinations.
class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final _form = GlobalKey<FormState>();
  late final s = widget.c.school;
  late final _name = TextEditingController(text: s['name'] ?? '');
  late final _code = TextEditingController(text: s['code'] ?? '');
  late final _description = TextEditingController(text: s['description'] ?? '');
  late final _head = TextEditingController(text: s['headTeacherName'] ?? '');
  late final _phone = TextEditingController(text: s['phone'] ?? '');
  late final _email = TextEditingController(text: s['email'] ?? '');
  late final _website = TextEditingController(text: s['website'] ?? '');
  late Map<String, String> _address = Map<String, String>.from(((s['address'] as Map?) ?? {}).map((k, v) => MapEntry('$k', '$v')));
  late Set<String> _levels = {...((s['levels'] as List?) ?? const []).map((e) => '$e')};
  late Set<String> _combos = {...((s['combinations'] as List?) ?? const []).map((e) => '$e')};
  late bool _active = s['isActive'] != false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _code, _description, _head, _phone, _email, _website]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.c.svc.updateSchool(widget.c.schoolId, {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'headTeacherName': _head.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'website': _website.text.trim(),
        'address': _address,
        'levels': _levels.toList(),
        'combinations': _combos.toList(),
        if (widget.c.superAdmin) 'code': _code.text.trim(),
        if (widget.c.superAdmin) 'isActive': _active,
      });
      await widget.c.reloadSchool();
      if (mounted) showSnack(context, 'School saved');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: SchoolPage(maxWidth: 760, children: [
        SectionCard(
          title: 'School',
          child: Column(children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'School name *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(
              controller: _code,
              enabled: widget.c.superAdmin,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: 'School code', helperText: widget.c.superAdmin ? 'Cannot change once student codes exist.' : 'Prefix of your student codes. Set by ECH.'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _head, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Head teacher / director')),
            const SizedBox(height: 12),
            TextFormField(controller: _description, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'About the school')),
          ]),
        ),
        SectionCard(
          title: 'Contacts',
          child: Column(children: [
            Row(children: [
              Expanded(child: TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)))),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: _website, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Website', prefixIcon: Icon(Icons.public))),
          ]),
        ),
        SectionCard(title: 'Address', child: AddressFields(value: _address, onChanged: (v) => _address = v)),
        SectionCard(title: 'Levels taught', child: ChipPicker(options: schoolLevels, selected: _levels, onChanged: (v) => setState(() => _levels = v))),
        SectionCard(
          icon: Icons.category_outlined,
          title: 'Combinations and trades',
          subtitle: 'Upper secondary streams (new REB curriculum and previous combinations) and TVET trades your school offers.',
          child: CombinationField(selected: _combos, extra: _combos.toList(), onChanged: (v) => setState(() => _combos = v)),
        ),
        if (widget.c.superAdmin)
          SectionCard(
            title: 'Status',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const T('School is active'),
              subtitle: T('When off, nobody from this school can sign in with a PIN and no new members can be added.', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(onPressed: _busy ? null : _save, icon: const Icon(Icons.save_outlined), label: const T('Save')),
        ),
      ]),
    );
  }
}
