import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/customers/data/customers_repository.dart';
import 'package:swarnbook/features/customers/data/models/customer.dart';

final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => CustomersRepository(),
);

final customersProvider = FutureProvider.autoDispose<List<Customer>>((ref) {
  return ref.watch(customersRepositoryProvider).getCustomers();
});
