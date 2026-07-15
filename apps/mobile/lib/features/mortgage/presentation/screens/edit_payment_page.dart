import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_form_helpers.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen "Edit Payment" form — corrects a wrongly entered amount or
/// type. The server reverts the old effect and recalculates the loan totals.
/// Returns `true` on success.
class EditPaymentPage extends StatefulWidget {
  const EditPaymentPage({
    super.key,
    required this.loanId,
    required this.payment,
  });

  final String loanId;
  final MortgagePayment payment;

  static Future<bool?> open(
    BuildContext context, {
    required String loanId,
    required MortgagePayment payment,
  }) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => EditPaymentPage(loanId: loanId, payment: payment),
    );
  }

  @override
  State<EditPaymentPage> createState() => _EditPaymentPageState();
}

class _EditPaymentPageState extends State<EditPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MortgageRepository();
  late final TextEditingController _amount;
  late String _paymentType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.payment.amount.toStringAsFixed(
        widget.payment.amount.truncateToDouble() == widget.payment.amount
            ? 0
            : 2,
      ),
    );
    _paymentType = widget.payment.paymentType == 'principal'
        ? 'principal'
        : 'interest';
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _repo.updatePayment(widget.loanId, widget.payment.id, {
        'amount': mortgageNumber(_amount.text),
        'paymentType': _paymentType,
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
        title: l10n.mortgageEditPayment,
        isSaving: _isSaving,
        saveLabel: l10n.commonSave,
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
        ],
      ),
    );
  }
}
