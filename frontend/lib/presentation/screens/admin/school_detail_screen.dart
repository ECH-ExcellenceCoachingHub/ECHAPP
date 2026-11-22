import 'package:flutter/material.dart';

import '../school_admin/school_admin_dashboard_screen.dart';

/// Super admin view of one school: the same dashboard the school's head
/// teacher uses, plus billing controls (record payments, prices).
class SchoolDetailScreen extends StatelessWidget {
  const SchoolDetailScreen({super.key, required this.schoolId});
  final String schoolId;

  @override
  Widget build(BuildContext context) => SchoolAdminDashboardScreen(schoolId: schoolId);
}
