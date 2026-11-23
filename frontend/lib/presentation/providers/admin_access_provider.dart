import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_account.dart';
import '../../services/api/admin_accounts_service.dart';
import 'auth_provider.dart';

/// The signed-in super admin's own limits. Falls back to full access when it
/// cannot be loaded: the server enforces limits regardless, this only decides
/// which dashboard areas are shown.
final myAdminAccessProvider = FutureProvider.autoDispose<AdminLimits>((ref) async {
  final user = ref.watch(authProvider.select((s) => s.user));
  if (user == null || user.role != 'admin') return AdminLimits.unrestricted;
  try {
    return await AdminAccountsService().myAccess();
  } catch (_) {
    return AdminLimits.unrestricted;
  }
});

/// Which limits area a dashboard route belongs to (null = always shown).
String? adminAreaForRoute(String route) {
  const map = <String, String>{
    '/admin/students': 'users',
    '/admin/teachers': 'users',
    '/admin/teacher-approvals': 'users',
    '/admin/courses': 'courses',
    '/admin/books': 'courses',
    '/admin/teacher-guides': 'courses',
    '/admin/live-sessions': 'courses',
    '/admin/exams-review': 'courses',
    '/admin/recordings': 'courses',
    '/admin/schools': 'schools',
    '/admin/payments': 'payments',
    '/admin/notifications': 'communication',
    '/admin/push-report': 'communication',
    '/admin/user-feedback': 'communication',
    '/admin/settings': 'settings',
    '/admin/admins': 'admins',
  };
  for (final entry in map.entries) {
    if (route == entry.key || route.startsWith('${entry.key}/')) return entry.value;
  }
  return null;
}

/// Whether a dashboard link should be shown to an admin with [access].
bool adminCanOpenRoute(AdminLimits access, String? route) {
  if (route == null) return true;
  final area = adminAreaForRoute(route);
  return area == null || access.canView(area);
}
