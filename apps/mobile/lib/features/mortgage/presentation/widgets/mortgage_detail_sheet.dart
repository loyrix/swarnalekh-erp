import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';

/// Read-only loan detail as an [AppDetailSheet], including payment receipts and
/// Collect / Close actions.
Future<void> showMortgageDetail(
  BuildContext context,
  MortgageLoan loan, {
  required VoidCallback onCollect,
  VoidCallback? onClose,
  required void Function(MortgagePayment payment) onReceipt,
}) {
  final l10n = AppLocalizations.of(context)!;

  // Tenure runs to the closing date for a closed loan, else to now.
  final tenure = mortgageTenure(
    loan.loanDate,
    asOf: loan.isActive ? null : DateTime.tryParse(loan.closedAt ?? ''),
  );

  final loanRows = <AppDetailRow>[
    AppDetailRow(l10n.reportsLoanAmount, mortgageMoney(loan.principalAmount)),
    AppDetailRow(l10n.mortgageLoanDate, mortgageDate(loan.loanDate)),
    AppDetailRow(l10n.mortgageTenure, tenure),
    if (loan.isActive) ...[
      AppDetailRow(
        l10n.mortgageOutstanding,
        mortgageMoney(loan.outstandingPrincipal),
      ),
      AppDetailRow(l10n.mortgageInterestMonths, '${loan.interestMonths}'),
      AppDetailRow(
        l10n.mortgagePendingInterest,
        mortgageMoney(loan.pendingInterestAmount),
      ),
      AppDetailRow(
        l10n.mortgageTotalPayable,
        mortgageMoney(loan.totalPayableAmount),
        emphasize: true,
      ),
      AppDetailRow(l10n.mortgageNextDue, mortgageDate(loan.nextDueDate)),
    ] else ...[
      AppDetailRow(
        l10n.mortgageInterestPaid,
        mortgageMoney(loan.totalInterestPaid),
      ),
      AppDetailRow(l10n.mortgageClosingDate, mortgageDate(loan.closedAt)),
    ],
    AppDetailRow(l10n.mortgageInterestRate, '${loan.interestRateMonthly}%'),
  ];

  final customerRows = <AppDetailRow>[
    AppDetailRow(
      l10n.mortgageCustomerName,
      loan.customerName ?? l10n.mortgageCustomerFallback,
    ),
    if (loan.customerPhone != null)
      AppDetailRow(l10n.mortgageMobileNumber, loan.customerPhone!),
    if (loan.aadhaarNumber != null)
      AppDetailRow(l10n.mortgageAadhaarNumber, loan.aadhaarNumber!),
    if (loan.panNumber != null)
      AppDetailRow(l10n.mortgagePanNumber, loan.panNumber!),
  ];

  final ornamentRows = [
    for (final o in loan.ornaments)
      AppDetailRow(
        '${o.ornamentType ?? '-'} · ${o.purity ?? '-'}',
        '${o.netWeight ?? 0} g / ${o.grossWeight ?? 0} g',
      ),
  ];

  return AppDetailSheet.show(
    context,
    title: loan.loanNumber ?? l10n.mortgageLoanFallback,
    subtitle: loan.customerName ?? l10n.mortgageCustomerFallback,
    sections: [
      AppDetailSection(
        heading: l10n.mortgageCustomerDetails,
        rows: customerRows,
      ),
      AppDetailSection(heading: l10n.mortgageLoanDetails, rows: loanRows),
      if (ornamentRows.isNotEmpty)
        AppDetailSection(heading: l10n.mortgageGoldDetails, rows: ornamentRows),
    ],
    extra: loan.payments.isEmpty
        ? null
        : _PaymentsBlock(payments: loan.payments, onReceipt: onReceipt),
    actions: [
      if (loan.isActive)
        GoldButton(
          label: l10n.mortgageCollect,
          icon: Icons.payments_outlined,
          onPressed: () {
            Navigator.of(context).maybePop();
            onCollect();
          },
        ),
      if (loan.isActive && onClose != null)
        GoldButton(
          label: l10n.mortgageClose,
          isOutlined: true,
          onPressed: () {
            Navigator.of(context).maybePop();
            onClose();
          },
        ),
    ],
  );
}

class _PaymentsBlock extends StatelessWidget {
  const _PaymentsBlock({required this.payments, required this.onReceipt});

  final List<MortgagePayment> payments;
  final void Function(MortgagePayment payment) onReceipt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mortgageReceipt,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.text3(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final payment in payments.take(5))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(mortgageMoney(payment.amount)),
            subtitle: Text(
              '${payment.receiptNumber ?? l10n.mortgageReceipt} • ${mortgageDate(payment.paymentDate)}',
            ),
            trailing: IconButton(
              tooltip: l10n.mortgageReceipt,
              icon: const Icon(Icons.download_rounded),
              onPressed: () => onReceipt(payment),
            ),
          ),
      ],
    );
  }
}
