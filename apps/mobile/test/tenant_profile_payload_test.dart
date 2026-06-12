import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/tenant/application/tenant_profile_payload.dart';

void main() {
  group('TenantProfileUpdateInput', () {
    test('serializes exactly the backend-supported shop profile fields', () {
      final payload = const TenantProfileUpdateInput(
        shopName: '  Kundan Jewellers  ',
        ownerName: '  Asha Shah  ',
        email: '  owner@example.com  ',
        phone: '  +919876543210  ',
        address: '  Main Road  ',
        city: '  Mumbai  ',
        state: '  Maharashtra  ',
        pincode: '  400001  ',
        gstin: '  27AAAAA0000Z1Z5  ',
        pan: '  AAAAA0000Z  ',
        logoUrl: '  data:image/jpeg;base64,AQID  ',
      ).toJson();

      expect(payload.keys, {
        'shopName',
        'ownerName',
        'email',
        'phone',
        'address',
        'city',
        'state',
        'pincode',
        'gstin',
        'pan',
        'logoUrl',
      });
      expect(payload, {
        'shopName': 'Kundan Jewellers',
        'ownerName': 'Asha Shah',
        'email': 'owner@example.com',
        'phone': '+919876543210',
        'address': 'Main Road',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'pincode': '400001',
        'gstin': '27AAAAA0000Z1Z5',
        'pan': 'AAAAA0000Z',
        'logoUrl': 'data:image/jpeg;base64,AQID',
      });
    });

    test('sends empty optional fields as null', () {
      final payload = const TenantProfileUpdateInput(
        shopName: 'SwarnaLekh',
        ownerName: 'Owner',
        phone: '   ',
      ).toJson();

      expect(payload['shopName'], 'SwarnaLekh');
      expect(payload['ownerName'], 'Owner');
      expect(payload['phone'], isNull);
      expect(payload['email'], isNull);
      expect(payload['logoUrl'], isNull);
    });
  });
}
