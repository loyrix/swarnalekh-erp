import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_form_helpers.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen loan settlement (close) form. Returns `true` on success.
class CloseLoanPage extends StatefulWidget {
  const CloseLoanPage({
    super.key,
    required this.loanId,
    required this.settlementAmount,
  });

  final String loanId;
  final double settlementAmount;

  static Future<bool?> open(
    BuildContext context, {
    required String loanId,
    required double settlementAmount,
  }) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) =>
          CloseLoanPage(loanId: loanId, settlementAmount: settlementAmount),
    );
  }

  @override
  State<CloseLoanPage> createState() => _CloseLoanPageState();
}

class _CloseLoanPageState extends State<CloseLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MortgageRepository();
  late final TextEditingController _amount;
  final _notes = TextEditingController();
  bool _isSaving = false;
  String _paymentMode = 'cash';

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.settlementAmount > 0
          ? widget.settlementAmount.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _repo.closeLoan(widget.loanId, {
        'amountPaid': mortgageNumber(_amount.text),
        'paymentMode': _paymentMode,
        'closureDate': DateTime.now().toIso8601String(),
        'notes': mortgageEmptyToNull(_notes.text),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        mortgageErrorMessage(error, l10n.mortgageFailedCloseLoan),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.mortgageCloseLoan,
        isSaving: _isSaving,
        saveLabel: l10n.mortgageCloseLoan,
        onSave: _save,
        children: [
          mortgageField(
            context,
            _amount,
            l10n.mortgageSettlementAmount,
            required: true,
            numeric: true,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: InputDecoration(labelText: l10n.mortgagePaymentMode),
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
          mortgageField(context, _notes, l10n.commonNotes),
        ],
      ),
    );
  }
}
