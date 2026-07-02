/// Typed results from the `GET /search` cross-entity endpoint.
class SearchResults {
  const SearchResults({
    required this.query,
    required this.customers,
    required this.inventory,
    required this.invoices,
    required this.total,
  });

  final String query;
  final List<CustomerHit> customers;
  final List<InventoryHit> inventory;
  final List<InvoiceHit> invoices;
  final int total;

  bool get isEmpty => total == 0;

  static const empty = SearchResults(
    query: '',
    customers: [],
    inventory: [],
    invoices: [],
    total: 0,
  );

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }

    final customers = parse('customers', CustomerHit.fromJson);
    final inventory = parse('inventory', InventoryHit.fromJson);
    final invoices = parse('invoices', InvoiceHit.fromJson);
    return SearchResults(
      query: json['query']?.toString() ?? '',
      customers: customers,
      inventory: inventory,
      invoices: invoices,
      total:
          (json['total'] as num?)?.toInt() ??
          customers.length + inventory.length + invoices.length,
    );
  }
}

class CustomerHit {
  const CustomerHit({
    required this.id,
    required this.name,
    this.phone,
    this.city,
  });

  final String id;
  final String name;
  final String? phone;
  final String? city;

  factory CustomerHit.fromJson(Map<String, dynamic> json) => CustomerHit(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    phone: _nullableString(json['phone']),
    city: _nullableString(json['city']),
  );
}

class InventoryHit {
  const InventoryHit({
    required this.id,
    required this.metalType,
    required this.status,
    this.tagNumber,
    this.itemName,
    this.category,
    this.sellingPrice,
  });

  final String id;
  final String metalType;
  final String status;
  final String? tagNumber;
  final String? itemName;
  final String? category;
  final double? sellingPrice;

  factory InventoryHit.fromJson(Map<String, dynamic> json) => InventoryHit(
    id: json['id']?.toString() ?? '',
    metalType: json['metalType']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    tagNumber: _nullableString(json['tagNumber']),
    itemName: _nullableString(json['itemName']),
    category: _nullableString(json['category']),
    sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
  );
}

class InvoiceHit {
  const InvoiceHit({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.grandTotal,
    required this.balanceDue,
    this.customerName,
  });

  final String id;
  final String invoiceNumber;
  final String invoiceDate;
  final double grandTotal;
  final double balanceDue;
  final String? customerName;

  factory InvoiceHit.fromJson(Map<String, dynamic> json) => InvoiceHit(
    id: json['id']?.toString() ?? '',
    invoiceNumber: json['invoiceNumber']?.toString() ?? '',
    invoiceDate: json['invoiceDate']?.toString() ?? '',
    grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
    balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0,
    customerName: _nullableString(json['customerName']),
  );
}

String? _nullableString(dynamic value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
