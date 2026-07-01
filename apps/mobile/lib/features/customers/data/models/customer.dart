/// Typed customer from `GET /customers`.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    required this.preferredKarat,
    required this.notes,
    required this.totalPurchases,
    required this.totalVisits,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? city;
  final String? preferredKarat;
  final String? notes;
  final double totalPurchases;
  final int totalVisits;

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: _str(json['phone']),
      email: _str(json['email']),
      city: _str(json['city']),
      preferredKarat: _str(json['preferredKarat']),
      notes: _str(json['notes']),
      totalPurchases: _num(json['totalPurchases']),
      totalVisits: _num(json['totalVisits']).round(),
    );
  }

  bool matches(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        (phone ?? '').toLowerCase().contains(q);
  }
}
