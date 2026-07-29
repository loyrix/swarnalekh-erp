import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_format.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_form_helpers.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen loan settlement (close) form. When the loan has top-ups, the
/// operator chooses how the top-up's interest is calculated — from the original
/// loan date (merge) or from the top-up date (separate) — with a live preview
/// of the final payable. Returns `true` on success.
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
  bool _loadingPreview = true;
  String _paymentMode = 'cash';

  // Default to the recommended "From Original Loan Date" (merge).
  String _interestMode = 'merge';
  MortgageClosePreview? _preview;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.settlementAmount > 0
          ? widget.settlementAmount.toStringAsFixed(0)
          : '',
    );
    _loadPreview();
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await _repo.getClosePreview(widget.loanId);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loadingPreview = false;
        _syncAmount();
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  ClosePolicyFigures? get _figures {
    final p = _preview;
    if (p == null) return null;
    return _interestMode == 'merge' ? p.merge : p.separate;
  }

  void _syncAmount() {
    final f = _figures;
    if (f != null) _amount.text = f.totalPayable.toStringAsFixed(0);
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
        if (_preview?.hasTopups == true) 'topupInterestMode': _interestMode,
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

  String _fmtDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    return d == null ? '-' : DateFormat('dd MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = _preview;
    final hasTopups = preview?.hasTopups == true;

    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.mortgageCloseLoan,
        isSaving: _isSaving,
        saveLabel: l10n.mortgageProceedToClose,
        onSave: _loadingPreview ? null : _save,
        children: [
          if (_loadingPreview)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (hasTopups) ...[
              _infoBanner(context, l10n),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(title: l10n.mortgageSelectInterestOption),
              const SizedBox(height: AppSpacing.sm),
              _optionCard(
                context,
                l10n,
                mode: 'merge',
                title: l10n.mortgageFromOriginalLoanDate,
                description: l10n.mortgageInterestFromOriginalDesc(
                  _fmtDate(preview!.loanDate),
                ),
                dateLabel: l10n.mortgageOriginalLoanDate,
                dateValue: _fmtDate(preview.loanDate),
                figures: preview.merge,
                recommended: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _optionCard(
                context,
                l10n,
                mode: 'separate',
                title: l10n.mortgageFromTopupDate,
                description: l10n.mortgageInterestFromTopupDesc(
                  _fmtDate(preview.firstTopupDate),
                ),
                dateLabel: l10n.mortgageTopupDate,
                dateValue: _fmtDate(preview.firstTopupDate),
                figures: preview.separate,
                recommended: false,
              ),
              const SizedBox(height: AppSpacing.lg),
              _previewCalculation(context, l10n),
              const SizedBox(height: AppSpacing.lg),
            ],
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
        ],
      ),
    );
  }

  Widget _infoBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.mortgageCloseInterestBanner,
              style: TextStyle(color: AppColors.text2(context), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(
    BuildContext context,
    AppLocalizations l10n, {
    required String mode,
    required String title,
    required String description,
    required String dateLabel,
    required String dateValue,
    required ClosePolicyFigures figures,
    required bool recommended,
  }) {
    final selected = _interestMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => setState(() {
        _interestMode = mode;
        _syncAmount();
      }),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfL(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.brd(context),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : AppColors.text3(context),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      l10n.mortgageRecommended,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(color: AppColors.text3(context), fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.sm),
            _kv(context, dateLabel, dateValue),
            _kv(
              context,
              l10n.mortgageTotalTopups,
              mortgageMoney(_preview!.totalTopups),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                l10n.mortgageInterestFromLabel(dateValue),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewCalculation(BuildContext context, AppLocalizations l10n) {
    final f = _figures!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mortgagePreviewCalculation,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          _kv(
            context,
            l10n.mortgagePrincipalOutstanding,
            mortgageMoney(f.outstandingPrincipal),
          ),
          _kv(
            context,
            l10n.mortgageInterestCalculated,
            mortgageMoney(f.pendingInterest),
          ),
          Divider(color: AppColors.brd(context), height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.mortgageTotalPayable,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                mortgageMoney(f.totalPayable),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.text3(context), fontSize: 12.5),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
