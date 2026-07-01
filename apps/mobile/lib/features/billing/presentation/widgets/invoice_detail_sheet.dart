import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/features/billing/presentation/billing_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';

/// Read-only invoice detail as an [AppDetailSheet] — replaces the old
/// full-width `DataTable` dialog. Items render as compact rows; GST + bill
/// summary as label/value sections; the verification code + QR as an extra.
Future<void> showInvoiceDetail(
  BuildContext context,
  PrintableInvoice printable, {
  required VoidCallback onPrint,
  required VoidCallback onDownload,
  required VoidCallback onShare,
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
      GoldButton(
        label: l10n.billingReprintInvoice,
        icon: Icons.print_outlined,
        isOutlined: true,
        onPressed: () {
          Navigator.of(context).maybePop();
          onPrint();
        },
      ),
      GoldButton(
        label: l10n.billingDownloadPdf,
        icon: Icons.download_outlined,
        isOutlined: true,
        onPressed: () {
          Navigator.of(context).maybePop();
          onDownload();
        },
      ),
      GoldButton(
        label: l10n.billingShareWhatsApp,
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
        _ProtectionBlock(printable: printable),
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

class _ProtectionBlock extends StatelessWidget {
  const _ProtectionBlock({required this.printable});

  final PrintableInvoice printable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final code = printable.verificationCode;
    final qr = printable.qrPayload;
    if (code == null && qr == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (code != null) ...[
                  Text(
                    l10n.billingVerification,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text3(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    code,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1(context),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${l10n.billingGenerated}: ${billingDate(printable.generatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text3(context),
                  ),
                ),
              ],
            ),
          ),
          if (qr != null) ...[
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 72,
              height: 72,
              child: QrImageView(
                data: qr,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
