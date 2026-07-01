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
