/// Typed parse of `GET /reports/overview`. Each report is a typed list so the
/// screen never reads `Map<String, dynamic>`.
class ReportsData {
  const ReportsData({
    required this.currentStock,
    required this.soldProducts,
    required this.lowStock,
    required this.dailySales,
    required this.monthlySales,
    required this.gst,
    required this.activeLoans,
    required this.interestCollection,
    required this.closedLoans,
    required this.totalGoldWeight,
    required this.totalSilverWeight,
  });

  final List<InventoryReportItem> currentStock;
  final List<SoldReportItem> soldProducts;
  final List<InventoryReportItem> lowStock;
  final List<InvoiceSalesReportItem> dailySales;
  final List<InvoiceSalesReportItem> monthlySales;
  final List<GstReportItem> gst;
  final List<ActiveLoanReportItem> activeLoans;
  final List<InterestCollectionReportItem> interestCollection;
  final List<ClosedLoanReportItem> closedLoans;
  final double totalGoldWeight;
  final double totalSilverWeight;

  static List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) map) {
    return (value as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(map)
        .toList();
  }

  factory ReportsData.fromJson(Map<String, dynamic> json) {
    final reports = json['reports'] as Map<String, dynamic>? ?? const {};
    final stats = json['inventoryStats'] as Map<String, dynamic>? ?? const {};
    return ReportsData(
      currentStock: _list(
        reports['currentStock'],
        InventoryReportItem.fromJson,
      ),
      soldProducts: _list(reports['soldProducts'], SoldReportItem.fromJson),
      lowStock: _list(reports['lowStock'], InventoryReportItem.fromJson),
      dailySales: _list(reports['dailySales'], InvoiceSalesReportItem.fromJson),
      monthlySales: _list(
        reports['monthlySales'],
        InvoiceSalesReportItem.fromJson,
      ),
      gst: _list(reports['gst'], GstReportItem.fromJson),
      activeLoans: _list(reports['activeLoans'], ActiveLoanReportItem.fromJson),
      interestCollection: _list(
        reports['interestCollection'],
        InterestCollectionReportItem.fromJson,
      ),
      closedLoans: _list(reports['closedLoans'], ClosedLoanReportItem.fromJson),
      totalGoldWeight: _num(stats['totalGoldWeight']),
      totalSilverWeight: _num(stats['totalSilverWeight']),
    );
  }
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _int(dynamic v) => _num(v).round();

String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class InventoryReportItem {
  const InventoryReportItem({
    required this.itemName,
    required this.categoryName,
    required this.designTag,
    required this.status,
    required this.karatOrPurity,
    required this.grossWeight,
    required this.netWeight,
    required this.sellingPrice,
    required this.location,
    required this.quantity,
  });

  final String? itemName;
  final String? categoryName;
  final String? designTag;
  final String? status;
  final String? karatOrPurity;
  final double grossWeight;
  final double netWeight;
  final double sellingPrice;
  final String? location;
  final int quantity;

  factory InventoryReportItem.fromJson(Map<String, dynamic> j) {
    return InventoryReportItem(
      itemName: _str(j['itemName']),
      categoryName: _str(j['categoryName']),
      designTag: _str(j['tagNumber']) ?? _str(j['barcode']),
      status: _str(j['status']),
      karatOrPurity: _str(j['karat']) ?? _str(j['purity']),
      grossWeight: _num(j['grossWeight']),
      netWeight: _num(j['netWeight']),
      sellingPrice: _num(j['estimatedSellingPrice']),
      location: _str(j['location']),
      quantity: _int(j['quantity']),
    );
  }
}

class SoldReportItem {
  const SoldReportItem({
    required this.productName,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMode,
    required this.soldDate,
    required this.sellingPrice,
  });

  final String? productName;
  final String? invoiceNumber;
  final String? customerName;
  final String? customerPhone;
  final String? paymentMode;
  final String? soldDate;
  final double sellingPrice;

  factory SoldReportItem.fromJson(Map<String, dynamic> j) {
    return SoldReportItem(
      productName: _str(j['productName']),
      invoiceNumber: _str(j['invoiceNumber']),
      customerName: _str(j['customerName']),
      customerPhone: _str(j['customerPhone']),
      paymentMode: _str(j['paymentMode']),
      soldDate: _str(j['soldDate']),
      sellingPrice: _num(j['sellingPrice']),
    );
  }
}

class InvoiceSalesReportItem {
  const InvoiceSalesReportItem({
    required this.invoiceNumber,
    required this.customerName,
    required this.invoiceDate,
    required this.grandTotal,
    required this.paymentMode,
    required this.itemCount,
  });

  final String? invoiceNumber;
  final String? customerName;
  final String? invoiceDate;
  final double grandTotal;
  final String? paymentMode;
  final int itemCount;

  factory InvoiceSalesReportItem.fromJson(Map<String, dynamic> j) {
    return InvoiceSalesReportItem(
      invoiceNumber: _str(j['invoiceNumber']),
      customerName: _str(j['customerName']),
      invoiceDate: _str(j['invoiceDate']),
      grandTotal: _num(j['grandTotal']),
      paymentMode: _str(j['paymentMode']),
      itemCount: (j['items'] as List<dynamic>? ?? const []).length,
    );
  }
}

class GstReportItem {
  const GstReportItem({
    required this.invoiceNumber,
    required this.customerName,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.totalTax,
  });

  final String? invoiceNumber;
  final String? customerName;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double totalTax;

  factory GstReportItem.fromJson(Map<String, dynamic> j) {
    return GstReportItem(
      invoiceNumber: _str(j['invoiceNumber']),
      customerName: _str(j['customerName']),
      taxableAmount: _num(j['taxableAmount']),
      cgstAmount: _num(j['cgstAmount']),
      sgstAmount: _num(j['sgstAmount']),
      totalTax: _num(j['totalTax']),
    );
  }
}

class ActiveLoanReportItem {
  const ActiveLoanReportItem({
    required this.customerName,
    required this.loanNumber,
    required this.principalAmount,
    required this.pendingInterestAmount,
    required this.totalPayableAmount,
    required this.nextDueDate,
  });

  final String? customerName;
  final String? loanNumber;
  final double principalAmount;
  final double pendingInterestAmount;
  final double totalPayableAmount;
  final String? nextDueDate;

  factory ActiveLoanReportItem.fromJson(Map<String, dynamic> j) {
    return ActiveLoanReportItem(
      customerName: _str(j['customerName']),
      loanNumber: _str(j['loanNumber']),
      principalAmount: _num(j['principalAmount']),
      pendingInterestAmount: _num(j['pendingInterestAmount']),
      totalPayableAmount: _num(j['totalPayableAmount']),
      nextDueDate: _str(j['nextDueDate']),
    );
  }
}

class InterestCollectionReportItem {
  const InterestCollectionReportItem({
    required this.receiptNumber,
    required this.customerName,
    required this.customerPhone,
    required this.loanNumber,
    required this.paymentType,
    required this.paymentMode,
    required this.paymentDate,
    required this.amount,
  });

  final String? receiptNumber;
  final String? customerName;
  final String? customerPhone;
  final String? loanNumber;
  final String? paymentType;
  final String? paymentMode;
  final String? paymentDate;
  final double amount;

  factory InterestCollectionReportItem.fromJson(Map<String, dynamic> j) {
    return InterestCollectionReportItem(
      receiptNumber: _str(j['receiptNumber']),
      customerName: _str(j['customerName']),
      customerPhone: _str(j['customerPhone']),
      loanNumber: _str(j['loanNumber']),
      paymentType: _str(j['paymentType']),
      paymentMode: _str(j['paymentMode']),
      paymentDate: _str(j['paymentDate']),
      amount: _num(j['amount']),
    );
  }
}

class ClosedLoanReportItem {
  const ClosedLoanReportItem({
    required this.customerName,
    required this.loanNumber,
    required this.status,
    required this.principalAmount,
    required this.totalInterestPaid,
    required this.closedAt,
  });

  final String? customerName;
  final String? loanNumber;
  final String? status;
  final double principalAmount;
  final double totalInterestPaid;
  final String? closedAt;

  factory ClosedLoanReportItem.fromJson(Map<String, dynamic> j) {
    return ClosedLoanReportItem(
      customerName: _str(j['customerName']),
      loanNumber: _str(j['loanNumber']),
      status: _str(j['status']),
      principalAmount: _num(j['principalAmount']),
      totalInterestPaid: _num(j['totalInterestPaid']),
      closedAt: _str(j['closedAt']),
    );
  }
}
