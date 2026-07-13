import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';

class CategoriesRepository {
  static final CategoriesRepository _instance =
      CategoriesRepository._internal();
  factory CategoriesRepository() => _instance;
  CategoriesRepository._internal();

  final ApiClient _api = ApiClient();

  Future<List<ShopCategory>> getCategories() async {
    final response = await _api.dio.get<List<dynamic>>('/categories');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ShopCategory.fromJson)
        .toList();
  }

  Future<void> save(Map<String, dynamic> payload, {String? id}) {
    if (id != null) {
      return _api.dio.patch('/categories/$id', data: payload);
    }
    return _api.dio.post('/categories', data: payload);
  }

  Future<void> delete(String id) => _api.dio.delete('/categories/$id');
}
