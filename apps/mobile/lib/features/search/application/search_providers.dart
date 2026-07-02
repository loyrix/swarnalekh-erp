import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/search/data/models/search_results.dart';
import 'package:swarnbook/features/search/data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(),
);

/// Cross-entity search results for a trimmed query. Blank query short-circuits
/// to an empty result without a network call.
final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, String>((ref, query) {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return Future.value(SearchResults.empty);
      return ref.watch(searchRepositoryProvider).search(trimmed);
    });
