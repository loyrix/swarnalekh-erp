import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/shared/application/stat_period.dart';

final mortgageRepositoryProvider = Provider<MortgageRepository>(
  (ref) => MortgageRepository(),
);

/// Dashboard keyed by the collections period (default: today).
final mortgageDashboardProvider = FutureProvider.autoDispose
    .family<MortgageDashboard, StatPeriod>((ref, period) {
      return ref
          .watch(mortgageRepositoryProvider)
          .getDashboard(query: period.toQueryParameters());
    });

final mortgageLoansProvider = FutureProvider.autoDispose
    .family<List<MortgageLoan>, MortgageQuery>((ref, query) {
      return ref.watch(mortgageRepositoryProvider).getLoans(query);
    });
