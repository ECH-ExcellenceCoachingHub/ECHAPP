import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../services/api/school_service.dart';
import '../../../widgets/forms/password_field.dart';
import '../../../widgets/school/school_ui.dart';

/// Super admin: every school, its subscription and members.
class AdminSchoolsScreen extends StatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  State<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends State<AdminSchoolsScreen> {
  final _svc = SchoolService();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _schools = [];
  int _total = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _schools.isEmpty;
      _error = null;
    });
    try {
      final r = await _svc.listSchools(search: _search.text.trim());
      setState(() {
        _schools = SchoolService.list(r['schools']);
        _total = (r['total'] as num?)?.toInt() ?? _schools.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CreateSchoolScreen()),
    );
    if (created == null || !mounted) return;
    final c = Map<String, dynamic>.from(created['credentials'] as Map? ?? {});
    final school = Map<String, dynamic>.from(created['school'] as Map? ?? {});
    await showCredentialsDialog(
      context,
      title: 'School created — admin sign-in',
      rows: [
        MapEntry('School', '${school['name']} (${school['code']})'),
        if (c['email'] != null) MapEntry('Email', '${c['email']}'),
        if (c['phone'] != null) MapEntry('Phone', '${c['phone']}'),
        MapEntry('Password', '${c['password']}'),
      ],
    );
    _load();
  }

  Tone _subTone(String? s) => switch (s) {
        'active' => Tone.good,
        'grace' => Tone.warn,
        'trial' => Tone.info,
        _ => Tone.bad,
      };

  String _subLabel(String? s) => switch (s) {
        'active' => 'Paid',
        'grace' => 'Grace period',
        'trial' => 'Trial',
        'expired' => 'Expired',
        'inactive' => 'Deactivated',
        _ => '—',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Schools'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go('/admin')),
        actions: [
          TextButton.icon(onPressed: () => context.push('/admin/school-courses'), icon: const Icon(Icons.menu_book_outlined), label: const Text('Courses for schools')),
          IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('New school')),
      body: SchoolPage(
        onRefresh: _load,
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name, code or district'),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), _load);
            },
          ),
          if (_loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            ErrorRetry(message: _error!, onRetry: _load)
          else if (_schools.isEmpty)
            EmptyState(
              icon: Icons.apartment_outlined,
              title: 'No schools yet',
              message: 'Create a school and its administrator to get started.',
              action: FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('New school')),
            )
          else ...[
            Text('$_total school${_total == 1 ? '' : 's'}', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
            for (final s in _schools) _schoolCard(s),
          ],
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _schoolCard(Map<String, dynamic> s) {
    final sub = Map<String, dynamic>.from(s['subscription'] as Map? ?? {});
    final admin = s['admin'] is Map ? s['admin'] as Map : null;
    final muted = AppTheme.getSecondaryTextColor(context);
    return Material(
      color: AppTheme.getCardColor(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await context.push('/school-detail/${s['id']}');
          _load();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6))),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              child: Text((s['code'] ?? '?').toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('${s['name']}', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.getTextColor(context)))),
                  const SizedBox(width: 8),
                  StatusPill(_subLabel(sub['status'] as String?), tone: _subTone(sub['status'] as String?)),
                ]),
                const SizedBox(height: 4),
                Text(
                  [addressLine(s['address']), if (admin != null) 'Admin: ${admin['fullName']}'].where((e) => e.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 14, children: [
                  _count(Icons.people_alt_outlined, '${s['studentCount'] ?? 0}/${sub['studentLimit'] ?? 0} students'),
                  _count(Icons.co_present_outlined, '${s['teacherCount'] ?? 0} teachers'),
                  _count(Icons.meeting_room_outlined, '${s['classCount'] ?? 0} classes'),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }

  Widget _count(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 15, color: AppTheme.getSecondaryTextColor(context)),
        const SizedBox(width: 4),
        Text(t, style: TextStyle(fontSize: 12.5, color: AppTheme.getSecondaryTextColor(context))),
      ]);
}

/// Full-page form: school details + address + first school admin + billing.
class CreateSchoolScreen extends StatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = SchoolService();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _head = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _trial = TextEditingController(text: '30');
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPhone = TextEditingController();
  final _adminPassword = TextEditingController();
  String _type = 'secondary';
  String _ownership = 'private';
  Map<String, String> _address = {};
  Set<String> _levels = {};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _code, _phone, _email, _head, _price, _trial, _adminName, _adminEmail, _adminPhone, _adminPassword]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final r = await _svc.createSchool({
        'name': _name.text.trim(),
        if (_code.text.trim().isNotEmpty) 'code': _code.text.trim(),
        'type': _type,
        'ownership': _ownership,
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'headTeacherName': _head.text.trim(),
        'address': _address,
        'levels': _levels.toList(),
        'pricePerStudentPerTerm': num.tryParse(_price.text.trim()) ?? 0,
        'trialStudentLimit': int.tryParse(_trial.text.trim()) ?? 30,
        'admin': {
          'fullName': _adminName.text.trim(),
          'email': _adminEmail.text.trim(),
          'phone': _adminPhone.text.trim(),
          if (_adminPassword.text.isNotEmpty) 'password': _adminPassword.text,
        },
      });
      if (mounted) Navigator.pop(context, r);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v, String what) => (v == null || v.trim().isEmpty) ? 'Enter $what' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(title: const Text('New school')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _save,
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
            label: const Text('Create school'),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: SchoolPage(maxWidth: 760, children: [
          SectionCard(
            title: 'School',
            child: Column(children: [
              TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'School name *', prefixIcon: Icon(Icons.apartment_outlined)), validator: (v) => _required(v, 'the school name')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'School code', helperText: 'Prefix of every student code (2–8 letters). Leave empty to use the initials.', prefixIcon: Icon(Icons.tag)),
                validator: (v) => (v == null || v.isEmpty || RegExp(r'^[A-Za-z0-9]{2,8}$').hasMatch(v.trim())) ? null : '2–8 letters or digits',
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'nursery', child: Text('Nursery')),
                      DropdownMenuItem(value: 'primary', child: Text('Primary')),
                      DropdownMenuItem(value: 'secondary', child: Text('Secondary')),
                      DropdownMenuItem(value: 'tvet', child: Text('TVET')),
                      DropdownMenuItem(value: 'combined', child: Text('Nursery–Secondary')),
                      DropdownMenuItem(value: 'university', child: Text('University')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'secondary'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _ownership,
                    decoration: const InputDecoration(labelText: 'Ownership'),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('Public')),
                      DropdownMenuItem(value: 'government_aided', child: Text('Government-aided')),
                      DropdownMenuItem(value: 'private', child: Text('Private')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _ownership = v ?? 'private'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _head, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Head teacher / director', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'School phone', prefixIcon: Icon(Icons.phone_outlined)))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'School email', prefixIcon: Icon(Icons.alternate_email)))),
              ]),
            ]),
          ),
          SectionCard(title: 'Address', child: AddressFields(value: _address, onChanged: (v) => _address = v)),
          SectionCard(
            title: 'Levels taught',
            subtitle: 'Used to suggest classes. You can change this later.',
            child: ChipPicker(options: schoolLevels, selected: _levels, onChanged: (v) => setState(() => _levels = v)),
          ),
          SectionCard(
            title: 'Billing',
            subtitle: 'Schools pay per student per term. Record payments on the school page.',
            child: Row(children: [
              Expanded(child: TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per student per term (RWF)'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _trial, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Trial students (before payment)'))),
            ]),
          ),
          SectionCard(
            title: 'School administrator',
            subtitle: 'The head teacher or director of studies who will manage the school in ECH.',
            child: Column(children: [
              TextFormField(controller: _adminName, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => _required(v, 'the full name')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.alternate_email)),
                validator: (v) => (v == null || !RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _adminPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 12),
              PasswordField(
                controller: _adminPassword,
                showGenerate: true,
                helper: 'Leave empty and ECH creates a strong password. It is shown once after saving.',
                validator: (v) => (v != null && v.isNotEmpty && v.length < 8) ? 'At least 8 characters' : null,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
