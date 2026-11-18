import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/teacher_access_service.dart';
import 'auth_provider.dart';

final teacherAccessServiceProvider = Provider<TeacherAccessService>((ref) => TeacherAccessService());

/// The signed-in teacher's access state (profile → approval → course → tools).
/// Re-fetched when the user changes; call `ref.invalidate(teacherAccessProvider)`
/// after anything that can change it (profile submitted, request approved…).
final teacherAccessProvider = FutureProvider<TeacherAccessStatus>((ref) async {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  if (userId == null) throw TeacherAccessException('Please sign in again.');
  return ref.read(teacherAccessServiceProvider).status();
});
