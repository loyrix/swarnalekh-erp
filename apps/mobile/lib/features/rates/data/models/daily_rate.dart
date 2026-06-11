class DailyRate {
  final String id;
  final DateTime rateDate;
  final String metalType;
  final String? karat;
  final double ratePerGram;
  final String source;

  DailyRate({
    required this.id,
    required this.rateDate,
    required this.metalType,
    this.karat,
    required this.ratePerGram,
    required this.source,
  });

  factory DailyRate.fromJson(Map<String, dynamic> json) {
    return DailyRate(
      id: json['id'] ?? '',
      rateDate: DateTime.parse(
        json['rateDate'] ?? DateTime.now().toIso8601String(),
      ),
      metalType: json['metalType'] ?? 'gold',
      karat: json['karat'],
      ratePerGram:
          double.tryParse(json['ratePerGram']?.toString() ?? '0') ?? 0.0,
      source: json['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rateDate': rateDate.toIso8601String(),
      'metalType': metalType,
      'karat': karat,
      'ratePerGram': ratePerGram,
      'source': source,
    };
  }
}
