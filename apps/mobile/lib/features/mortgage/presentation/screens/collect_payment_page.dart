import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_form_helpers.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen "Collect Interest / Payment" form. Returns `true` on success.
class CollectPaymentPage extends StatefulWidget {
  const CollectPaymentPage({super.key, required this.loanId});

  final String loanId;

  static Future<bool?> open(BuildContext context, {required String loanId}) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => CollectPaymentPage(loanId: loanId),
    );
  }

  @override
  State<CollectPaymentPage> createState() => _CollectPaymentPageState();
}

class _CollectPaymentPageState extends State<CollectPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MortgageRepository();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  bool _isSaving = false;
  String _paymentType = 'interest';
  String _paymentMode = 'cash';

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _repo.collectPayment(widget.loanId, {
        'amount': mortgageNumber(_amount.text),
        'paymentType': _paymentType,
        'paymentMode': _paymentMode,
        'paymentDate': DateTime.now().toIso8601String(),
        'referenceNumber': mortgageEmptyToNull(_reference.text),
        'notes': mortgageEmptyToNull(_notes.text),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        mortgageErrorMessage(error, l10n.mortgageFailedSavePayment),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.mortgageCollectPayment,
        isSaving: _isSaving,
        saveLabel: l10n.mortgageSavePayment,
        onSave: _save,
        children: [
          mortgageField(
            context,
            _amount,
            l10n.mortgageAmount,
            required: true,
            numeric: true,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _paymentType,
            decoration: InputDecoration(labelText: l10n.mortgagePaymentType),
            items: [
              DropdownMenuItem(
                value: 'interest',
                child: Text(l10n.mortgageInterest),
              ),
              DropdownMenuItem(
                value: 'principal',
                child: Text(l10n.mortgagePrincipal),
              ),
            ],
            onChanged: (v) => setState(() => _paymentType = v ?? 'interest'),
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
          mortgageField(context, _reference, l10n.mortgageReferenceNumber),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _notes, l10n.commonNotes),
        ],
      ),
    );
  }
}
