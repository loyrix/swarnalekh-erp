class TenantProfileUpdateInput {
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

  const TenantProfileUpdateInput({
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
  });

  Map<String, dynamic> toJson() {
    return {
      'shopName': shopName.trim(),
      'ownerName': ownerName.trim(),
      'email': _nullableTrim(email),
      'phone': _nullableTrim(phone),
      'address': _nullableTrim(address),
      'city': _nullableTrim(city),
      'state': _nullableTrim(state),
      'pincode': _nullableTrim(pincode),
      'gstin': _nullableTrim(gstin),
      'pan': _nullableTrim(pan),
      'logoUrl': _nullableTrim(logoUrl),
    };
  }
}

String? _nullableTrim(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
