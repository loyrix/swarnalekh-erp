import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_form_helpers.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen "Add Top-up" form — records extra principal on an active loan.
/// Returns `true` on success.
class TopUpLoanPage extends StatefulWidget {
  const TopUpLoanPage({super.key, required this.loanId});

  final String loanId;

  static Future<bool?> open(BuildContext context, {required String loanId}) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => TopUpLoanPage(loanId: loanId),
    );
  }

  @override
  State<TopUpLoanPage> createState() => _TopUpLoanPageState();
}

class _TopUpLoanPageState extends State<TopUpLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MortgageRepository();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _topupDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _topupDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _topupDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _repo.topUpLoan(widget.loanId, {
        'amount': mortgageNumber(_amount.text),
        'topupDate': _topupDate.toIso8601String(),
        'notes': mortgageEmptyToNull(_notes.text),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        mortgageErrorMessage(error, l10n.mortgageFailedTopup),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.mortgageTopupTitle,
        isSaving: _isSaving,
        saveLabel: l10n.mortgageAddTopup,
        onSave: _save,
        children: [
          Text(
            l10n.mortgageTopupHelp,
            style: TextStyle(color: AppColors.text2(context)),
          ),
          const SizedBox(height: AppSpacing.md),
          mortgageField(
            context,
            _amount,
            l10n.mortgageTopupAmount,
            required: true,
            numeric: true,
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.mortgageTopupDate,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
              ),
              child: Text(
                '${_topupDate.day.toString().padLeft(2, '0')}/'
                '${_topupDate.month.toString().padLeft(2, '0')}/'
                '${_topupDate.year}',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _notes, l10n.commonNotes),
        ],
      ),
    );
  }
}
