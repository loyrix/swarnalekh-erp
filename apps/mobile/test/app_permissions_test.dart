import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';

void main() {
  test('maps owner and admin to PDF Admin permissions', () {
    expect(isAdminRole('owner'), isTrue);
    expect(isAdminRole('admin'), isTrue);
    expect(isAdminRole('OWNER'), isTrue);
  });

  test('keeps staff out of Admin-only permissions', () {
    expect(isAdminRole('staff'), isFalse);
    expect(isStaffRole('staff'), isTrue);
  });

  test('builds profile initials from shop names', () {
    expect(profileInitialsFromName('Kundan Jewellers'), 'KJ');
    expect(profileInitialsFromName('SwarnaLekh'), 'SW');
    expect(profileInitialsFromName(''), 'SL');
  });

  group('isRestrictedRoute', () {
    test('redirects staff away from every admin-only route', () {
      for (final route in kAdminOnlyRoutes) {
        expect(
          isRestrictedRoute('staff', route),
          isTrue,
          reason: 'staff must not access $route',
        );
      }
    });

    test('allows staff on shared routes', () {
      expect(isRestrictedRoute('staff', '/dashboard'), isFalse);
      expect(isRestrictedRoute('staff', '/inventory'), isFalse);
      expect(isRestrictedRoute('staff', '/billing'), isFalse);
      expect(isRestrictedRoute('staff', '/mortgage'), isFalse);
    });

    test('never restricts admins or owners', () {
      for (final route in kAdminOnlyRoutes) {
        expect(isRestrictedRoute('admin', route), isFalse);
        expect(isRestrictedRoute('owner', route), isFalse);
      }
    });

    test('treats unknown/null role as non-staff (not restricted here)', () {
      expect(isRestrictedRoute(null, '/reports'), isFalse);
    });
  });
}
