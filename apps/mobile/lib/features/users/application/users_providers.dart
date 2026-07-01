import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/features/users/application/user_management_payloads.dart';
import 'package:swarnbook/features/users/data/users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(),
);

final usersProvider = FutureProvider.autoDispose<List<ManagedUser>>((ref) {
  return ref.watch(usersRepositoryProvider).getUsers();
});
