/// Typed dashboard payload from `GET /dashboard/bootstrap`.
///
/// Replaces the previous `Map<String, dynamic>` access so the screen reads
/// strongly-typed fields and parsing lives in one tested place.
class DashboardData {
  const DashboardData({
    required this.stats,
    required this.userName,
    required this.role,
    required this.shopName,
  });

  final DashboardStats stats;
  final String userName;
  final String? role;
  final String shopName;

  factory DashboardData.fromBootstrap(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final tenant = json['tenant'] as Map<String, dynamic>? ?? const {};
    return DashboardData(
      stats: DashboardStats.fromJson(stats),
      userName: (user['name'] ?? '').toString(),
      role: user['role']?.toString(),
      shopName: (tenant['shopName'] ?? '').toString(),
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.totalGoldStock,
    required this.totalSilverStock,
    required this.totalInventoryValue,
    required this.monthlyRevenue,
    required this.pendingMortgageInterest,
    required this.activeLoans,
    required this.todaysSales,
    required this.totalBillsGenerated,
    required this.soldProductsThisMonth,
    required this.salesTrend,
    this.categoryStockAlerts = const [],
  });

  final double totalGoldStock;
  final double totalSilverStock;
  final double totalInventoryValue;
  final double monthlyRevenue;
  final double pendingMortgageInterest;
  final int activeLoans;
  final double todaysSales;
  final int totalBillsGenerated;
  final int soldProductsThisMonth;
  final List<SalesTrendPoint> salesTrend;

  /// Categories at/below their minimum-stock threshold (or emptied out).
  final List<CategoryStockAlert> categoryStockAlerts;

  static double _num(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _int(dynamic value) => _num(value).round();

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final trend = (json['salesTrend'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SalesTrendPoint.fromJson)
        .toList();
    return DashboardStats(
      totalGoldStock: _num(json['totalGoldStock']),
      totalSilverStock: _num(json['totalSilverStock']),
      totalInventoryValue: _num(json['totalInventoryValue']),
      monthlyRevenue: _num(json['monthlyRevenue']),
      pendingMortgageInterest: _num(json['pendingMortgageInterest']),
      activeLoans: _int(json['activeLoans']),
      todaysSales: _num(json['todaysSales']),
      totalBillsGenerated: _int(json['totalBillsGenerated']),
      soldProductsThisMonth: _int(json['soldProductsThisMonth']),
      salesTrend: trend,
      categoryStockAlerts:
          (json['categoryStockAlerts'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(CategoryStockAlert.fromJson)
              .toList(),
    );
  }
}

/// One category needing a restock (Dashboard out-of-stock tile).
class CategoryStockAlert {
  const CategoryStockAlert({
    required this.id,
    required this.name,
    required this.prefix,
    required this.inStockCount,
    required this.minStockThreshold,
    required this.isOut,
  });

  final String id;
  final String name;
  final String? prefix;
  final int inStockCount;
  final int minStockThreshold;

  /// true = nothing left (out of stock); false = at/below threshold (low).
  final bool isOut;

  factory CategoryStockAlert.fromJson(Map<String, dynamic> json) {
    final prefix = json['prefix']?.toString().trim() ?? '';
    return CategoryStockAlert(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      prefix: prefix.isEmpty ? null : prefix,
      inStockCount: DashboardStats._int(json['inStockCount']),
      minStockThreshold: DashboardStats._int(json['minStockThreshold']),
      isOut: json['severity']?.toString() == 'out',
    );
  }
}

class SalesTrendPoint {
  const SalesTrendPoint({required this.date, required this.total});

  /// ISO date (YYYY-MM-DD) for the bucket.
  final String date;
  final double total;

  DateTime? get parsedDate => DateTime.tryParse(date);

  factory SalesTrendPoint.fromJson(Map<String, dynamic> json) {
    return SalesTrendPoint(
      date: (json['date'] ?? '').toString(),
      total: DashboardStats._num(json['total']),
    );
  }
}
