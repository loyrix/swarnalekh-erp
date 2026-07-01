/// Typed inventory row from `GET /inventory/overview`.
///
/// Carries every field the list, detail sheet, and add/edit form need, so no
/// screen reads `Map<String, dynamic>` directly.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.itemName,
    required this.tagNumber,
    required this.designNumber,
    required this.categoryName,
    required this.metalType,
    required this.stockType,
    required this.karat,
    required this.purity,
    required this.status,
    required this.quantity,
    required this.grossWeight,
    required this.netWeight,
    required this.stoneWeight,
    required this.stoneValue,
    required this.purchaseRate,
    required this.sellingPrice,
    required this.estimatedSellingPrice,
    required this.makingChargesPerGram,
    required this.makingChargesFixed,
    required this.makingChargesPercent,
    required this.location,
    required this.photo,
  });

  final String id;
  final String? itemName;
  final String? tagNumber;
  final String? designNumber;
  final String? categoryName;
  final String metalType;
  final String stockType;
  final String? karat;
  final double? purity;
  final String status;
  final int quantity;
  final double? grossWeight;
  final double? netWeight;
  final double? stoneWeight;
  final double? stoneValue;
  final double? purchaseRate;

  /// Explicitly saved selling price (from Add Stock), if any.
  final double? sellingPrice;

  /// Server-estimated selling price used for display.
  final double? estimatedSellingPrice;

  final double? makingChargesPerGram;
  final double? makingChargesFixed;
  final double? makingChargesPercent;
  final String? location;

  /// First photo (data-URI or URL), if any.
  final String? photo;

  static double? _numOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String? _strOrNull(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final category =
        json['categoryName'] ??
        (json['category'] is Map ? json['category']['name'] : null);
    final photos = json['photos'];
    String? firstPhoto;
    if (photos is List && photos.isNotEmpty) {
      firstPhoto = photos.first?.toString();
    } else if (photos is String && photos.trim().isNotEmpty) {
      firstPhoto = photos;
    }

    return InventoryItem(
      id: (json['id'] ?? '').toString(),
      itemName: _strOrNull(json['itemName']),
      tagNumber: _strOrNull(json['tagNumber']),
      designNumber:
          _strOrNull(json['designNumber']) ?? _strOrNull(json['barcode']),
      categoryName: _strOrNull(category),
      metalType: (json['metalType'] ?? 'gold').toString(),
      stockType: (json['stockType'] ?? 'unique').toString(),
      karat: _strOrNull(json['karat']),
      purity: _numOrNull(json['purity']),
      status: (json['status'] ?? 'in_stock').toString(),
      quantity: (_numOrNull(json['quantity']) ?? 1).round(),
      grossWeight: _numOrNull(json['grossWeight']),
      netWeight: _numOrNull(json['netWeight']),
      stoneWeight: _numOrNull(json['stoneWeight']),
      stoneValue: _numOrNull(json['stoneValue']),
      purchaseRate: _numOrNull(json['purchaseRate']),
      sellingPrice: _numOrNull(json['sellingPrice']),
      estimatedSellingPrice: _numOrNull(json['estimatedSellingPrice']),
      makingChargesPerGram: _numOrNull(json['makingChargesPerGram']),
      makingChargesFixed: _numOrNull(json['makingChargesFixed']),
      makingChargesPercent: _numOrNull(json['makingChargesPercent']),
      location: _strOrNull(json['location']),
      photo: firstPhoto,
    );
  }
}

/// A row from `GET /inventory/sold-products`.
class SoldProduct {
  const SoldProduct({
    required this.productName,
    required this.invoiceNumber,
    required this.customerName,
    required this.soldDate,
    required this.sellingPrice,
    required this.paymentMethod,
  });

  final String? productName;
  final String? invoiceNumber;
  final String? customerName;
  final String? soldDate;
  final double? sellingPrice;
  final String? paymentMethod;

  factory SoldProduct.fromJson(Map<String, dynamic> json) {
    return SoldProduct(
      productName: InventoryItem._strOrNull(json['productName']),
      invoiceNumber: InventoryItem._strOrNull(json['invoiceNumber']),
      customerName: InventoryItem._strOrNull(json['customerName']),
      soldDate: InventoryItem._strOrNull(json['soldDate']),
      sellingPrice: InventoryItem._numOrNull(json['sellingPrice']),
      paymentMethod: InventoryItem._strOrNull(json['paymentMethod']),
    );
  }
}

/// Stats + alerts block from the overview payload.
class InventoryStats {
  const InventoryStats({
    required this.totalGoldWeight,
    required this.totalSilverWeight,
    required this.totalProducts,
    required this.soldThisMonth,
    required this.lowStock,
    required this.outOfStock,
    required this.highValueProducts,
    required this.unsoldProducts,
    required this.valuationDate,
  });

  final double totalGoldWeight;
  final double totalSilverWeight;
  final int totalProducts;
  final int soldThisMonth;
  final int lowStock;
  final int outOfStock;
  final int highValueProducts;
  final int unsoldProducts;
  final String? valuationDate;

  factory InventoryStats.fromJson(Map<String, dynamic> json) {
    final alerts =
        (json['alerts'] as Map?)?.cast<String, dynamic>() ?? const {};
    int asInt(dynamic v) => (InventoryItem._numOrNull(v) ?? 0).round();
    return InventoryStats(
      totalGoldWeight: InventoryItem._numOrNull(json['totalGoldWeight']) ?? 0,
      totalSilverWeight:
          InventoryItem._numOrNull(json['totalSilverWeight']) ?? 0,
      totalProducts: asInt(json['totalProducts']),
      soldThisMonth: asInt(json['soldThisMonth']),
      lowStock: asInt(alerts['lowStock']),
      outOfStock: asInt(alerts['outOfStock']),
      highValueProducts: asInt(alerts['highValueProducts']),
      unsoldProducts: asInt(alerts['unsoldProducts']),
      valuationDate: InventoryItem._strOrNull(json['valuationDate']),
    );
  }
}

/// Full overview payload: item list + stats.
class InventoryOverview {
  const InventoryOverview({required this.items, required this.stats});

  final List<InventoryItem> items;
  final InventoryStats? stats;

  factory InventoryOverview.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InventoryItem.fromJson)
        .toList();
    final stats = json['stats'];
    return InventoryOverview(
      items: items,
      stats: stats is Map<String, dynamic>
          ? InventoryStats.fromJson(stats)
          : null,
    );
  }
}
