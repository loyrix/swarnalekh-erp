import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';

/// Immutable filter set for the inventory overview query. Value equality lets
/// it key a Riverpod `family` so identical queries share a cache entry.
class InventoryQuery {
  const InventoryQuery({
    this.status = 'in_stock',
    this.metal = 'all',
    this.search = '',
    this.category = '',
    this.branch = '',
  });

  final String status;
  final String metal;
  final String search;
  final String category;
  final String branch;

  InventoryQuery copyWith({
    String? status,
    String? metal,
    String? search,
    String? category,
    String? branch,
  }) {
    return InventoryQuery(
      status: status ?? this.status,
      metal: metal ?? this.metal,
      search: search ?? this.search,
      category: category ?? this.category,
      branch: branch ?? this.branch,
    );
  }

  Map<String, dynamic> toQueryParameters() => {
    'status': status,
    if (metal != 'all') 'metalType': metal,
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (category.trim().isNotEmpty) 'categoryName': category.trim(),
    if (branch.trim().isNotEmpty) 'location': branch.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is InventoryQuery &&
      other.status == status &&
      other.metal == metal &&
      other.search == search &&
      other.category == category &&
      other.branch == branch;

  @override
  int get hashCode => Object.hash(status, metal, search, category, branch);
}

class InventoryRepository {
  static final InventoryRepository _instance = InventoryRepository._internal();
  factory InventoryRepository() => _instance;
  InventoryRepository._internal();

  final ApiClient _api = ApiClient();

  Future<InventoryOverview> getOverview(InventoryQuery query) async {
    final response = await _api.dio.get(
      '/inventory/overview',
      queryParameters: query.toQueryParameters(),
    );
    final payload = response.data as Map<String, dynamic>? ?? const {};
    return InventoryOverview.fromJson(payload);
  }

  Future<List<SoldProduct>> getSoldProducts(String search) async {
    final response = await _api.dio.get(
      '/inventory/sold-products',
      queryParameters: {if (search.trim().isNotEmpty) 'search': search.trim()},
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SoldProduct.fromJson)
        .toList();
  }

  Future<void> delete(String id) => _api.dio.delete('/inventory/$id');
}
