import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/tenant/data/models/tenant_profile.dart';

void main() {
  test('TenantProfile reads shop logo from API json', () {
    final profile = TenantProfile.fromJson({
      'id': 'tenant-1',
      'shopName': 'SwarnaLekh Jewellers',
      'ownerName': 'Owner',
      'logoUrl': 'data:image/jpeg;base64,AQID',
      'subscriptionPlan': 'free',
      'users': const [],
    });

    expect(profile.logoUrl, 'data:image/jpeg;base64,AQID');
  });
}
