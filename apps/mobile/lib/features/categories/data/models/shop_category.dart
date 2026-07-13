/// A jewellery category (Ring, Chain, …) with its tag prefix and
/// minimum-stock threshold. Server-seeded from the default master list.
class ShopCategory {
  const ShopCategory({
    required this.id,
    required this.name,
    required this.prefix,
    required this.minStockThreshold,
    required this.active,
    required this.inStockCount,
    required this.itemCount,
  });

  final String id;
  final String name;

  /// Tag prefix (RG → RG-01). Null for legacy categories the server could
  /// not derive a prefix for.
  final String? prefix;

  /// Category counts as out of stock when inStockCount <= threshold.
  final int minStockThreshold;
  final bool active;
  final int inStockCount;
  final int itemCount;

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    return ShopCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      prefix: _strOrNull(json['prefix']),
      minStockThreshold: _toInt(json['minStockThreshold']),
      active: json['active'] != false,
      inStockCount: _toInt(json['inStockCount']),
      itemCount: _toInt(json['itemCount']),
    );
  }

  static String? _strOrNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
