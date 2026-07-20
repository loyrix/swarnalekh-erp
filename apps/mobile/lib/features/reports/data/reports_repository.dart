import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/reports/data/models/reports_data.dart';

/// Immutable filter set for reports (value equality keys the provider family).
class ReportsQuery {
  const ReportsQuery({
    this.search = '',
    this.dateFrom = '',
    this.dateTo = '',
    this.category = '',
    this.branch = '',
    this.status = 'all',
  });

  final String search;
  final String dateFrom;
  final String dateTo;
  final String category;
  final String branch;
  final String status;

  ReportsQuery copyWith({
    String? search,
    String? dateFrom,
    String? dateTo,
    String? category,
    String? branch,
    String? status,
  }) {
    return ReportsQuery(
      search: search ?? this.search,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      category: category ?? this.category,
      branch: branch ?? this.branch,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic>? toQueryParameters() {
    final params = <String, dynamic>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (dateFrom.trim().isNotEmpty) 'dateFrom': dateFrom.trim(),
      if (dateTo.trim().isNotEmpty) 'dateTo': dateTo.trim(),
      if (category.trim().isNotEmpty) 'categoryName': category.trim(),
      if (branch.trim().isNotEmpty) 'branch': branch.trim(),
      if (status != 'all') 'status': status,
    };
    return params.isEmpty ? null : params;
  }

  @override
  bool operator ==(Object other) =>
      other is ReportsQuery &&
      other.search == search &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.category == category &&
      other.branch == branch &&
      other.status == status;

  @override
  int get hashCode =>
      Object.hash(search, dateFrom, dateTo, category, branch, status);
}

class ReportsRepository {
  static final ReportsRepository _instance = ReportsRepository._internal();
  factory ReportsRepository() => _instance;
  ReportsRepository._internal();

  final ApiClient _api = ApiClient();

  Future<ReportsData> getOverview(ReportsQuery query) async {
    final response = await _api.dio.get(
      '/reports/overview',
      queryParameters: query.toQueryParameters(),
    );
    final payload = response.data as Map<String, dynamic>? ?? const {};
    return ReportsData.fromJson(payload);
  }
}
