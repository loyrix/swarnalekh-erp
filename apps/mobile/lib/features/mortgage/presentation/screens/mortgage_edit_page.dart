import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_form_helpers.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Edit a loan's correctable fields — customer details, interest rate and
/// notes. Principal and loan date are intentionally not editable (they would
/// rewrite the interest history). Returns `true` when saved.
class MortgageEditPage extends StatefulWidget {
  const MortgageEditPage({super.key, required this.loan});

  final MortgageLoan loan;

  static Future<bool?> open(
    BuildContext context, {
    required MortgageLoan loan,
  }) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => MortgageEditPage(loan: loan),
    );
  }

  @override
  State<MortgageEditPage> createState() => _MortgageEditPageState();
}

class _MortgageEditPageState extends State<MortgageEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MortgageRepository();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _aadhaar;
  late final TextEditingController _pan;
  late final TextEditingController _rate;
  late final TextEditingController _notes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    _name = TextEditingController(text: l.customerName ?? '');
    _phone = TextEditingController(text: l.customerPhone ?? '');
    _aadhaar = TextEditingController(text: l.aadhaarNumber ?? '');
    _pan = TextEditingController(text: l.panNumber ?? '');
    _rate = TextEditingController(text: '${l.interestRateMonthly}');
    _notes = TextEditingController(text: l.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _aadhaar.dispose();
    _pan.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _repo.updateLoan(widget.loan.id, {
        'customerName': _name.text.trim(),
        'customerPhone': mortgageEmptyToNull(_phone.text),
        'aadhaarNumber': mortgageEmptyToNull(_aadhaar.text),
        'panNumber': mortgageEmptyToNull(_pan.text),
        'interestRateMonthly': mortgageNumber(_rate.text),
        'notes': mortgageEmptyToNull(_notes.text),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        mortgageErrorMessage(error, l10n.mortgageFailedUpdateLoan),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.mortgageEditLoan,
        isSaving: _isSaving,
        saveLabel: l10n.commonSave,
        onSave: _save,
        children: [
          SectionHeader(title: l10n.mortgageCustomerDetails),
          const SizedBox(height: AppSpacing.sm),
          mortgageField(
            context,
            _name,
            l10n.mortgageCustomerName,
            required: true,
          ),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _phone, l10n.mortgageMobileNumber),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _aadhaar, l10n.mortgageAadhaarNumber),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _pan, l10n.mortgagePanNumber),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.mortgageLoanDetails),
          const SizedBox(height: AppSpacing.sm),
          mortgageField(
            context,
            _rate,
            l10n.mortgageInterestRatePercent,
            required: true,
            numeric: true,
          ),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _notes, l10n.commonNotes),
        ],
      ),
    );
  }
}
