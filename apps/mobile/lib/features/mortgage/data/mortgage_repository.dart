import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/mortgage/application/mortgage_receipt_payloads.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';

/// Immutable filter for the loan list (value equality keys the provider family).
class MortgageQuery {
  const MortgageQuery({this.status = 'active', this.search = ''});

  final String status;
  final String search;

  MortgageQuery copyWith({String? status, String? search}) => MortgageQuery(
    status: status ?? this.status,
    search: search ?? this.search,
  );

  Map<String, dynamic> toQueryParameters() => {
    if (status != 'all') 'status': status,
    if (search.trim().isNotEmpty) 'search': search.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is MortgageQuery &&
      other.status == status &&
      other.search == search;

  @override
  int get hashCode => Object.hash(status, search);
}

class MortgageRepository {
  static final MortgageRepository _instance = MortgageRepository._internal();
  factory MortgageRepository() => _instance;
  MortgageRepository._internal();

  final ApiClient _api = ApiClient();

  Future<MortgageDashboard> getDashboard({Map<String, dynamic>? query}) async {
    final response = await _api.dio.get(
      '/mortgages/dashboard',
      queryParameters: query,
    );
    final payload = response.data as Map<String, dynamic>? ?? const {};
    return MortgageDashboard.fromJson(payload);
  }

  Future<List<MortgageLoan>> getLoans(MortgageQuery query) async {
    final response = await _api.dio.get(
      '/mortgages',
      queryParameters: query.toQueryParameters(),
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MortgageLoan.fromJson)
        .toList();
  }

  Future<void> createLoan(Map<String, dynamic> payload) =>
      _api.dio.post('/mortgages', data: payload);

  /// Correct a recorded payment's amount/type (admin only).
  Future<void> updatePayment(
    String loanId,
    String paymentId,
    Map<String, dynamic> payload,
  ) => _api.dio.patch('/mortgages/$loanId/payments/$paymentId', data: payload);

  Future<void> collectPayment(String loanId, Map<String, dynamic> payload) =>
      _api.dio.post('/mortgages/$loanId/payments', data: payload);

  Future<void> closeLoan(String loanId, Map<String, dynamic> payload) =>
      _api.dio.post('/mortgages/$loanId/close', data: payload);

  /// Reopen a closed loan so Collect/Close entries can be corrected (admin).
  Future<void> reopenLoan(String loanId, {String? notes}) => _api.dio.post(
    '/mortgages/$loanId/reopen',
    data: {if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim()},
  );

  Future<MortgageReceiptPdfPayload> getReceipt(
    String loanId,
    String paymentId,
  ) async {
    final response = await _api.dio.get(
      '/mortgages/$loanId/payments/$paymentId/receipt',
    );
    return decodeMortgageReceiptPdfPayload(
      Map<String, dynamic>.from(response.data as Map),
      fallbackFileName: 'mortgage-receipt-$paymentId.pdf',
    );
  }
}
