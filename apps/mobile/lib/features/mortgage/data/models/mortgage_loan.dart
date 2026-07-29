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
    required this.interestMonths,
    required this.loanDate,
    required this.nextDueDate,
    required this.closedAt,
    required this.aadhaarNumber,
    required this.panNumber,
    required this.photoIdUrl,
    required this.customerPhotoUrl,
    required this.notes,
    required this.ornaments,
    required this.payments,
    required this.topups,
    required this.totalTopups,
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

  /// Months of interest charged so far (started month = full month).
  final int interestMonths;

  /// Date the customer pledged the mortgage (ISO string).
  final String? loanDate;
  final String? nextDueDate;
  final String? closedAt;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? photoIdUrl;
  final String? customerPhotoUrl;
  final String? notes;
  final List<MortgageOrnament> ornaments;
  final List<MortgagePayment> payments;
  final List<MortgageTopup> topups;
  final double totalTopups;

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
      interestMonths: _num(json['interestMonths']).round(),
      loanDate: _str(json['loanDate']),
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
      topups: (json['topups'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MortgageTopup.fromJson)
          .toList(),
      totalTopups: _num(json['totalTopups']),
    );
  }
}

/// One policy's settlement figures in the close preview.
class ClosePolicyFigures {
  const ClosePolicyFigures({
    required this.pendingInterest,
    required this.outstandingPrincipal,
    required this.totalPayable,
  });

  final double pendingInterest;
  final double outstandingPrincipal;
  final double totalPayable;

  factory ClosePolicyFigures.fromJson(Map<String, dynamic> json) {
    return ClosePolicyFigures(
      pendingInterest: MortgageLoan._num(json['pendingInterest']),
      outstandingPrincipal: MortgageLoan._num(json['outstandingPrincipal']),
      totalPayable: MortgageLoan._num(json['totalPayable']),
    );
  }
}

/// `GET /mortgages/:id/close-preview` — settlement under both top-up policies.
class MortgageClosePreview {
  const MortgageClosePreview({
    required this.hasTopups,
    required this.loanDate,
    required this.firstTopupDate,
    required this.totalTopups,
    required this.separate,
    required this.merge,
  });

  final bool hasTopups;
  final String? loanDate;
  final String? firstTopupDate;
  final double totalTopups;
  final ClosePolicyFigures separate;
  final ClosePolicyFigures merge;

  factory MortgageClosePreview.fromJson(Map<String, dynamic> json) {
    return MortgageClosePreview(
      hasTopups: json['hasTopups'] == true,
      loanDate: MortgageLoan._str(json['loanDate']),
      firstTopupDate: MortgageLoan._str(json['firstTopupDate']),
      totalTopups: MortgageLoan._num(json['totalTopups']),
      separate: ClosePolicyFigures.fromJson(
        (json['separate'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      merge: ClosePolicyFigures.fromJson(
        (json['merge'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

/// One row of the loan ledger (`GET /mortgages/:id/ledger`).
class MortgageLedgerEvent {
  const MortgageLedgerEvent({
    required this.date,
    required this.type,
    required this.amount,
    required this.direction,
  });

  final String? date;
  final String type;
  final double amount;
  final String direction; // 'debit' (out) | 'credit' (in)

  bool get isCredit => direction == 'credit';

  factory MortgageLedgerEvent.fromJson(Map<String, dynamic> json) {
    return MortgageLedgerEvent(
      date: MortgageLoan._str(json['date']),
      type: (json['type'] ?? '').toString(),
      amount: MortgageLoan._num(json['amount']),
      direction: (json['direction'] ?? 'debit').toString(),
    );
  }
}

class MortgageTopup {
  const MortgageTopup({
    required this.id,
    required this.amount,
    required this.topupDate,
    required this.notes,
  });

  final String id;
  final double amount;
  final String? topupDate;
  final String? notes;

  factory MortgageTopup.fromJson(Map<String, dynamic> json) {
    return MortgageTopup(
      id: (json['id'] ?? '').toString(),
      amount: MortgageLoan._num(json['amount']),
      topupDate: MortgageLoan._str(json['topupDate']),
      notes: MortgageLoan._str(json['notes']),
    );
  }
}

class MortgageOrnament {
  const MortgageOrnament({
    required this.ornamentType,
    required this.purity,
    required this.grossWeight,
    required this.netWeight,
    required this.photos,
  });

  final String? ornamentType;
  final String? purity;
  final double? grossWeight;
  final double? netWeight;
  final List<String> photos;

  String? get firstPhoto => photos.isNotEmpty ? photos.first : null;

  factory MortgageOrnament.fromJson(Map<String, dynamic> json) {
    final raw = json['photos'];
    return MortgageOrnament(
      ornamentType: MortgageLoan._str(json['ornamentType']),
      purity: MortgageLoan._str(json['purity']),
      grossWeight: MortgageLoan._num(json['grossWeight']),
      netWeight: MortgageLoan._num(json['netWeight']),
      photos: raw is List
          ? raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
          : const [],
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
