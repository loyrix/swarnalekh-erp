import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/customers/data/models/customer.dart';

class CustomersRepository {
  static final CustomersRepository _instance = CustomersRepository._internal();
  factory CustomersRepository() => _instance;
  CustomersRepository._internal();

  final ApiClient _api = ApiClient();

  Future<List<Customer>> getCustomers() async {
    final response = await _api.dio.get('/customers');
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Customer.fromJson)
        .toList();
  }

  Future<void> save(Map<String, dynamic> payload, {String? id}) {
    if (id != null) {
      return _api.dio.put('/customers/$id', data: payload);
    }
    return _api.dio.post('/customers', data: payload);
  }
}
