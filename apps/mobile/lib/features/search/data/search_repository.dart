import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/search/data/models/search_results.dart';

class SearchRepository {
  static final SearchRepository _instance = SearchRepository._internal();
  factory SearchRepository() => _instance;
  SearchRepository._internal();

  final ApiClient _api = ApiClient();

  Future<SearchResults> search(String query, {int? limit}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return SearchResults.empty;

    final response = await _api.dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {'q': trimmed, if (limit != null) 'limit': limit},
    );
    return SearchResults.fromJson(response.data ?? const {});
  }
}
