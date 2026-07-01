import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';

final mortgageRepositoryProvider = Provider<MortgageRepository>(
  (ref) => MortgageRepository(),
);

final mortgageDashboardProvider = FutureProvider.autoDispose<MortgageDashboard>(
  (ref) {
    return ref.watch(mortgageRepositoryProvider).getDashboard();
  },
);

final mortgageLoansProvider = FutureProvider.autoDispose
    .family<List<MortgageLoan>, MortgageQuery>((ref, query) {
      return ref.watch(mortgageRepositoryProvider).getLoans(query);
    });
