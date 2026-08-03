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

/// A single line in the New Bill form.
///
/// Two kinds of line share this shape and may sit on the same bill:
///  * **inventory** — `inventoryItemId` set; the server prices it from stock.
///  * **on-demand** — `inventoryItemId` null; the customer ordered something we
///    don't stock, so name/weight/purity are typed and the server prices them
///    from the daily rate. No stock is reserved.
class InvoiceDraftItem {
  const InvoiceDraftItem.inventory({
    required String this.inventoryItemId,
    required this.quantity,
  }) : itemName = null,
       metalType = null,
       karat = null,
       netWeight = null,
       makingCharges = null;

  const InvoiceDraftItem.onDemand({
    required String this.itemName,
    required String this.metalType,
    required String this.karat,
    required double this.netWeight,
    this.makingCharges,
  }) : inventoryItemId = null,
       quantity = 1;

  final String? inventoryItemId;
  final int quantity;

  // On-demand only.
  final String? itemName;
  final String? metalType;
  final String? karat;
  final double? netWeight;
  final double? makingCharges;

  bool get isOnDemand => inventoryItemId == null;

  Map<String, dynamic> toJson() => {
    if (inventoryItemId != null) 'inventoryItemId': inventoryItemId,
    'quantity': quantity,
    if (itemName != null) 'itemName': itemName,
    if (metalType != null) 'metalType': metalType,
    if (karat != null) 'karat': karat,
    if (netWeight != null) 'netWeight': netWeight,
    if (makingCharges != null) 'makingCharges': makingCharges,
  };
}

/// The full New Bill payload, shared verbatim by preview and create so the
/// previewed total is exactly what gets charged.
class InvoiceDraft {
  const InvoiceDraft({
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    this.amountPaid = 0,
    this.paymentMode = 'cash',
    this.notes,
    this.ratePerGramOverride,
    this.makingPerGramOverride,
    this.gstPercentOverride,
    this.oldGoldValue,
  });

  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final List<InvoiceDraftItem> items;
  final double amountPaid;
  final String paymentMode;
  final String? notes;

  /// Gold rate (per gram) typed on the bill; prices every rate-based line.
  final double? ratePerGramOverride;

  /// Making charge (per gram of gross weight) typed on the bill.
  final double? makingPerGramOverride;

  /// Total GST % typed on the bill (split evenly into CGST/SGST).
  final double? gstPercentOverride;

  /// Old gold exchanged, as the rupee amount agreed at the counter. The server
  /// deducts it from the taxable amount before GST, like a discount.
  final double? oldGoldValue;

  Map<String, dynamic> toJson({String? idempotencyKey}) {
    return {
      if (customerId != null) 'customerId': customerId,
      if (customerId == null && customerName != null)
        'customerName': customerName,
      if (customerId == null &&
          customerPhone != null &&
          customerPhone!.isNotEmpty)
        'customerPhone': customerPhone,
      if (customerAddress != null && customerAddress!.isNotEmpty)
        'customerAddress': customerAddress,
      'items': items.map((i) => i.toJson()).toList(),
      'amountPaid': amountPaid,
      'paymentMode': paymentMode,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (ratePerGramOverride != null && ratePerGramOverride! > 0)
        'ratePerGramOverride': ratePerGramOverride,
      if (makingPerGramOverride != null && makingPerGramOverride! >= 0)
        'makingPerGramOverride': makingPerGramOverride,
      if (gstPercentOverride != null && gstPercentOverride! >= 0)
        'gstPercentOverride': gstPercentOverride,
      if (oldGoldValue != null && oldGoldValue! > 0)
        'oldGoldValue': oldGoldValue,
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

  Future<Uri> getShareUri(String id) async {
    final response = await _api.dio.get('/invoices/$id/share');
    final payload = (response.data as Map).cast<String, dynamic>();
    return invoiceWhatsAppUri(payload);
  }
}
