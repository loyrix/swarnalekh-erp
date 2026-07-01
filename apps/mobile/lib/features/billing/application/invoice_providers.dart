import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/billing/data/invoice_repository.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => InvoiceRepository(),
);

final billingDashboardProvider = FutureProvider.autoDispose<BillingDashboard>((
  ref,
) {
  return ref.watch(invoiceRepositoryProvider).getDashboard();
});

final invoicesProvider = FutureProvider.autoDispose
    .family<List<Invoice>, InvoiceQuery>((ref, query) {
      return ref.watch(invoiceRepositoryProvider).getInvoices(query);
    });
