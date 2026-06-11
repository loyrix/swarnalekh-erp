class ManagedUser {
  final String id;
  final String name;
  final String role;
  final String? email;
  final String? phone;
  final bool isActive;
  final bool authLinked;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  const ManagedUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    required this.isActive,
    required this.authLinked,
    this.lastLoginAt,
    this.createdAt,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'staff',
      email: _optionalString(json['email']),
      phone: _optionalString(json['phone']),
      isActive: json['isActive'] != false,
      authLinked: json['authLinked'] == true,
      lastLoginAt: DateTime.tryParse(json['lastLoginAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  bool get isOwner => role.trim().toLowerCase() == 'owner';
}

List<ManagedUser> parseManagedUsers(Object? payload) {
  if (payload is! List) return const [];
  return payload
      .whereType<Map>()
      .map((entry) => ManagedUser.fromJson(Map<String, dynamic>.from(entry)))
      .toList(growable: false);
}

Map<String, dynamic> managedUserPayload({
  required String name,
  required String email,
  required String role,
  String? phone,
  bool? isActive,
}) {
  return {
    'name': name.trim(),
    'email': email.trim().toLowerCase(),
    'phone': phone == null || phone.trim().isEmpty ? null : phone.trim(),
    'role': role,
    if (isActive != null) 'isActive': isActive,
  };
}

String? _optionalString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
