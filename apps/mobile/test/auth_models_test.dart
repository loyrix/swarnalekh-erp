import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/auth/data/auth_repository.dart';
import 'package:swarnbook/features/auth/data/models/auth_session.dart';
import 'package:swarnbook/features/auth/data/models/auth_user.dart';

void main() {
  group('AuthUser.fromJson', () {
    test('reads profile and flattens tenant fields', () {
      final user = AuthUser.fromJson({
        'id': 'u1',
        'tenantId': 't1',
        'name': 'Owner',
        'email': 'o@x.com',
        'phone': null,
        'role': 'owner',
        'tenant': {
          'id': 't1',
          'shopName': 'Krishna Jewellers',
          'subscriptionPlan': 'free',
        },
      });
      expect(user.id, 'u1');
      expect(user.role, 'owner');
      expect(user.shopName, 'Krishna Jewellers');
      expect(user.subscriptionPlan, 'free');
      expect(user.phone, isNull);
    });

    test('falls back to tenant id and safe defaults', () {
      final user = AuthUser.fromJson({
        'id': 'u2',
        'tenant': {'id': 't9'},
      });
      expect(user.tenantId, 't9');
      expect(user.role, 'staff');
      expect(user.shopName, isNull);
    });
  });

  group('AuthSession.fromJson', () {
    test('parses token, expiry and nested user', () {
      final session = AuthSession.fromJson({
        'accessToken': 'a.b.c',
        'expiresAt': 1893456000,
        'tokenType': 'Bearer',
        'user': {'id': 'u1', 'name': 'Owner', 'role': 'owner'},
      });
      expect(session.accessToken, 'a.b.c');
      expect(session.expiresAt, 1893456000);
      expect(session.user.id, 'u1');
    });
  });

  group('RegisterRequest.toJson', () {
    test('trims required fields and omits empty optionals', () {
      final json = RegisterRequest(
        shopName: '  Shop ',
        ownerName: ' Owner ',
        email: '  O@x.com ',
        password: 'password1',
        phone: '  ',
      ).toJson();
      expect(json['shopName'], 'Shop');
      expect(json['ownerName'], 'Owner');
      expect(json['email'], 'O@x.com');
      expect(json['password'], 'password1');
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('city'), isFalse);
    });

    test('includes provided optionals', () {
      final json = RegisterRequest(
        shopName: 'S',
        ownerName: 'O',
        email: 'o@x.com',
        password: 'password1',
        city: 'Pune',
        gstin: '27AAAAA0000Z1Z5',
      ).toJson();
      expect(json['city'], 'Pune');
      expect(json['gstin'], '27AAAAA0000Z1Z5');
    });
  });
}
