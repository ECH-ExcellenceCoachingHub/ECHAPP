import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/teacher_access_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/teacher_access_provider.dart';
import 'teacher_journey_widgets.dart';

const _subjects = [
  'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'Kinyarwanda', 'French', 'Kiswahili',
  'History', 'Geography', 'Entrepreneurship', 'ICT / Computer Science', 'Economics', 'General Studies',
  'Literature', 'Social Studies', 'Science & Elementary Technology', 'Accounting', 'Religious Education',
  'Creative Arts', 'Physical Education',
];
const _schoolTypes = ['Public', 'Government-aided', 'Private', 'International', 'TVET', 'University / College', 'Other'];
const _provinces = ['Kigali City', 'Northern', 'Southern', 'Eastern', 'Western', 'Outside Rwanda'];
const _qualifications = ['A2 (Secondary certificate)', 'Diploma (A1)', "Bachelor's (A0)", "Master's", 'PhD', 'Other'];

/// Step 1 of the teacher journey: where and what the teacher teaches.
/// The admin sees all of it when approving the account.
class TeacherOnboardingScreen extends ConsumerStatefulWidget {
  const TeacherOnboardingScreen({super.key});

  @override
  ConsumerState<TeacherOnboardingScreen> createState() => _TeacherOnboardingScreenState();
}

class _TeacherOnboardingScreenState extends ConsumerState<TeacherOnboardingScreen> {
  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _school = TextEditingController();
  final _district = TextEditingController();
  final _years = TextEditingController();
  final _bio = TextEditingController();
  final _otherLevel = TextEditingController();
  final _otherSubject = TextEditingController();

  String? _schoolType;
  String? _province;
  String? _qualification;
  final Set<String> _levels = {};
  final Set<String> _subjectsChosen = {};
  List<LevelGroup> _groups = LevelGroup.defaults;
  int _step = 0;
  bool _saving = false;
  bool _loaded = false;
  bool _wasApproved = false;
  String? _stepError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    final name = user?.fullName ?? '';
    _name.text = name == 'Unknown User' ? '' : name;
    _phone.text = user?.phone ?? '';
    try {
      final s = await ref.read(teacherAccessProvider.future);
      final p = s.profile;
      _groups = s.levelGroups;
      _wasApproved = s.approved && s.selfRegistered;
      if (p.phone.isNotEmpty) _phone.text = p.phone;
      _school.text = p.school;
      _district.text = p.district;
      _years.text = p.yearsExperience?.toString() ?? '';
      _bio.text = p.bio;
      _schoolType = _schoolTypes.contains(p.schoolType) ? p.schoolType : null;
      _province = _provinces.contains(p.province) ? p.province : null;
      _qualification = _qualifications.contains(p.qualification) ? p.qualification : (p.qualification.isEmpty ? null : 'Other');
      _levels.addAll(p.levels);
      _subjectsChosen.addAll(p.subjects);
    } catch (_) {
      // A fresh form is fine when the status can't be loaded.
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _school, _district, _years, _bio, _otherLevel, _otherSubject]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateStep() {
    setState(() => _stepError = null);
    final ok = _formKeys[_step].currentState?.validate() ?? true;
    if (!ok) return false;
    if (_step == 1) {
      if (_levels.isEmpty) {
        setState(() => _stepError = 'Choose at least one class or level you teach.');
        return false;
      }
      if (_subjectsChosen.isEmpty) {
        setState(() => _stepError = 'Choose at least one subject.');
        return false;
      }
    }
    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final user = ref.read(authProvider).user;
      final name = _name.text.trim();
      if (user != null && name.isNotEmpty && name != user.fullName) {
        try {
          await ref.read(authProvider.notifier).updateProfile(fullName: name);
        } catch (_) {/* the teacher profile still matters more */}
      }
      final profile = TeacherProfile(
        school: _school.text.trim(),
        schoolType: _schoolType ?? '',
        district: _district.text.trim(),
        province: _province ?? '',
        country: _province == 'Outside Rwanda' ? 'Other' : 'Rwanda',
        levels: _levels.toList(),
        subjects: _subjectsChosen.toList(),
        yearsExperience: int.tryParse(_years.text.trim()),
        qualification: _qualification ?? '',
        phone: _phone.text.trim(),
        bio: _bio.text.trim(),
      );
      final status = await ref.read(teacherAccessServiceProvider).submitProfile(profile);
      ref.invalidate(teacherAccessProvider);
      if (!mounted) return;
      if (status.canUseTools) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
        context.go('/teacher/dashboard');
      } else {
        context.go(status.gateRoute ?? '/teacher/pending');
      }
    } catch (e) {
      if (mounted) setState(() => _stepError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['You and your school', 'What you teach', 'Your experience'];
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(_wasApproved ? 'Edit teacher profile' : 'Teacher profile'),
        leading: _step > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--))
            : (context.canPop() ? null : const SizedBox.shrink()),
        actions: const [TeacherLogoutButton()],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(children: [
                TeacherJourneyProgress(current: 0, profileStep: _step, profileSteps: 3),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text('Step ${_step + 1} of 3 · ${titles[_step]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            'An ECH admin checks this before your teacher account is activated.',
                            style: TextStyle(color: Theme.of(context).hintColor),
                          ),
                          const SizedBox(height: 20),
                          if (_step == 0) _stepSchool(),
                          if (_step == 1) _stepTeaching(),
                          if (_step == 2) _stepExperience(),
                          if (_stepError != null) ...[
                            const SizedBox(height: 12),
                            Text(_stepError!, style: const TextStyle(color: Colors.red)),
                          ],
                        ]),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                            onPressed: _saving ? null : _next,
                            child: _saving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text(_step < 2 ? 'Next' : (_wasApproved ? 'Save profile' : 'Submit for approval'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _stepSchool() {
    return Form(
      key: _formKeys[0],
      child: Column(children: [
        TextFormField(controller: _name, decoration: _dec('Full name', icon: Icons.person_outline), validator: _required, textCapitalization: TextCapitalization.words),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _dec('Phone number', hint: '07xx xxx xxx', icon: Icons.phone_outlined),
          validator: (v) => (v == null || v.replaceAll(RegExp(r'\D'), '').length < 9) ? 'Enter a valid phone number' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(controller: _school, decoration: _dec('School / institution name', icon: Icons.apartment_outlined), validator: _required, textCapitalization: TextCapitalization.words),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _schoolType,
          decoration: _dec('Type of school', icon: Icons.category_outlined),
          items: [for (final t in _schoolTypes) DropdownMenuItem(value: t, child: Text(t))],
          onChanged: (v) => setState(() => _schoolType = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _province,
          decoration: _dec('Province', icon: Icons.map_outlined),
          items: [for (final p in _provinces) DropdownMenuItem(value: p, child: Text(p))],
          onChanged: (v) => setState(() => _province = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(controller: _district, decoration: _dec('District / city', icon: Icons.location_on_outlined), validator: _required, textCapitalization: TextCapitalization.words),
      ]),
    );
  }

  Widget _stepTeaching() {
    final custom = _levels.where((l) => !_groups.any((g) => g.levels.contains(l))).toList();
    final customSubjects = _subjectsChosen.where((s) => !_subjects.contains(s)).toList();
    return Form(
      key: _formKeys[1],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Classes / levels you teach', 'Select all that apply — you can teach more than one.'),
        for (final g in _groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(g.group, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in g.levels)
              FilterChip(
                label: Text(l),
                selected: _levels.contains(l),
                onSelected: (on) => setState(() => on ? _levels.add(l) : _levels.remove(l)),
              ),
          ]),
        ],
        if (custom.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in custom) InputChip(label: Text(l), onDeleted: () => setState(() => _levels.remove(l))),
          ]),
        ],
        const SizedBox(height: 10),
        _AddOther(controller: _otherLevel, hint: 'Other class (e.g. Senior 4 MCB, Year 2)', onAdd: (v) => setState(() => _levels.add(v))),
        const SizedBox(height: 24),
        const _SectionLabel('Subjects you teach', 'Select all that apply.'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in _subjects)
            FilterChip(
              label: Text(s),
              selected: _subjectsChosen.contains(s),
              onSelected: (on) => setState(() => on ? _subjectsChosen.add(s) : _subjectsChosen.remove(s)),
            ),
          for (final s in customSubjects) InputChip(label: Text(s), onDeleted: () => setState(() => _subjectsChosen.remove(s))),
        ]),
        const SizedBox(height: 10),
        _AddOther(controller: _otherSubject, hint: 'Other subject', onAdd: (v) => setState(() => _subjectsChosen.add(v))),
      ]),
    );
  }

  Widget _stepExperience() {
    return Form(
      key: _formKeys[2],
      child: Column(children: [
        TextFormField(
          controller: _years,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _dec('Years of teaching experience', icon: Icons.timeline_outlined),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n > 60 ? 'Enter a number of years' : null;
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _qualification,
          decoration: _dec('Highest qualification', icon: Icons.workspace_premium_outlined),
          items: [for (final q in _qualifications) DropdownMenuItem(value: q, child: Text(q))],
          onChanged: (v) => setState(() => _qualification = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _bio,
          maxLines: 4,
          maxLength: 1000,
          decoration: _dec('About you (optional)', hint: 'Anything that helps us know your teaching — e.g. your role, clubs, achievements.'),
        ),
        const SizedBox(height: 8),
        _Summary(levels: _levels.toList(), subjects: _subjectsChosen.toList(), school: _school.text),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionLabel(this.title, this.subtitle);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      Text(subtitle, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
    ]);
  }
}

class _AddOther extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onAdd;
  const _AddOther({required this.controller, required this.hint, required this.onAdd});

  void _add() {
    final v = controller.text.trim();
    if (v.isEmpty) return;
    onAdd(v);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(isDense: true, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          onSubmitted: (_) => _add(),
        ),
      ),
      const SizedBox(width: 8),
      OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
    ]);
  }
}

class _Summary extends StatelessWidget {
  final List<String> levels;
  final List<String> subjects;
  final String school;
  const _Summary({required this.levels, required this.subjects, required this.school});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('You will be recommended teacher\'s guides for:', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('${levels.join(', ')} · ${subjects.join(', ')}'),
        if (school.trim().isNotEmpty) Text('at ${school.trim()}', style: TextStyle(color: Theme.of(context).hintColor)),
      ]),
    );
  }
}
