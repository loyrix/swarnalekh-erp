import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/data/invoice_repository.dart';
import 'package:swarnbook/features/billing/presentation/billing_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen "Collect payment" form for an existing invoice. Records a
/// partial (or final) payment; the server moves amountPaid/balanceDue. Returns
/// `true` when a payment was recorded.
class CollectInvoicePaymentPage extends StatefulWidget {
  const CollectInvoicePaymentPage({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.balanceDue,
  });

  final String invoiceId;
  final String? invoiceNumber;
  final double balanceDue;

  static Future<bool?> open(
    BuildContext context, {
    required String invoiceId,
    String? invoiceNumber,
    required double balanceDue,
  }) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => CollectInvoicePaymentPage(
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        balanceDue: balanceDue,
      ),
    );
  }

  @override
  State<CollectInvoicePaymentPage> createState() =>
      _CollectInvoicePaymentPageState();
}

class _CollectInvoicePaymentPageState extends State<CollectInvoicePaymentPage> {
  final _repo = InvoiceRepository();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  String _paymentMode = 'cash';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.balanceDue > 0 ? widget.balanceDue.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value, AppLocalizations l10n) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || amount <= 0) {
      return l10n.validationMinGreaterZero;
    }
    if (amount > widget.balanceDue + 0.01) {
      return '${l10n.billingBalance}: ${billingMoney(widget.balanceDue)}';
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _repo.addPayment(
        widget.invoiceId,
        amount: double.parse(_amount.text.trim()),
        paymentMode: _paymentMode,
        referenceNumber: _reference.text,
        notes: _notes.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, l10n.errorFailedRecordPayment);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.billingCollectPayment,
        isSaving: _isSaving,
        saveLabel: l10n.billingCollectPayment,
        onSave: _save,
        footer: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfL(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.brd(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.billingBalance} '
                '(${widget.invoiceNumber ?? l10n.billingInvoiceFallback})',
                style: TextStyle(color: AppColors.text3(context), fontSize: 12),
              ),
              Text(
                billingMoney(widget.balanceDue),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        children: [
          Text(
            l10n.billingCollectSubtitle,
            style: TextStyle(color: AppColors.text3(context)),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.billingPaymentAmount,
              prefixText: '₹ ',
              border: const OutlineInputBorder(),
            ),
            validator: (v) => _validateAmount(v, l10n),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: InputDecoration(
              labelText: l10n.billingPaymentMode,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'cash',
                child: Text(l10n.billingPaymentCash),
              ),
              DropdownMenuItem(
                value: 'upi',
                child: Text(l10n.billingPaymentUpi),
              ),
              DropdownMenuItem(
                value: 'card',
                child: Text(l10n.billingPaymentCard),
              ),
              DropdownMenuItem(
                value: 'bank_transfer',
                child: Text(l10n.billingPaymentBankTransfer),
              ),
            ],
            onChanged: (v) => setState(() => _paymentMode = v ?? 'cash'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _reference,
            decoration: InputDecoration(
              labelText: l10n.billingReference,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.commonNotes,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
