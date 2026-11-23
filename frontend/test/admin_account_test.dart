import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/models/admin_account.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_access_provider.dart';

void main() {
  test('an admin without limits has full access everywhere', () {
    final limits = AdminLimits.fromJson(null);
    expect(limits.restricted, isFalse);
    expect(limits.summary, 'Full access');
    for (final area in AdminLimits.areas) {
      expect(limits.canChange(area), isTrue);
    }
  });

  test('restricted limits parse, default unknown areas to none, and round-trip', () {
    final limits = AdminLimits.fromJson({
      'restricted': true,
      'areas': {'users': 'full', 'payments': 'view', 'courses': 'bogus'},
    });
    expect(limits.level('users'), 'full');
    expect(limits.level('payments'), 'view');
    expect(limits.level('courses'), 'none');
    expect(limits.level('admins'), 'none');
    expect(limits.canView('payments'), isTrue);
    expect(limits.canChange('payments'), isFalse);
    expect(limits.summary, 'Limited: 1 full, 1 view only');
    expect(AdminLimits.fromJson(limits.toJson()).toJson(), limits.toJson());
  });

  test('dashboard links are hidden only for areas with no access', () {
    final limits = AdminLimits.fromJson({
      'restricted': true,
      'areas': {'users': 'view'},
    });
    expect(adminCanOpenRoute(limits, '/admin/students'), isTrue);
    expect(adminCanOpenRoute(limits, '/admin/payments'), isFalse);
    expect(adminCanOpenRoute(limits, '/admin/admins'), isFalse);
    expect(adminCanOpenRoute(limits, '/admin/analytics'), isTrue); // not an area
    expect(adminCanOpenRoute(AdminLimits.unrestricted, '/admin/payments'), isTrue);
  });

  test('admin accounts parse from the server list', () {
    final a = AdminAccount.fromJson({
      'id': 'abc',
      'fullName': 'Alice',
      'email': 'alice@ech.rw',
      'disabled': true,
      'adminLimits': {'restricted': false, 'areas': {}},
    });
    expect(a.id, 'abc');
    expect(a.disabled, isTrue);
    expect(a.limits.restricted, isFalse);
  });
}
