import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/users/application/user_management_payloads.dart';

void main() {
  test('parses managed users from API payload', () {
    final users = parseManagedUsers([
      {
        'id': 'user-1',
        'name': 'Asha',
        'email': 'asha@example.com',
        'role': 'admin',
        'isActive': true,
        'authLinked': true,
        'createdAt': '2026-06-10T00:00:00.000Z',
      },
      'invalid',
    ]);

    expect(users, hasLength(1));
    expect(users.first.id, 'user-1');
    expect(users.first.role, 'admin');
    expect(users.first.isActive, isTrue);
    expect(users.first.authLinked, isTrue);
    expect(users.first.createdAt, isNotNull);
  });

  test('builds normalized managed user payloads', () {
    expect(
      managedUserPayload(
        name: ' Asha ',
        email: ' ASHA@EXAMPLE.COM ',
        phone: ' ',
        role: 'staff',
        isActive: true,
      ),
      {
        'name': 'Asha',
        'email': 'asha@example.com',
        'phone': null,
        'role': 'staff',
        'isActive': true,
      },
    );
  });

  test('returns empty list for invalid managed users payload', () {
    expect(parseManagedUsers({'users': []}), isEmpty);
  });
}
