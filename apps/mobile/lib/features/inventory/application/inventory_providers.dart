import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/inventory/data/inventory_repository.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/shared/application/stat_period.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(),
);

/// Stat strip keyed by the "sold" period (default: this month). Period-neutral
/// figures (weights, total) are unaffected; only the sold count changes.
final inventoryStatsProvider = FutureProvider.autoDispose
    .family<InventoryStats, StatPeriod>((ref, period) {
      return ref
          .watch(inventoryRepositoryProvider)
          .getStats(query: period.toQueryParameters());
    });

/// Inventory overview for a given filter set. Change the [InventoryQuery] to
/// refetch; call `ref.invalidate` after a mutation to refresh the current one.
final inventoryOverviewProvider = FutureProvider.autoDispose
    .family<InventoryOverview, InventoryQuery>((ref, query) {
      return ref.watch(inventoryRepositoryProvider).getOverview(query);
    });

/// Sold products list, filtered by a free-text [search].
final soldProductsProvider = FutureProvider.autoDispose
    .family<List<SoldProduct>, String>((ref, search) {
      return ref.watch(inventoryRepositoryProvider).getSoldProducts(search);
    });
