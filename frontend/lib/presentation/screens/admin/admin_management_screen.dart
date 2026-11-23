import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_access_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/services/api/admin_accounts_service.dart';
import 'package:excellencecoachinghub/models/admin_account.dart';
import 'package:excellencecoachinghub/models/user.dart';

/// Super admins managing other super admins: details, password, limits,
/// active status, delete, and promoting a user to admin.
class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  final AdminService _adminService = AdminService();
  final AdminAccountsService _accounts = AdminAccountsService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<AdminAccount> _admins = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final admins = await _accounts.list(search: _searchController.text);
      if (!mounted) return;
      setState(() {
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  /// Runs an action, reports the outcome and reloads the list.
  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      _toast(success);
      _loadAdmins();
    } catch (e) {
      _toast('$e', error: true);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _editDetails(AdminAccount a) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditAdminDialog(admin: a),
    );
    if (result == null) return;
    await _run(
      () => _accounts.updateDetails(a.id, fullName: result['fullName'], email: result['email'], phone: result['phone']),
      'Details of ${result['fullName']} saved',
    );
  }

  Future<void> _changePassword(AdminAccount a) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _ChangePasswordDialog(admin: a),
    );
    if (password == null) return;
    try {
      final message = await _accounts.setPassword(a.id, password);
      _toast(message);
    } catch (e) {
      _toast('$e', error: true);
    }
  }

  Future<void> _setLimits(AdminAccount a) async {
    final limits = await showDialog<AdminLimits>(
      context: context,
      builder: (_) => _AdminLimitsDialog(admin: a),
    );
    if (limits == null) return;
    await _run(
      () => _accounts.setLimits(a.id, limits),
      limits.restricted ? 'Limits saved for ${a.fullName}' : '${a.fullName} now has full access',
    );
  }

  Future<void> _toggleActive(AdminAccount a) async {
    final activating = a.disabled;
    final ok = await _confirm(
      title: activating ? 'Activate admin' : 'Deactivate admin',
      message: activating
          ? '${a.fullName} will be able to sign in again.'
          : '${a.fullName} will be signed out and will not be able to sign in until activated again.',
      action: activating ? 'Activate' : 'Deactivate',
      danger: !activating,
    );
    if (!ok) return;
    await _run(() => _accounts.setActive(a.id, activating), '${a.fullName} ${activating ? 'activated' : 'deactivated'}');
  }

  Future<void> _delete(AdminAccount a) async {
    final ok = await _confirm(
      title: 'Delete admin',
      message: 'Permanently delete ${a.fullName} (${a.email}) and their sign-in account? This cannot be undone.',
      action: 'Delete',
      danger: true,
    );
    if (!ok) return;
    await _run(() => _accounts.delete(a.id), '${a.fullName} deleted');
  }

  Future<void> _promote(String userId) async {
    await _run(() => _adminService.updateUserRole(userId, 'admin'), 'User promoted to admin');
  }

  Future<bool> _confirm({required String title, required String message, required String action, bool danger = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? Colors.red : AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider.select((state) => state.user));
    final myAccess = ref.watch(myAdminAccessProvider).valueOrNull ?? AdminLimits.unrestricted;
    final canManage = myAccess.canChange('admins');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAdmins, tooltip: 'Refresh'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(
                      canManage
                          ? 'Edit admins, change their passwords and set what they can access'
                          : 'You can view admins but not change them',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                if (canManage)
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => PromoteAdminDialog(onPromote: _promote),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search admins...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (_) => _loadAdmins(),
              onChanged: (value) {
                if (value.isEmpty || value.length >= 2) _loadAdmins();
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, textAlign: TextAlign.center))
                      : _admins.isEmpty
                          ? const Center(child: Text('No admins found'))
                          : RefreshIndicator(
                              onRefresh: _loadAdmins,
                              child: ListView.builder(
                                itemCount: _admins.length,
                                itemBuilder: (context, index) {
                                  final a = _admins[index];
                                  return _adminCard(a, isMe: a.id == currentUser?.id, canManage: canManage);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(AdminAccount a, {required bool isMe, required bool canManage}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: isMe || !canManage ? null : () => _editDetails(a),
        leading: CircleAvatar(
          backgroundColor: a.disabled ? Colors.grey.withOpacity(0.2) : AppTheme.primaryGreen.withOpacity(0.1),
          child: Text(a.fullName.isNotEmpty ? a.fullName[0].toUpperCase() : '?'),
        ),
        title: Text(
          a.fullName,
          style: a.disabled ? TextStyle(color: theme.disabledColor) : null,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([a.email, if (a.phone != null && a.phone!.isNotEmpty) a.phone].join(' · ')),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _badge(
                  a.limits.summary,
                  a.limits.restricted ? Colors.orange : AppTheme.primaryGreen,
                  a.limits.restricted ? Icons.lock_outline : Icons.verified_user_outlined,
                ),
                if (a.disabled) _badge('Deactivated', Colors.red, Icons.block),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: isMe
            ? const Chip(label: Text('You'))
            : !canManage
                ? null
                : PopupMenuButton<String>(
                    tooltip: 'Manage ${a.fullName}',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editDetails(a);
                          break;
                        case 'password':
                          _changePassword(a);
                          break;
                        case 'limits':
                          _setLimits(a);
                          break;
                        case 'status':
                          _toggleActive(a);
                          break;
                        case 'delete':
                          _delete(a);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      _menuItem('edit', Icons.edit_outlined, 'Edit details'),
                      _menuItem('password', Icons.password, 'Change password'),
                      _menuItem('limits', Icons.tune, 'Set limits'),
                      const PopupMenuDivider(),
                      _menuItem(
                        'status',
                        a.disabled ? Icons.play_arrow : Icons.pause,
                        a.disabled ? 'Activate' : 'Deactivate',
                        color: a.disabled ? Colors.green : Colors.orange,
                      ),
                      _menuItem('delete', Icons.delete_outline, 'Delete', color: Colors.red),
                    ],
                  ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: color != null ? TextStyle(color: color) : null),
      ]),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

double _dialogWidth(BuildContext context, [double max = 440]) {
  final w = MediaQuery.of(context).size.width;
  return w < max + 40 ? w * 0.85 : max;
}

// ── Edit details ─────────────────────────────────────────────────────────

class _EditAdminDialog extends StatefulWidget {
  final AdminAccount admin;
  const _EditAdminDialog({required this.admin});

  @override
  State<_EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends State<_EditAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.admin.fullName);
  late final _email = TextEditingController(text: widget.admin.email);
  late final _phone = TextEditingController(text: widget.admin.phone ?? '');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit admin details'),
      content: SizedBox(
        width: _dialogWidth(context),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email (used to sign in)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'fullName': _name.text.trim(),
              'email': _email.text.trim(),
              'phone': _phone.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ── Change password ──────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  final AdminAccount admin;
  const _ChangePasswordDialog({required this.admin});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _generate() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789@#%&';
    final rnd = Random.secure();
    final value = List.generate(14, (_) => chars[rnd.nextInt(chars.length)]).join();
    setState(() {
      _password.text = value;
      _confirm.text = value;
      _obscure = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change password for ${widget.admin.fullName}'),
      content: SizedBox(
        width: _dialogWidth(context),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'They will be signed out of the app and must sign in with the new password. '
                'Share it with them privately.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'New password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    tooltip: _obscure ? 'Show' : 'Hide',
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirm new password', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('Generate a strong password'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _password.text);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          child: const Text('Change password'),
        ),
      ],
    );
  }
}

// ── Limits ───────────────────────────────────────────────────────────────

class _AdminLimitsDialog extends StatefulWidget {
  final AdminAccount admin;
  const _AdminLimitsDialog({required this.admin});

  @override
  State<_AdminLimitsDialog> createState() => _AdminLimitsDialogState();
}

class _AdminLimitsDialogState extends State<_AdminLimitsDialog> {
  late bool _restricted = widget.admin.limits.restricted;
  late final Map<String, String> _levels = {
    for (final area in AdminLimits.areas)
      area: widget.admin.limits.restricted ? widget.admin.limits.level(area) : 'full',
  };

  void _setAll(String level) => setState(() {
        for (final area in AdminLimits.areas) {
          _levels[area] = level;
        }
      });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Limits for ${widget.admin.fullName}'),
      content: SizedBox(
        width: _dialogWidth(context, 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Limit this admin\'s access'),
                subtitle: Text(_restricted
                    ? 'They can only use the areas set below. Changes apply on their next action.'
                    : 'Off: full access to everything, like any super admin.'),
                value: _restricted,
                activeColor: AppTheme.primaryGreen,
                onChanged: (v) => setState(() => _restricted = v),
              ),
              if (_restricted) ...[
                const Divider(),
                Wrap(spacing: 8, children: [
                  const Text('Set all:', style: TextStyle(color: Colors.grey)),
                  for (final level in AdminLimits.levels)
                    ActionChip(
                      label: Text(AdminLimits.levelLabels[level]!),
                      onPressed: () => _setAll(level),
                    ),
                ]),
                const SizedBox(height: 8),
                for (final area in AdminLimits.areas) _areaRow(area),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            AdminLimits(restricted: _restricted, areaLevels: Map.of(_levels)),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          child: const Text('Save limits'),
        ),
      ],
    );
  }

  Widget _areaRow(String area) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AdminLimits.areaLabels[area]!, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(AdminLimits.areaHints[area]!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final level in AdminLimits.levels)
                  ButtonSegment(value: level, label: Text(AdminLimits.levelLabels[level]!)),
              ],
              selected: {_levels[area]!},
              onSelectionChanged: (s) => setState(() => _levels[area] = s.first),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Promote ──────────────────────────────────────────────────────────────

class PromoteAdminDialog extends StatefulWidget {
  final Function(String) onPromote;

  const PromoteAdminDialog({super.key, required this.onPromote});

  @override
  State<PromoteAdminDialog> createState() => _PromoteAdminDialogState();
}

class _PromoteAdminDialogState extends State<PromoteAdminDialog> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<User> _students = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchStudents(String query) async {
    if (query.isEmpty) {
      setState(() => _students = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _adminService.getStudents(search: query, source: 'firebase');
      if (!mounted) return;
      setState(() {
        _students = result.students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Promote Student to Admin'),
      content: SizedBox(
        width: _dialogWidth(context, 400),
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchStudents,
            ),
            const SizedBox(height: 10),
            const Text(
              'New admins get full access. Use "Set limits" afterwards to restrict them.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return ListTile(
                          title: Text(student.fullName),
                          subtitle: Text(student.email),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onPromote(student.id);
                            },
                            child: const Text('Promote'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
