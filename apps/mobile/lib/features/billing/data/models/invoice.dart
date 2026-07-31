// Typed billing models. Presentation never touches raw `Map<String, dynamic>`.

double _d(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String? _s(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// A row from `GET /invoices` (history list).
class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.grandTotal,
    required this.amountPaid,
    required this.balanceDue,
    required this.itemCount,
  });

  final String id;
  final String? invoiceNumber;
  final String? customerName;
  final double grandTotal;
  final double amountPaid;
  final double balanceDue;
  final int itemCount;

  bool get isPaid => balanceDue <= 0;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    return Invoice(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: _s(json['invoiceNumber']),
      customerName: _s(json['customerName']),
      grandTotal: _d(json['grandTotal']),
      amountPaid: _d(json['amountPaid']),
      balanceDue: _d(json['balanceDue']),
      itemCount: items is List ? items.length : 0,
    );
  }
}

/// A single top-selling product on the billing dashboard.
class TopSellingProduct {
  const TopSellingProduct({required this.itemName, required this.quantity});

  final String itemName;
  final int quantity;

  factory TopSellingProduct.fromJson(Map<String, dynamic> json) {
    return TopSellingProduct(
      itemName: (json['itemName'] ?? 'Item').toString(),
      quantity: _i(json['quantity']),
    );
  }
}

/// `GET /invoices/dashboard`.
class BillingDashboard {
  const BillingDashboard({
    required this.todaysRevenue,
    required this.monthlyRevenue,
    required this.totalBills,
    required this.averageBillValue,
    required this.topSellingProducts,
  });

  final double todaysRevenue;
  final double monthlyRevenue;
  final int totalBills;
  final double averageBillValue;
  final List<TopSellingProduct> topSellingProducts;

  factory BillingDashboard.fromJson(Map<String, dynamic> json) {
    final top = json['topSellingProducts'];
    return BillingDashboard(
      todaysRevenue: _d(json['todaysRevenue']),
      monthlyRevenue: _d(json['monthlyRevenue']),
      totalBills: _i(json['totalBills']),
      averageBillValue: _d(json['averageBillValue']),
      topSellingProducts: top is List
          ? top
                .whereType<Map<String, dynamic>>()
                .map(TopSellingProduct.fromJson)
                .toList()
          : const [],
    );
  }
}

/// One priced line from `POST /invoices/preview`.
class InvoicePreviewLine {
  const InvoicePreviewLine({
    required this.inventoryItemId,
    required this.itemName,
    required this.karat,
    required this.quantity,
    required this.netWeight,
    required this.ratePerGram,
    required this.metalValue,
    required this.makingCharges,
    required this.itemTotal,
  });

  final String inventoryItemId;
  final String? itemName;
  final String? karat;
  final int quantity;
  final double netWeight;

  /// Metal rate used to price this line (0 when an explicit selling price was
  /// used instead of a daily rate).
  final double ratePerGram;
  final double metalValue;
  final double makingCharges;
  final double itemTotal;

  factory InvoicePreviewLine.fromJson(Map<String, dynamic> json) {
    return InvoicePreviewLine(
      inventoryItemId: (json['inventoryItemId'] ?? '').toString(),
      itemName: _s(json['itemName']),
      karat: _s(json['karat']),
      quantity: _i(json['quantity']),
      netWeight: _d(json['netWeight']),
      ratePerGram: _d(json['ratePerGram']),
      metalValue: _d(json['metalValue']),
      makingCharges: _d(json['makingCharges']),
      itemTotal: _d(json['itemTotal']),
    );
  }
}

/// Server-computed pricing preview — the shown total equals the charged total.
class InvoicePreview {
  const InvoicePreview({
    required this.items,
    required this.subtotal,
    required this.totalMakingCharges,
    required this.totalStoneValue,
    required this.discountAmount,
    required this.taxableAmount,
    required this.totalTax,
    required this.grandTotal,
    this.customerAddress,
  });

  final List<InvoicePreviewLine> items;
  final double subtotal;
  final double totalMakingCharges;
  final double totalStoneValue;
  final double discountAmount;
  final double taxableAmount;
  final double totalTax;
  final double grandTotal;
  final String? customerAddress;

  /// Sum of per-line metal value — the "product value" summary metric.
  double get productValue =>
      items.fold(0.0, (sum, line) => sum + line.metalValue);

  int get totalUnits => items.fold(0, (sum, line) => sum + line.quantity);

  factory InvoicePreview.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    return InvoicePreview(
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(InvoicePreviewLine.fromJson)
                .toList()
          : const [],
      subtotal: _d(json['subtotal']),
      totalMakingCharges: _d(json['totalMakingCharges']),
      totalStoneValue: _d(json['totalStoneValue']),
      discountAmount: _d(json['discountAmount']),
      taxableAmount: _d(json['taxableAmount']),
      totalTax: _d(json['totalTax']),
      grandTotal: _d(json['grandTotal']),
      customerAddress: _s(json['customerAddress']),
    );
  }
}

/// A selectable inventory row for the New Bill form. Pricing lives on the
/// server (`/invoices/preview`); this only carries identity + display fields.
class BillingInventoryItem {
  const BillingInventoryItem({
    required this.id,
    required this.itemName,
    required this.tagNumber,
    required this.huid,
    required this.metalType,
    required this.karat,
    required this.stockType,
    required this.status,
    required this.availableQuantity,
    required this.netWeight,
    required this.photos,
    required this.searchBlob,
  });

  final String id;
  final String? itemName;
  final String? tagNumber;
  final String? huid;
  final String? metalType;
  final String? karat;
  final String stockType;
  final String status;
  final int availableQuantity;
  final double netWeight;

  /// Photo sources (data-URI or network URL); first one drives the thumbnail.
  final List<String> photos;
  final String searchBlob;

  bool get isBulk => stockType == 'bulk';

  String? get firstPhoto => photos.isNotEmpty ? photos.first : null;

  bool matches(String query) => searchBlob.contains(query.toLowerCase());

  factory BillingInventoryItem.fromJson(Map<String, dynamic> json) {
    final blob = [
      json['itemName'],
      json['tagNumber'],
      json['barcode'],
      json['designNumber'],
      json['categoryName'],
      json['metalType'],
      json['karat'],
      json['huid'],
    ].whereType<Object>().map((v) => v.toString().toLowerCase()).join(' ');
    final rawPhotos = json['photos'];
    return BillingInventoryItem(
      id: (json['id'] ?? '').toString(),
      itemName: _s(json['itemName']),
      tagNumber: _s(json['tagNumber']),
      huid: _s(json['huid']),
      metalType: _s(json['metalType']),
      karat: _s(json['karat']),
      stockType: (json['stockType'] ?? 'unique').toString(),
      status: (json['status'] ?? 'in_stock').toString(),
      availableQuantity: json['quantity'] == null ? 1 : _i(json['quantity']),
      netWeight: _d(json['netWeight']),
      photos: rawPhotos is List
          ? rawPhotos
                .map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList()
          : const [],
      searchBlob: blob,
    );
  }
}

/// A saved-customer option for the New Bill dropdown. Carries the denormalized
/// relationship stats (`totalPurchases`, `totalVisits`, `lastVisitAt`) that the
/// API keeps up to date on every invoice create, so the picker can show a rich
/// customer card without an extra request.
class BillingCustomerOption {
  const BillingCustomerOption({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.totalPurchases,
    required this.totalVisits,
    required this.lastVisitAt,
  });

  final String id;
  final String? name;
  final String? phone;
  final String? address;
  final String? city;

  /// Lifetime amount billed to this customer (cumulative), not the last bill.
  final double totalPurchases;

  /// Number of invoices raised for this customer.
  final int totalVisits;
  final DateTime? lastVisitAt;

  /// Human location line: "address, city" (either part may be missing).
  String? get location {
    final parts = [
      address,
      city,
    ].where((p) => p != null && p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  factory BillingCustomerOption.fromJson(Map<String, dynamic> json) {
    return BillingCustomerOption(
      id: (json['id'] ?? '').toString(),
      name: _s(json['name']),
      phone: _s(json['phone']),
      address: _s(json['address']),
      city: _s(json['city']),
      totalPurchases: _d(json['totalPurchases']),
      totalVisits: _i(json['totalVisits']),
      lastVisitAt: DateTime.tryParse(json['lastVisitAt']?.toString() ?? ''),
    );
  }
}

/// Everything the New Bill form needs to load up-front.
class BillingFormData {
  const BillingFormData({required this.customers, required this.items});

  final List<BillingCustomerOption> customers;
  final List<BillingInventoryItem> items;
}

// ---------------------------------------------------------------------------
// Printable invoice (`GET /invoices/:id/print`) — used by the detail sheet.
// ---------------------------------------------------------------------------

class PrintableShop {
  const PrintableShop({
    required this.name,
    required this.phone,
    required this.gstin,
    required this.pan,
    required this.address,
    required this.logoUrl,
  });

  final String? name;
  final String? phone;
  final String? gstin;
  final String? pan;
  final String? address;
  final String? logoUrl;

  factory PrintableShop.fromJson(Map<String, dynamic> json) {
    final address = [
      json['address'],
      json['city'],
      json['state'],
      json['pincode'],
    ].where((p) => p?.toString().trim().isNotEmpty == true).join(', ');
    return PrintableShop(
      name: _s(json['name']),
      phone: _s(json['phone']),
      gstin: _s(json['gstin']),
      pan: _s(json['pan']),
      address: address.isEmpty ? null : address,
      logoUrl: _s(json['logoUrl']),
    );
  }
}

class PrintableItem {
  const PrintableItem({
    required this.itemName,
    required this.karat,
    required this.grossWeight,
    required this.netWeight,
    required this.ratePerGram,
    required this.makingCharges,
    required this.itemTotal,
  });

  final String? itemName;
  final String? karat;
  final double grossWeight;
  final double netWeight;
  final double ratePerGram;
  final double makingCharges;
  final double itemTotal;

  factory PrintableItem.fromJson(Map<String, dynamic> json) {
    return PrintableItem(
      itemName: _s(json['itemName']),
      karat: _s(json['karat']),
      grossWeight: _d(json['grossWeight']),
      netWeight: _d(json['netWeight']),
      ratePerGram: _d(json['ratePerGram']),
      makingCharges: _d(json['makingCharges']),
      itemTotal: _d(json['itemTotal']),
    );
  }
}

/// A payment recorded against an invoice (`GET /invoices/:id/payments` or the
/// `payments` array on the printable detail).
class InvoicePayment {
  const InvoicePayment({
    required this.id,
    required this.amount,
    required this.paymentMode,
    required this.referenceNumber,
    required this.notes,
    required this.paymentDate,
  });

  final String id;
  final double amount;
  final String paymentMode;
  final String? referenceNumber;
  final String? notes;
  final DateTime? paymentDate;

  factory InvoicePayment.fromJson(Map<String, dynamic> json) {
    return InvoicePayment(
      id: (json['id'] ?? '').toString(),
      amount: _d(json['amount']),
      paymentMode: (json['paymentMode'] ?? 'cash').toString(),
      referenceNumber: _s(json['referenceNumber']),
      notes: _s(json['notes']),
      paymentDate: DateTime.tryParse(
        (json['paymentDate'] ?? json['createdAt'])?.toString() ?? '',
      ),
    );
  }
}

class PrintableInvoiceDetail {
  const PrintableInvoiceDetail({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerGstin,
    required this.paymentMode,
    required this.items,
    required this.subtotal,
    required this.totalMakingCharges,
    required this.totalStoneValue,
    required this.discountAmount,
    required this.oldGoldValue,
    required this.taxableAmount,
    required this.cgstPercent,
    required this.cgstAmount,
    required this.sgstPercent,
    required this.sgstAmount,
    required this.igstPercent,
    required this.igstAmount,
    required this.totalTax,
    required this.grandTotal,
    required this.amountPaid,
    required this.balanceDue,
    required this.notes,
    required this.payments,
  });

  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerGstin;
  final String? paymentMode;
  final List<PrintableItem> items;
  final double subtotal;
  final double totalMakingCharges;
  final double totalStoneValue;
  final double discountAmount;
  final double oldGoldValue;
  final double taxableAmount;
  final double cgstPercent;
  final double cgstAmount;
  final double sgstPercent;
  final double sgstAmount;
  final double igstPercent;
  final double igstAmount;
  final double totalTax;
  final double grandTotal;
  final double amountPaid;
  final double balanceDue;
  final String? notes;
  final List<InvoicePayment> payments;

  bool get hasBalance => balanceDue > 0;

  factory PrintableInvoiceDetail.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final payments = json['payments'];
    return PrintableInvoiceDetail(
      invoiceNumber: _s(json['invoiceNumber']),
      invoiceDate: DateTime.tryParse(json['invoiceDate']?.toString() ?? ''),
      customerName: _s(json['customerName']),
      customerPhone: _s(json['customerPhone']),
      customerAddress: _s(json['customerAddress']),
      customerGstin: _s(json['customerGstin']),
      paymentMode: _s(json['paymentMode']),
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(PrintableItem.fromJson)
                .toList()
          : const [],
      subtotal: _d(json['subtotal']),
      totalMakingCharges: _d(json['totalMakingCharges']),
      totalStoneValue: _d(json['totalStoneValue']),
      discountAmount: _d(json['discountAmount']),
      oldGoldValue: _d(json['oldGoldValue']),
      taxableAmount: _d(json['taxableAmount']),
      cgstPercent: _d(json['cgstPercent']),
      cgstAmount: _d(json['cgstAmount']),
      sgstPercent: _d(json['sgstPercent']),
      sgstAmount: _d(json['sgstAmount']),
      igstPercent: _d(json['igstPercent']),
      igstAmount: _d(json['igstAmount']),
      totalTax: _d(json['totalTax']),
      grandTotal: _d(json['grandTotal']),
      amountPaid: _d(json['amountPaid']),
      balanceDue: _d(json['balanceDue']),
      notes: _s(json['notes']),
      payments: payments is List
          ? payments
                .whereType<Map<String, dynamic>>()
                .map(InvoicePayment.fromJson)
                .toList()
          : const [],
    );
  }
}

class PrintableInvoice {
  const PrintableInvoice({
    required this.shop,
    required this.invoice,
    required this.qrPayload,
    required this.verificationCode,
    required this.generatedAt,
  });

  final PrintableShop shop;
  final PrintableInvoiceDetail invoice;
  final String? qrPayload;
  final String? verificationCode;
  final DateTime? generatedAt;

  factory PrintableInvoice.fromJson(Map<String, dynamic> json) {
    return PrintableInvoice(
      shop: PrintableShop.fromJson(
        (json['shop'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      invoice: PrintableInvoiceDetail.fromJson(
        (json['invoice'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      qrPayload: _s(json['qrPayload']),
      verificationCode: _s(json['verificationCode']),
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
    );
  }
}
