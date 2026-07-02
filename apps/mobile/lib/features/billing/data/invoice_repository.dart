import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/billing/application/invoice_action_payloads.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';

/// Immutable filter for the invoice history list. Value equality keys the
/// Riverpod provider family so identical queries share one request.
class InvoiceQuery {
  const InvoiceQuery({this.search = '', this.dateFrom, this.dateTo});

  final String search;
  final String? dateFrom;
  final String? dateTo;

  InvoiceQuery copyWith({String? search, String? dateFrom, String? dateTo}) {
    return InvoiceQuery(
      search: search ?? this.search,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }

  Map<String, dynamic>? toQueryParameters() {
    final params = <String, dynamic>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (dateFrom != null && dateFrom!.trim().isNotEmpty)
        'dateFrom': dateFrom!.trim(),
      if (dateTo != null && dateTo!.trim().isNotEmpty) 'dateTo': dateTo!.trim(),
    };
    return params.isEmpty ? null : params;
  }

  @override
  bool operator ==(Object other) =>
      other is InvoiceQuery &&
      other.search == search &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo;

  @override
  int get hashCode => Object.hash(search, dateFrom, dateTo);
}

/// A single selected line in the New Bill form.
class InvoiceDraftItem {
  const InvoiceDraftItem({
    required this.inventoryItemId,
    required this.quantity,
  });

  final String inventoryItemId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'inventoryItemId': inventoryItemId,
    'quantity': quantity,
  };
}

/// The full New Bill payload, shared verbatim by preview and create so the
/// previewed total is exactly what gets charged.
class InvoiceDraft {
  const InvoiceDraft({
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.items,
    this.discountAmount = 0,
    this.amountPaid = 0,
    this.paymentMode = 'cash',
    this.notes,
  });

  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final List<InvoiceDraftItem> items;
  final double discountAmount;
  final double amountPaid;
  final String paymentMode;
  final String? notes;

  Map<String, dynamic> toJson({String? idempotencyKey}) {
    return {
      if (customerId != null) 'customerId': customerId,
      if (customerId == null && customerName != null)
        'customerName': customerName,
      if (customerId == null &&
          customerPhone != null &&
          customerPhone!.isNotEmpty)
        'customerPhone': customerPhone,
      'items': items.map((i) => i.toJson()).toList(),
      'discountAmount': discountAmount,
      'amountPaid': amountPaid,
      'paymentMode': paymentMode,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    };
  }
}

class InvoiceRepository {
  static final InvoiceRepository _instance = InvoiceRepository._internal();
  factory InvoiceRepository() => _instance;
  InvoiceRepository._internal();

  final ApiClient _api = ApiClient();

  Future<BillingDashboard> getDashboard() async {
    final response = await _api.dio.get('/invoices/dashboard');
    final data = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
    return BillingDashboard.fromJson(data);
  }

  Future<List<Invoice>> getInvoices(InvoiceQuery query) async {
    final response = await _api.dio.get(
      '/invoices',
      queryParameters: query.toQueryParameters(),
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Invoice.fromJson)
        .toList();
  }

  Future<BillingFormData> getFormData() async {
    final responses = await Future.wait([
      _api.dio.get('/customers', queryParameters: {'limit': 100}),
      _api.dio.get(
        '/inventory/overview',
        queryParameters: {'status': 'in_stock'},
      ),
    ]);
    final customers = (responses[0].data as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BillingCustomerOption.fromJson)
        .toList();
    final rawItems =
        ((responses[1].data as Map?)?['items'] as List<dynamic>?) ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(BillingInventoryItem.fromJson)
        .toList();
    return BillingFormData(customers: customers, items: items);
  }

  Future<InvoicePreview> preview(InvoiceDraft draft) async {
    final response = await _api.dio.post(
      '/invoices/preview',
      data: draft.toJson(),
    );
    final data = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
    return InvoicePreview.fromJson(data);
  }

  Future<void> create(InvoiceDraft draft, {required String idempotencyKey}) {
    return _api.dio.post(
      '/invoices',
      data: draft.toJson(idempotencyKey: idempotencyKey),
    );
  }

  Future<void> addPayment(
    String invoiceId, {
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
  }) {
    return _api.dio.post(
      '/invoices/$invoiceId/payments',
      data: {
        'amount': amount,
        'paymentMode': paymentMode,
        if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
          'referenceNumber': referenceNumber.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
  }

  Future<PrintableInvoice> getPrintable(String id) async {
    final response = await _api.dio.get('/invoices/$id/print');
    final data = (response.data as Map).cast<String, dynamic>();
    return PrintableInvoice.fromJson(data);
  }

  Future<InvoicePdfPayload> getPdf(String id) async {
    final response = await _api.dio.get('/invoices/$id/pdf');
    final payload = (response.data as Map).cast<String, dynamic>();
    return decodeInvoicePdfPayload(
      payload,
      fallbackFileName: 'invoice-$id.pdf',
    );
  }

  Future<Uri> getShareUri(String id) async {
    final response = await _api.dio.get('/invoices/$id/share');
    final payload = (response.data as Map).cast<String, dynamic>();
    return invoiceWhatsAppUri(payload);
  }
}
