import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/features/billing/presentation/billing_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';

/// Read-only invoice detail as an [AppDetailSheet] — replaces the old
/// full-width `DataTable` dialog. Items render as compact rows; GST + bill
/// summary as label/value sections.
Future<void> showInvoiceDetail(
  BuildContext context,
  PrintableInvoice printable, {
  required VoidCallback onPrint,
  required VoidCallback onDownload,
  required VoidCallback onShare,
  VoidCallback? onCollect,
}) {
  final l10n = AppLocalizations.of(context)!;
  final inv = printable.invoice;

  final customerRows = <AppDetailRow>[
    AppDetailRow(
      l10n.billingCustomerName,
      inv.customerName ?? l10n.customerWalkIn,
    ),
    if (inv.customerPhone != null)
      AppDetailRow(l10n.billingMobile, inv.customerPhone!),
    if (inv.customerAddress != null)
      AppDetailRow(l10n.billingCustomerAddress, inv.customerAddress!),
    if (inv.customerGstin != null)
      AppDetailRow(l10n.billingGstin, inv.customerGstin!),
    AppDetailRow(l10n.billingInvoiceDate, billingDate(inv.invoiceDate)),
    if (inv.paymentMode != null)
      AppDetailRow(l10n.billingPaymentMethod, inv.paymentMode!),
  ];

  final gstRows = <AppDetailRow>[
    AppDetailRow(l10n.billingTaxableAmount, billingMoney(inv.taxableAmount)),
    if (inv.cgstAmount > 0)
      AppDetailRow(
        'CGST ${billingPercent(inv.cgstPercent)}',
        billingMoney(inv.cgstAmount),
      ),
    if (inv.sgstAmount > 0)
      AppDetailRow(
        'SGST ${billingPercent(inv.sgstPercent)}',
        billingMoney(inv.sgstAmount),
      ),
    if (inv.igstAmount > 0)
      AppDetailRow(
        'IGST ${billingPercent(inv.igstPercent)}',
        billingMoney(inv.igstAmount),
      ),
    AppDetailRow(l10n.billingTotalGst, billingMoney(inv.totalTax)),
  ];

  final summaryRows = <AppDetailRow>[
    AppDetailRow(l10n.billingGoldValue, billingMoney(inv.subtotal)),
    AppDetailRow(
      l10n.billingMakingCharges,
      billingMoney(inv.totalMakingCharges),
    ),
    if (inv.totalStoneValue > 0)
      AppDetailRow(l10n.billingStoneValue, billingMoney(inv.totalStoneValue)),
    if (inv.discountAmount > 0)
      AppDetailRow(l10n.billingDiscount, billingMoney(inv.discountAmount)),
    if (inv.oldGoldValue > 0)
      AppDetailRow(l10n.billingOldGold, billingMoney(inv.oldGoldValue)),
    AppDetailRow(
      l10n.billingFinalTotal,
      billingMoney(inv.grandTotal),
      emphasize: true,
    ),
    AppDetailRow(l10n.billingPaid, billingMoney(inv.amountPaid)),
    AppDetailRow(l10n.billingBalance, billingMoney(inv.balanceDue)),
  ];

  final subtitleParts = [
    inv.customerName ?? l10n.customerWalkIn,
    billingDate(inv.invoiceDate),
  ];

  return AppDetailSheet.show(
    context,
    title: inv.invoiceNumber ?? l10n.billingInvoiceFallback,
    subtitle: subtitleParts.join(' • '),
    extra: _InvoiceExtras(printable: printable),
    sections: [
      AppDetailSection(
        heading: l10n.billingCustomerDetails,
        rows: customerRows,
      ),
      AppDetailSection(heading: l10n.billingGstBreakdown, rows: gstRows),
      AppDetailSection(heading: l10n.billingBillCalculation, rows: summaryRows),
    ],
    actions: [
      if (onCollect != null && inv.hasBalance)
        GoldButton(
          label: l10n.billingActionCollect,
          icon: Icons.payments_outlined,
          onPressed: () {
            Navigator.of(context).maybePop();
            onCollect();
          },
        ),
      GoldButton(
        label: l10n.billingActionPrint,
        icon: Icons.print_outlined,
        isOutlined: true,
        onPressed: () {
          Navigator.of(context).maybePop();
          onPrint();
        },
      ),
      GoldButton(
        label: l10n.billingActionDownload,
        icon: Icons.download_outlined,
        isOutlined: true,
        onPressed: () {
          Navigator.of(context).maybePop();
          onDownload();
        },
      ),
      GoldButton(
        label: l10n.billingActionShare,
        icon: Icons.share_outlined,
        onPressed: () {
          Navigator.of(context).maybePop();
          onShare();
        },
      ),
    ],
  );
}

class _InvoiceExtras extends StatelessWidget {
  const _InvoiceExtras({required this.printable});

  final PrintableInvoice printable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = printable.invoice.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.billingItems),
        const SizedBox(height: AppSpacing.xs),
        if (items.isEmpty)
          Text(
            l10n.billingNoProductsFound,
            style: TextStyle(color: AppColors.text3(context)),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: CompactDataRow(
                title: item.itemName ?? l10n.billingItemFallback,
                subtitle: item.karat,
                metrics: [
                  (l10n.billingNet, billingWeight(item.netWeight)),
                  (l10n.billingRate, billingMoney(item.ratePerGram)),
                  (l10n.billingMakingCharges, billingMoney(item.makingCharges)),
                ],
                trailing: Text(
                  billingMoney(item.itemTotal),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1(context),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        _heading(context, l10n.billingPayments),
        const SizedBox(height: AppSpacing.xs),
        if (printable.invoice.payments.isEmpty)
          Text(
            l10n.billingNoPayments,
            style: TextStyle(color: AppColors.text3(context)),
          )
        else
          ...printable.invoice.payments.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: CompactDataRow(
                leading: Container(
                  alignment: Alignment.center,
                  color: AppColors.success.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                title: billingMoney(p.amount),
                subtitle: [
                  p.paymentMode,
                  if (p.referenceNumber != null) p.referenceNumber!,
                ].join(' • '),
                trailing: Text(
                  billingDate(p.paymentDate),
                  style: TextStyle(
                    color: AppColors.text3(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _heading(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.text3(context),
      ),
    );
  }
}
