import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/shared/application/stat_period.dart';

/// Immutable filter set for the inventory overview query. Value equality lets
/// it key a Riverpod `family` so identical queries share a cache entry.
class InventoryQuery {
  const InventoryQuery({
    this.status = 'in_stock',
    this.metal = 'all',
    this.search = '',
    this.categoryId = '',
    this.branch = '',
    this.dateFrom = '',
    this.dateTo = '',
  });

  final String status;
  final String metal;
  final String search;
  final String categoryId;
  final String branch;

  /// Created-date window (ISO yyyy-MM-dd); empty = all time.
  final String dateFrom;
  final String dateTo;

  InventoryQuery copyWith({
    String? status,
    String? metal,
    String? search,
    String? categoryId,
    String? branch,
    String? dateFrom,
    String? dateTo,
  }) {
    return InventoryQuery(
      status: status ?? this.status,
      metal: metal ?? this.metal,
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      branch: branch ?? this.branch,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }

  Map<String, dynamic> toQueryParameters() => {
    'status': status,
    if (metal != 'all') 'metalType': metal,
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (categoryId.isNotEmpty) 'categoryId': categoryId,
    if (branch.trim().isNotEmpty) 'location': branch.trim(),
    if (dateFrom.isNotEmpty) 'dateFrom': dateFrom,
    if (dateTo.isNotEmpty) 'dateTo': dateTo,
  };

  @override
  bool operator ==(Object other) =>
      other is InventoryQuery &&
      other.status == status &&
      other.metal == metal &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.branch == branch &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo;

  @override
  int get hashCode =>
      Object.hash(status, metal, search, categoryId, branch, dateFrom, dateTo);
}

/// Query for the sold-products list: free-text search + sold-date period.
class SoldQuery {
  const SoldQuery({this.search = '', this.period = StatPeriod.month});

  final String search;
  final StatPeriod period;

  SoldQuery copyWith({String? search, StatPeriod? period}) =>
      SoldQuery(search: search ?? this.search, period: period ?? this.period);

  Map<String, dynamic> toQueryParameters() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    ...period.toQueryParameters(),
  };

  @override
  bool operator ==(Object other) =>
      other is SoldQuery && other.search == search && other.period == period;

  @override
  int get hashCode => Object.hash(search, period);
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

  Future<List<SoldProduct>> getSoldProducts(SoldQuery query) async {
    final response = await _api.dio.get(
      '/inventory/sold-products',
      queryParameters: query.toQueryParameters(),
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SoldProduct.fromJson)
        .toList();
  }

  Future<void> delete(String id) => _api.dio.delete('/inventory/$id');
}
