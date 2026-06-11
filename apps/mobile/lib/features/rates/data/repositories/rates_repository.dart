import 'package:swarnbook/core/network/api_client.dart';
import '../models/daily_rate.dart';

class RatesRepository {
  static final RatesRepository _instance = RatesRepository._internal();
  factory RatesRepository() => _instance;
  RatesRepository._internal();

  final ApiClient _api = ApiClient();

  Future<List<DailyRate>> getLatestRates() async {
    try {
      final response = await _api.dio.get('/daily-rates/latest');
      final data = response.data as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(DailyRate.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Failed to load latest rates: $e');
    }
  }

  Future<List<DailyRate>> getRatesByDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _api.dio.get(
        '/daily-rates',
        queryParameters: {'date': dateString},
      );

      final data = response.data as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(DailyRate.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Failed to load rates for date: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory({int days = 15}) async {
    try {
      final response = await _api.dio.get(
        '/daily-rates/history',
        queryParameters: {'days': days},
      );
      final data = response.data as List<dynamic>;
      return data.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('Failed to load rate history: $e');
    }
  }

  Future<List<DailyRate>> getYesterdayRates() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getRatesByDate(yesterday);
  }

  Future<void> bulkUpdateRates(List<Map<String, dynamic>> rates) async {
    try {
      await _api.dio.post('/daily-rates/bulk', data: {'rates': rates});
    } catch (e) {
      throw Exception('Failed to update rates: $e');
    }
  }
}
