/// Typed mortgage loan from `GET /mortgages`.
class MortgageLoan {
  const MortgageLoan({
    required this.id,
    required this.loanNumber,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.principalAmount,
    required this.outstandingPrincipal,
    required this.pendingInterestAmount,
    required this.totalPayableAmount,
    required this.totalInterestPaid,
    required this.interestRateMonthly,
    required this.nextDueDate,
    required this.closedAt,
    required this.aadhaarNumber,
    required this.panNumber,
    required this.photoIdUrl,
    required this.customerPhotoUrl,
    required this.notes,
    required this.ornaments,
    required this.payments,
  });

  final String id;
  final String? loanNumber;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final double principalAmount;
  final double outstandingPrincipal;
  final double pendingInterestAmount;
  final double totalPayableAmount;
  final double totalInterestPaid;
  final double interestRateMonthly;
  final String? nextDueDate;
  final String? closedAt;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? photoIdUrl;
  final String? customerPhotoUrl;
  final String? notes;
  final List<MortgageOrnament> ornaments;
  final List<MortgagePayment> payments;

  bool get isActive => status == 'active';

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory MortgageLoan.fromJson(Map<String, dynamic> json) {
    return MortgageLoan(
      id: (json['id'] ?? '').toString(),
      loanNumber: _str(json['loanNumber']),
      status: (json['status'] ?? 'active').toString(),
      customerName: _str(json['customerName']),
      customerPhone: _str(json['customerPhone']),
      principalAmount: _num(json['principalAmount']),
      outstandingPrincipal: _num(json['outstandingPrincipal']),
      pendingInterestAmount: _num(json['pendingInterestAmount']),
      totalPayableAmount: _num(json['totalPayableAmount']),
      totalInterestPaid: _num(json['totalInterestPaid']),
      interestRateMonthly: _num(json['interestRateMonthly']),
      nextDueDate: _str(json['nextDueDate']),
      closedAt: _str(json['closedAt']),
      aadhaarNumber: _str(json['aadhaarNumber']),
      panNumber: _str(json['panNumber']),
      photoIdUrl: _str(json['photoIdUrl']),
      customerPhotoUrl: _str(json['customerPhotoUrl']),
      notes: _str(json['notes']),
      ornaments: (json['ornaments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MortgageOrnament.fromJson)
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MortgagePayment.fromJson)
          .toList(),
    );
  }
}

class MortgageOrnament {
  const MortgageOrnament({
    required this.ornamentType,
    required this.purity,
    required this.grossWeight,
    required this.netWeight,
  });

  final String? ornamentType;
  final String? purity;
  final double? grossWeight;
  final double? netWeight;

  factory MortgageOrnament.fromJson(Map<String, dynamic> json) {
    return MortgageOrnament(
      ornamentType: MortgageLoan._str(json['ornamentType']),
      purity: MortgageLoan._str(json['purity']),
      grossWeight: MortgageLoan._num(json['grossWeight']),
      netWeight: MortgageLoan._num(json['netWeight']),
    );
  }
}

class MortgagePayment {
  const MortgagePayment({
    required this.id,
    required this.receiptNumber,
    required this.amount,
    required this.paymentType,
    required this.paymentMode,
    required this.paymentDate,
  });

  final String id;
  final String? receiptNumber;
  final double amount;
  final String? paymentType;
  final String? paymentMode;
  final String? paymentDate;

  factory MortgagePayment.fromJson(Map<String, dynamic> json) {
    return MortgagePayment(
      id: (json['id'] ?? '').toString(),
      receiptNumber: MortgageLoan._str(json['receiptNumber']),
      amount: MortgageLoan._num(json['amount']),
      paymentType: MortgageLoan._str(json['paymentType']),
      paymentMode: MortgageLoan._str(json['paymentMode']),
      paymentDate: MortgageLoan._str(json['paymentDate']),
    );
  }
}

/// Dashboard counters from `GET /mortgages/dashboard`.
class MortgageDashboard {
  const MortgageDashboard({
    required this.activeLoans,
    required this.closedLoans,
    required this.pendingInterest,
    required this.totalLoanAmount,
    required this.todaysCollections,
    required this.overdueLoans,
  });

  final int activeLoans;
  final int closedLoans;
  final double pendingInterest;
  final double totalLoanAmount;
  final double todaysCollections;
  final int overdueLoans;

  static int _int(dynamic v) => MortgageLoan._num(v).round();

  factory MortgageDashboard.fromJson(Map<String, dynamic> json) {
    return MortgageDashboard(
      activeLoans: _int(json['activeLoans']),
      closedLoans: _int(json['closedLoans']),
      pendingInterest: MortgageLoan._num(json['pendingInterest']),
      totalLoanAmount: MortgageLoan._num(json['totalLoanAmount']),
      todaysCollections: MortgageLoan._num(json['todaysCollections']),
      overdueLoans: _int(json['overdueLoans']),
    );
  }

  static const empty = MortgageDashboard(
    activeLoans: 0,
    closedLoans: 0,
    pendingInterest: 0,
    totalLoanAmount: 0,
    todaysCollections: 0,
    overdueLoans: 0,
  );
}
