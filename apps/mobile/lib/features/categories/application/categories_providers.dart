import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/categories/data/categories_repository.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(),
);

/// All categories for the shop (server seeds the default master list on
/// first read). Used by the settings screen and the inventory dropdowns.
final categoriesProvider = FutureProvider.autoDispose<List<ShopCategory>>((
  ref,
) {
  return ref.watch(categoriesRepositoryProvider).getCategories();
});
