/// A super admin account and the limits on what it may do in the dashboard.
///
/// Limits are per area: `full` (view and change), `view` (read only) or
/// `none`. An admin that is not [AdminLimits.restricted] has full access.
class AdminLimits {
  static const areas = <String>[
    'users',
    'courses',
    'schools',
    'payments',
    'communication',
    'settings',
    'admins',
  ];

  static const levels = <String>['full', 'view', 'none'];

  static const areaLabels = <String, String>{
    'users': 'Students & teachers',
    'courses': 'Courses & content',
    'schools': 'Schools',
    'payments': 'Payments',
    'communication': 'Notifications & feedback',
    'settings': 'Platform settings',
    'admins': 'Other admins',
  };

  static const areaHints = <String, String>{
    'users': 'Students, teachers, teacher approvals, enrolments',
    'courses': "Courses, library, live sessions, exams, teacher's guides",
    'schools': 'Schools and the courses offered to them',
    'payments': 'Payments, approvals and payment stats',
    'communication': 'Push notifications, push report, user feedback',
    'settings': 'Settings, backups, maintenance',
    'admins': 'Edit admins, their passwords and limits. Full access here lets them undo any limit.',
  };

  static const levelLabels = <String, String>{
    'full': 'Full',
    'view': 'View only',
    'none': 'No access',
  };

  final bool restricted;
  final Map<String, String> areaLevels;

  const AdminLimits({required this.restricted, required this.areaLevels});

  static const unrestricted = AdminLimits(restricted: false, areaLevels: {});

  factory AdminLimits.fromJson(Object? json) {
    if (json is! Map) return unrestricted;
    final restricted = json['restricted'] == true;
    final raw = json['areas'];
    final map = <String, String>{};
    for (final area in areas) {
      final v = raw is Map ? raw[area] : null;
      map[area] = levels.contains(v) ? v as String : (restricted ? 'none' : 'full');
    }
    return AdminLimits(restricted: restricted, areaLevels: map);
  }

  Map<String, dynamic> toJson() => {
        'restricted': restricted,
        'areas': {for (final a in areas) a: level(a)},
      };

  String level(String area) => restricted ? (areaLevels[area] ?? 'none') : 'full';

  bool canView(String area) => level(area) != 'none';
  bool canChange(String area) => level(area) == 'full';

  /// Short summary for a list row, e.g. "Limited: 3 full, 2 view only".
  String get summary {
    if (!restricted) return 'Full access';
    final full = areas.where((a) => level(a) == 'full').length;
    final view = areas.where((a) => level(a) == 'view').length;
    final parts = <String>[
      if (full > 0) '$full full',
      if (view > 0) '$view view only',
    ];
    return parts.isEmpty ? 'Limited: no access' : 'Limited: ${parts.join(', ')}';
  }
}

class AdminAccount {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final bool disabled;
  final DateTime? lastActive;
  final AdminLimits limits;

  const AdminAccount({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.disabled,
    this.lastActive,
    required this.limits,
  });

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    final last = json['lastActive'];
    return AdminAccount(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: (json['fullName'] as String?)?.trim().isNotEmpty == true ? json['fullName'] as String : 'Unnamed admin',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      disabled: json['disabled'] == true || json['isActive'] == false,
      lastActive: last is String ? DateTime.tryParse(last) : null,
      limits: AdminLimits.fromJson(json['adminLimits']),
    );
  }
}
