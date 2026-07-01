import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/users/application/user_management_payloads.dart';

class UsersRepository {
  static final UsersRepository _instance = UsersRepository._internal();
  factory UsersRepository() => _instance;
  UsersRepository._internal();

  final ApiClient _api = ApiClient();

  Future<List<ManagedUser>> getUsers() async {
    final response = await _api.dio.get<List<dynamic>>('/users');
    return parseManagedUsers(response.data);
  }

  Future<void> save(Map<String, dynamic> payload, {String? id}) {
    if (id != null) {
      return _api.dio.put('/users/$id', data: payload);
    }
    return _api.dio.post('/users', data: payload);
  }

  Future<void> deactivate(String id) => _api.dio.delete('/users/$id');
}
