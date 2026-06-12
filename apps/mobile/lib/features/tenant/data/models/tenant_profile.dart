class TenantUserSummary {
  final String id;
  final String name;
  final String role;
  final String? phone;
  final String? email;

  TenantUserSummary({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
    this.email,
  });

  factory TenantUserSummary.fromJson(Map<String, dynamic> json) {
    return TenantUserSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'staff',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class TenantProfile {
  final String id;
  final String shopName;
  final String ownerName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gstin;
  final String? pan;
  final String? logoUrl;
  final String subscriptionPlan;
  final List<TenantUserSummary> users;

  TenantProfile({
    required this.id,
    required this.shopName,
    required this.ownerName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.gstin,
    this.pan,
    this.logoUrl,
    required this.subscriptionPlan,
    required this.users,
  });

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    final usersJson = (json['users'] as List?) ?? const [];
    return TenantProfile(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      gstin: json['gstin']?.toString(),
      pan: json['pan']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      subscriptionPlan: json['subscriptionPlan']?.toString() ?? 'free',
      users: usersJson
          .whereType<Map<String, dynamic>>()
          .map(TenantUserSummary.fromJson)
          .toList(),
    );
  }
}
