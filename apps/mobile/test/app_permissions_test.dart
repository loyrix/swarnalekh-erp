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
}
