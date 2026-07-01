import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/application/mortgage_receipt_payloads.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_form_helpers.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen Add Mortgage form (Customer / Verification / Gold / Loan).
/// Returns `true` when a loan is created.
class MortgageFormPage extends StatefulWidget {
  const MortgageFormPage({super.key});

  static Future<bool?> open(BuildContext context) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => const MortgageFormPage(),
    );
  }

  @override
  State<MortgageFormPage> createState() => _MortgageFormPageState();
}

class _MortgageFormPageState extends State<MortgageFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MortgageRepository();
  final ImagePicker _imagePicker = ImagePicker();

  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _customerAddress = TextEditingController();
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();
  final _ornamentType = TextEditingController();
  final _grossWeight = TextEditingController();
  final _netWeight = TextEditingController();
  final _loanAmount = TextEditingController();
  final _interestRate = TextEditingController(text: '2');
  final _loanDate = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _notes = TextEditingController();
  bool _isSaving = false;
  String _purity = '22K';
  String? _photoIdUrl;
  String? _customerPhotoUrl;

  @override
  void dispose() {
    for (final c in [
      _customerName,
      _customerPhone,
      _customerAddress,
      _aadhaar,
      _pan,
      _ornamentType,
      _grossWeight,
      _netWeight,
      _loanAmount,
      _interestRate,
      _loanDate,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseImage(String target) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1200,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final dataUri = verificationImageDataUri(
      bytes: bytes,
      mimeType: image.mimeType ?? _mimeTypeForImage(image.name),
    );
    setState(() {
      if (target == 'photoId') {
        _photoIdUrl = dataUri;
      } else {
        _customerPhotoUrl = dataUri;
      }
    });
  }

  Future<void> _pickLoanDate() async {
    final current = _parseLoanDate(_loanDate.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _loanDate.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final grossWeight = mortgageNumber(_grossWeight.text);
    final netWeight = mortgageNumber(_netWeight.text);
    final loanDate = _parseLoanDate(_loanDate.text);
    if (loanDate == null) {
      AppToast.error(context, l10n.mortgageEnterValidLoanDate);
      return;
    }
    if (netWeight > grossWeight) {
      AppToast.error(context, l10n.mortgageNetWeightExceedsGross);
      return;
    }

    setState(() => _isSaving = true);
    final payload = {
      'customerName': _customerName.text.trim(),
      'customerPhone': mortgageEmptyToNull(_customerPhone.text),
      'customerAddress': mortgageEmptyToNull(_customerAddress.text),
      'aadhaarNumber': mortgageEmptyToNull(_aadhaar.text),
      'panNumber': mortgageEmptyToNull(_pan.text),
      'photoIdUrl': _photoIdUrl,
      'customerPhotoUrl': _customerPhotoUrl,
      'principalAmount': mortgageNumber(_loanAmount.text),
      'interestRateMonthly': mortgageNumber(_interestRate.text),
      'loanDate': loanDate.toIso8601String(),
      'notes': mortgageEmptyToNull(_notes.text),
      'ornaments': [
        {
          'ornamentType': _ornamentType.text.trim(),
          'purity': _purity,
          'grossWeight': grossWeight,
          'netWeight': netWeight,
        },
      ],
    };

    try {
      await _repo.createLoan(payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        mortgageErrorMessage(error, l10n.mortgageFailedCreate),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.mortgageAddTitle,
        isSaving: _isSaving,
        saveLabel: l10n.mortgageSaveLoan,
        onSave: _save,
        children: [
          mortgageSectionTitle(context, l10n.mortgageCustomerDetails),
          mortgageField(
            context,
            _customerName,
            l10n.mortgageCustomerName,
            required: true,
          ),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _customerPhone, l10n.mortgageMobileNumber),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _customerAddress, l10n.mortgageAddress),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _aadhaar, l10n.mortgageAadhaarNumber),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _pan, l10n.mortgagePanNumber),
          const SizedBox(height: AppSpacing.lg),
          mortgageSectionTitle(context, l10n.mortgageCustomerVerification),
          _imageField(
            label: l10n.mortgagePhotoId,
            hasImage: _photoIdUrl != null,
            onChoose: () => _chooseImage('photoId'),
            onClear: () => setState(() => _photoIdUrl = null),
          ),
          const SizedBox(height: AppSpacing.md),
          _imageField(
            label: l10n.mortgageCustomerPhoto,
            hasImage: _customerPhotoUrl != null,
            onChoose: () => _chooseImage('customerPhoto'),
            onClear: () => setState(() => _customerPhotoUrl = null),
          ),
          const SizedBox(height: AppSpacing.lg),
          mortgageSectionTitle(context, l10n.mortgageGoldDetails),
          mortgageField(
            context,
            _ornamentType,
            l10n.mortgageOrnamentType,
            required: true,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _purity,
            decoration: InputDecoration(labelText: l10n.mortgagePurity),
            items: const [
              '18K',
              '22K',
              '24K',
              'Silver 925',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _purity = v ?? '22K'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: mortgageField(
                  context,
                  _grossWeight,
                  l10n.mortgageGrossWeight,
                  required: true,
                  numeric: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: mortgageField(
                  context,
                  _netWeight,
                  l10n.mortgageNetWeight,
                  required: true,
                  numeric: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          mortgageSectionTitle(context, l10n.mortgageLoanDetails),
          mortgageField(
            context,
            _loanAmount,
            l10n.mortgageLoanAmount,
            required: true,
            numeric: true,
          ),
          const SizedBox(height: AppSpacing.md),
          mortgageField(
            context,
            _interestRate,
            l10n.mortgageMonthlyInterestRate,
            required: true,
            numeric: true,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _loanDate,
            readOnly: true,
            decoration: InputDecoration(
              labelText: l10n.mortgageLoanDate,
              suffixIcon: IconButton(
                tooltip: l10n.mortgageSelectLoanDate,
                onPressed: _pickLoanDate,
                icon: const Icon(Icons.calendar_today_outlined),
              ),
            ),
            validator: (value) => _parseLoanDate(value ?? '') == null
                ? l10n.mortgageRequired
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          mortgageField(context, _notes, l10n.commonNotes),
        ],
      ),
    );
  }

  Widget _imageField({
    required String label,
    required bool hasImage,
    required VoidCallback onChoose,
    required VoidCallback onClear,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasImage
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.surf(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.brd(context)),
            ),
            child: Icon(
              hasImage
                  ? Icons.check_circle_outline_rounded
                  : Icons.add_photo_alternate_outlined,
              color: hasImage ? AppColors.success : AppColors.text3(context),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  hasImage ? l10n.mortgageSelected : l10n.mortgageChooseImage,
                  style: TextStyle(color: AppColors.text3(context)),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onChoose,
            icon: const Icon(Icons.photo_library_outlined),
          ),
          IconButton(
            onPressed: hasImage ? onClear : null,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  String _mimeTypeForImage(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  DateTime? _parseLoanDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse('${trimmed}T00:00:00.000Z');
  }
}
