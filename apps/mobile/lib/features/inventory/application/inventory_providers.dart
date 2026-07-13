import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/inventory/data/inventory_repository.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(),
);

/// Inventory overview for a given filter set. Change the [InventoryQuery] to
/// refetch; call `ref.invalidate` after a mutation to refresh the current one.
final inventoryOverviewProvider = FutureProvider.autoDispose
    .family<InventoryOverview, InventoryQuery>((ref, query) {
      return ref.watch(inventoryRepositoryProvider).getOverview(query);
    });

/// Sold products list, filtered by search + sold-date period.
final soldProductsProvider = FutureProvider.autoDispose
    .family<List<SoldProduct>, SoldQuery>((ref, query) {
      return ref.watch(inventoryRepositoryProvider).getSoldProducts(query);
    });
