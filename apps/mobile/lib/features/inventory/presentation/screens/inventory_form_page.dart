import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/inventory/application/inventory_image_payloads.dart';
import 'package:swarnbook/features/inventory/application/inventory_pricing_calculations.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/features/inventory/presentation/inventory_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen Add/Edit Stock form. Replaces the fixed-width AlertDialog so the
/// 15+ field form is fully usable on phones. Returns `true` when saved.
class InventoryFormPage extends StatefulWidget {
  const InventoryFormPage({super.key, this.item});

  final InventoryItem? item;

  /// Opens the form as a full-screen route. Returns `true` if a save occurred.
  static Future<bool?> open(BuildContext context, {InventoryItem? item}) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => InventoryFormPage(item: item),
    );
  }

  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _tagController;
  late final TextEditingController _designNumberController;
  late final TextEditingController _categoryController;
  late final TextEditingController _quantityController;
  late final TextEditingController _grossWeightGramsController;
  late final TextEditingController _grossWeightMgController;
  late final TextEditingController _netWeightGramsController;
  late final TextEditingController _netWeightMgController;
  late final TextEditingController _stoneWeightController;
  late final TextEditingController _stoneValueController;
  late final TextEditingController _purchaseRateController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _makingController;
  late final TextEditingController _locationController;
  late final TextEditingController _photoUrlController;
  late String _metalType;
  late String _stockType;
  String? _karat;
  late String _status;
  late String _makingMode;
  bool _isSaving = false;

  static const List<Map<String, String>> _metalOptions = [
    {'label': 'Gold', 'value': 'gold'},
    {'label': 'Silver', 'value': 'silver'},
  ];

  static const List<Map<String, String>> _stockTypes = [
    {'label': 'Unique Item', 'value': 'unique'},
    {'label': 'Bulk Stock', 'value': 'bulk'},
  ];

  static const Map<String, List<Map<String, String>>> _karatOptions = {
    'gold': [
      {'label': '24K', 'value': '24K'},
      {'label': '22K', 'value': '22K'},
      {'label': '18K', 'value': '18K'},
      {'label': '14K', 'value': '14K'},
      {'label': 'Other', 'value': 'OTHER'},
    ],
    'silver': [
      {'label': 'Fine', 'value': 'FINE'},
      {'label': '925', 'value': '925'},
      {'label': 'Other', 'value': 'OTHER'},
    ],
    'platinum': [
      {'label': 'PT950', 'value': 'PT950'},
      {'label': 'Other', 'value': 'OTHER'},
    ],
    'other': [
      {'label': 'Other', 'value': 'OTHER'},
    ],
  };

  static const List<Map<String, String>> _statusOptions = [
    {'label': 'In Stock', 'value': 'in_stock'},
    {'label': 'Sold', 'value': 'sold'},
    {'label': 'Reserved', 'value': 'reserved'},
  ];

  static const List<Map<String, String>> _makingModes = [
    {'label': 'Per Gram', 'value': inventoryMakingModePerGram},
    {'label': 'Fixed', 'value': inventoryMakingModeFixed},
    {'label': 'Percentage', 'value': inventoryMakingModePercentage},
  ];

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.itemName ?? '');
    _tagController = TextEditingController(text: item?.tagNumber ?? '');
    _designNumberController = TextEditingController(
      text: item?.designNumber ?? '',
    );
    _categoryController = TextEditingController(text: item?.categoryName ?? '');
    _metalType = item?.metalType ?? 'gold';
    _stockType = item?.stockType ?? 'unique';
    _karat = item?.karat;
    _status = item?.status ?? 'in_stock';
    _quantityController = TextEditingController(text: '${item?.quantity ?? 1}');
    final grossWeight = splitInventoryWeight(item?.grossWeight);
    final netWeight = splitInventoryWeight(item?.netWeight);
    _grossWeightGramsController = TextEditingController(
      text: grossWeight.grams,
    );
    _grossWeightMgController = TextEditingController(
      text: grossWeight.milligrams,
    );
    _netWeightGramsController = TextEditingController(text: netWeight.grams);
    _netWeightMgController = TextEditingController(text: netWeight.milligrams);
    _stoneWeightController = TextEditingController(
      text: item?.stoneWeight?.toString() ?? '',
    );
    _stoneValueController = TextEditingController(
      text: item?.stoneValue?.toString() ?? '',
    );
    _purchaseRateController = TextEditingController(
      text: item?.purchaseRate?.toString() ?? '',
    );
    // Dynamic pricing: prefill only an explicit override; a blank field means
    // the item is priced live from the daily rate at bill time.
    _sellingPriceController = TextEditingController(
      text: item?.sellingPrice?.toString() ?? '',
    );
    if (item?.makingChargesPercent != null) {
      _makingMode = inventoryMakingModePercentage;
    } else if (item?.makingChargesFixed != null) {
      _makingMode = inventoryMakingModeFixed;
    } else {
      _makingMode = inventoryMakingModePerGram;
    }
    _makingController = TextEditingController(
      text:
          (item?.makingChargesPercent ??
                  item?.makingChargesPerGram ??
                  item?.makingChargesFixed)
              ?.toString() ??
          '',
    );
    _locationController = TextEditingController(text: item?.location ?? '');
    _photoUrlController = TextEditingController(text: item?.photo ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _designNumberController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _grossWeightGramsController.dispose();
    _grossWeightMgController.dispose();
    _netWeightGramsController.dispose();
    _netWeightMgController.dispose();
    _stoneWeightController.dispose();
    _stoneValueController.dispose();
    _purchaseRateController.dispose();
    _sellingPriceController.dispose();
    _makingController.dispose();
    _locationController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final grossWeight = composeInventoryWeight(
      _grossWeightGramsController.text,
      _grossWeightMgController.text,
    );
    final netWeight = composeInventoryWeight(
      _netWeightGramsController.text,
      _netWeightMgController.text,
    );
    final grossMg = int.tryParse(_grossWeightMgController.text.trim()) ?? 0;
    final netMg = int.tryParse(_netWeightMgController.text.trim()) ?? 0;
    if (grossWeight <= 0 || netWeight <= 0) {
      setState(() => _isSaving = false);
      AppToast.error(context, l10n.validationWeightGreaterThanZero);
      return;
    }
    if (grossMg < 0 || grossMg > 999 || netMg < 0 || netMg > 999) {
      setState(() => _isSaving = false);
      AppToast.error(context, l10n.validationMilligramsRange);
      return;
    }
    if (netWeight > grossWeight) {
      setState(() => _isSaving = false);
      AppToast.error(context, l10n.validationNetWeightGreater);
      return;
    }

    final payload = {
      'itemName': _nameController.text.trim(),
      'tagNumber': _tagController.text.trim().isEmpty
          ? null
          : _tagController.text.trim(),
      'barcode': _designNumberController.text.trim().isEmpty
          ? null
          : _designNumberController.text.trim(),
      'categoryName': _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      'stockType': _stockType,
      'quantity': _stockType == 'bulk'
          ? int.parse(_quantityController.text.trim())
          : 1,
      'metalType': _metalType,
      'karat': _karat == null || _karat == 'OTHER' ? null : _karat,
      'grossWeight': grossWeight,
      'netWeight': netWeight,
      'makingChargesPerGram':
          _makingMode == inventoryMakingModePerGram &&
              _makingController.text.trim().isNotEmpty
          ? double.parse(_makingController.text.trim())
          : null,
      'makingChargesFixed':
          _makingMode == inventoryMakingModeFixed &&
              _makingController.text.trim().isNotEmpty
          ? double.parse(_makingController.text.trim())
          : null,
      'makingChargesPercent':
          _makingMode == inventoryMakingModePercentage &&
              _makingController.text.trim().isNotEmpty
          ? double.parse(_makingController.text.trim())
          : null,
      'stoneWeight': _stoneWeightController.text.trim().isEmpty
          ? null
          : double.parse(_stoneWeightController.text.trim()),
      'stoneValue': _stoneValueController.text.trim().isEmpty
          ? null
          : double.parse(_stoneValueController.text.trim()),
      'purchaseRate': _purchaseRateController.text.trim().isEmpty
          ? null
          : double.parse(_purchaseRateController.text.trim()),
      'sellingPrice': _sellingPriceController.text.trim().isEmpty
          ? null
          : double.parse(_sellingPriceController.text.trim()),
      'photoUrls': _photoUrlController.text.trim().isEmpty
          ? <String>[]
          : [_photoUrlController.text.trim()],
      'status': _status,
      'location': _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    };

    try {
      if (_isEdit) {
        await _api.dio.put('/inventory/${widget.item!.id}', data: payload);
      } else {
        await _api.dio.post('/inventory', data: payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, l10n.errorFailedSaveInventory);
      }
    }
  }

  Future<void> _chooseProductImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1200,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? _mimeTypeForImage(image.name);
    final dataUri = inventoryImageDataUri(bytes: bytes, mimeType: mimeType);
    setState(() => _photoUrlController.text = dataUri);
  }

  void _clearProductImage() => setState(() => _photoUrlController.clear());

  void _syncNetWeightFromGrossAndStone() {
    final grossWeight = composeInventoryWeight(
      _grossWeightGramsController.text,
      _grossWeightMgController.text,
    );
    final stoneWeight =
        double.tryParse(_stoneWeightController.text.trim()) ?? 0;
    final netWeight = calculateInventoryNetWeight(
      grossWeight: grossWeight,
      stoneWeight: stoneWeight,
    );
    final split = splitInventoryWeight(netWeight);
    setState(() {
      _netWeightGramsController.text = split.grams;
      _netWeightMgController.text = split.milligrams;
    });
  }

  // Pricing inputs changed → just refresh the live preview. We intentionally do
  // NOT auto-fill a stored selling price: a blank field prices the item live
  // from the daily rate at bill time (dynamic pricing).
  void _onPricingChanged() => setState(() {});

  void _onSellingPriceChanged(String value) => setState(() {});

  double get _currentNetWeight => composeInventoryWeight(
    _netWeightGramsController.text,
    _netWeightMgController.text,
  );

  double get _currentPurchaseRate =>
      double.tryParse(_purchaseRateController.text.trim()) ?? 0;

  double get _calculatedMakingCharges {
    final value = double.tryParse(_makingController.text.trim()) ?? 0;
    return calculateInventoryMakingCharges(
      netWeight: _currentNetWeight,
      purchasePrice: _currentPurchaseRate,
      makingValue: value,
      makingMode: _makingMode,
    );
  }

  double get _calculatedFinalSellingPrice =>
      calculateInventoryFinalSellingPrice(
        netWeight: _currentNetWeight,
        purchasePrice: _currentPurchaseRate,
        makingCharges: _calculatedMakingCharges,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: _isEdit ? l10n.inventoryEditTitle : l10n.inventoryAddTitle,
        isSaving: _isSaving,
        saveLabel: _isEdit ? l10n.commonUpdate : l10n.commonCreate,
        onSave: _save,
        children: [
          _sectionTitle(l10n.inventoryProductDetails),
          _field(
            _nameController,
            l10n.inventoryFieldItemName,
            requiredMessage: l10n.validationItemNameRequired,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(_tagController, l10n.inventoryFieldTagNumber),
          const SizedBox(height: AppSpacing.md),
          _field(_designNumberController, l10n.inventoryFieldDesignNumber),
          const SizedBox(height: AppSpacing.md),
          _field(_categoryController, l10n.inventoryFieldCategory),
          const SizedBox(height: AppSpacing.md),
          _dropdownField(
            label: l10n.inventoryFieldStockType,
            value: _stockType,
            items: _stockTypes,
            labelBuilder: (value) => _stockTypeLabel(l10n, value),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _stockType = value;
                if (_stockType == 'unique') _quantityController.text = '1';
              });
            },
          ),
          if (_stockType == 'bulk') ...[
            const SizedBox(height: AppSpacing.md),
            _field(
              _quantityController,
              l10n.inventoryFieldQuantity,
              isNumber: true,
              allowDecimal: false,
              requiredMessage: l10n.validationQuantityRequired,
              wholeNumberMessage: l10n.validationWholeNumber,
              minOneMessage: l10n.validationQuantityMinOne,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _dropdownField(
            label: l10n.inventoryFieldMetalType,
            value: _metalType,
            items: _metalOptions,
            labelBuilder: (value) => inventoryMetalLabel(l10n, value),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _metalType = value;
                final validKarats =
                    _karatOptions[_metalType]?.map((e) => e['value']).toSet() ??
                    {};
                if (_karat != null && !validKarats.contains(_karat)) {
                  _karat = null;
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _dropdownField<String?>(
            label: l10n.inventoryFieldKarat,
            value: _karat,
            items: _karatOptions[_metalType] ?? const [],
            labelBuilder: (value) => _karatLabel(l10n, value),
            onChanged: (value) => setState(() => _karat = value),
            // Karat is mandatory so every item matches a daily rate and prices
            // dynamically (prevents ₹0 bills from unmatched rates).
            validator: (value) =>
                value == null ? l10n.validationKaratRequired : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(l10n.inventoryWeightDetails),
          const SizedBox(height: AppSpacing.md),
          _weightRow(
            title: l10n.inventoryFieldGrossWeight,
            gramsController: _grossWeightGramsController,
            mgController: _grossWeightMgController,
            onChanged: (_) => _syncNetWeightFromGrossAndStone(),
          ),
          const SizedBox(height: AppSpacing.md),
          _weightRow(
            title: l10n.inventoryFieldNetWeight,
            gramsController: _netWeightGramsController,
            mgController: _netWeightMgController,
            readOnly: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            _stoneWeightController,
            l10n.inventoryFieldStoneWeight,
            isNumber: true,
            onChanged: (_) => _syncNetWeightFromGrossAndStone(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(l10n.inventoryPriceDetails),
          _field(
            _purchaseRateController,
            l10n.inventoryFieldPurchasePrice,
            isNumber: true,
            onChanged: (_) => _onPricingChanged(),
          ),
          const SizedBox(height: AppSpacing.md),
          _dropdownField(
            label: l10n.inventoryFieldMakingMode,
            value: _makingMode,
            items: _makingModes,
            labelBuilder: (value) => _makingModeLabel(l10n, value),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _makingMode = value;
                _makingController.clear();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            _makingController,
            _makingMode == inventoryMakingModeFixed
                ? l10n.inventoryFixedMaking
                : _makingMode == inventoryMakingModePercentage
                ? l10n.inventoryMakingPercentage
                : l10n.inventoryMakingPerGram,
            isNumber: true,
            onChanged: (_) => _onPricingChanged(),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            _sellingPriceController,
            l10n.inventoryFieldSellingPrice,
            isNumber: true,
            onChanged: _onSellingPriceChanged,
            helperText: l10n.inventorySellingPriceHint,
          ),
          const SizedBox(height: AppSpacing.md),
          _autoCalculationSummary(),
          const SizedBox(height: AppSpacing.lg),
          _field(_locationController, l10n.inventoryFieldBranch),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(l10n.inventoryUploadImage),
          _imageUploadField(),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(l10n.inventoryFormStatus),
          _dropdownField(
            label: l10n.inventoryColumnStatus,
            value: _status,
            items: _statusOptions,
            labelBuilder: (value) => inventoryStatusLabel(l10n, value),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _status = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _imageUploadField() {
    final l10n = AppLocalizations.of(context)!;
    final imageSource = _photoUrlController.text.trim().isEmpty
        ? null
        : _photoUrlController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              inventoryImagePreview(context, imageSource, size: 96),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    PrimaryActionButton.outlined(
                      label: l10n.inventoryChooseProductImage,
                      icon: Icons.photo_library_outlined,
                      onPressed: _chooseProductImage,
                    ),
                    IconButton.filledTonal(
                      tooltip: l10n.inventoryRemoveImage,
                      onPressed: imageSource == null
                          ? null
                          : _clearProductImage,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (imageSource != null && isInventoryDataImage(imageSource))
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.inventoryImageReady,
                    style: TextStyle(
                      color: AppColors.text2(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            TextFormField(
              controller: _photoUrlController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.inventoryFieldImageUrl,
                border: const OutlineInputBorder(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _autoCalculationSummary() {
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      (
        l10n.inventoryCalcNetWeight,
        '${_currentNetWeight.toStringAsFixed(3)} g',
      ),
      (
        l10n.inventoryCalcMakingCharges,
        _currencyValue(_calculatedMakingCharges),
      ),
      (
        l10n.inventoryCalcFinalSellingPrice,
        _currencyValue(_calculatedFinalSellingPrice),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inventoryAutoCalculations,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: TextStyle(color: AppColors.text2(context)),
                    ),
                  ),
                  Text(
                    row.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _currencyValue(double value) => '₹${value.toStringAsFixed(2)}';

  Widget _field(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool allowDecimal = true,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    String? requiredMessage,
    String? wholeNumberMessage,
    String? minOneMessage,
    String? helperText,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.numberWithOptions(decimal: allowDecimal)
          : null,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (requiredMessage != null && text.isEmpty) return requiredMessage;
        if (isNumber && text.isNotEmpty && double.tryParse(text) == null) {
          return l10n.validationValidNumber;
        }
        if (!allowDecimal && text.isNotEmpty && int.tryParse(text) == null) {
          return wholeNumberMessage ?? l10n.validationWholeNumber;
        }
        if (minOneMessage != null &&
            text.isNotEmpty &&
            (int.tryParse(text) ?? 0) < 1) {
          return minOneMessage;
        }
        return null;
      },
    );
  }

  Widget _weightRow({
    required String title,
    required TextEditingController gramsController,
    required TextEditingController mgController,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.text2(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _field(
                gramsController,
                l10n.inventoryGrams,
                isNumber: true,
                allowDecimal: false,
                readOnly: readOnly,
                onChanged: onChanged,
                wholeNumberMessage: l10n.validationWholeNumber,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _field(
                mgController,
                l10n.inventoryMilligrams,
                isNumber: true,
                allowDecimal: false,
                readOnly: readOnly,
                onChanged: onChanged,
                wholeNumberMessage: l10n.validationWholeNumber,
              ),
            ),
          ],
        ),
      ],
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

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<Map<String, String>> items,
    required ValueChanged<T?> onChanged,
    String Function(dynamic value)? labelBuilder,
    bool allowEmpty = false,
    String? Function(T?)? validator,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final dropdownItems = <DropdownMenuItem<T>>[
      if (allowEmpty)
        DropdownMenuItem<T>(value: null, child: Text(l10n.commonNotSet)),
      ...items.map(
        (item) => DropdownMenuItem<T>(
          value: item['value'] as T,
          child: Text(labelBuilder?.call(item['value']) ?? item['label']!),
        ),
      ),
    ];

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: dropdownItems,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String _stockTypeLabel(AppLocalizations l10n, dynamic value) {
    return switch ((value ?? '').toString()) {
      'bulk' => l10n.inventoryStockTypeBulk,
      'unique' => l10n.inventoryStockTypeUnique,
      _ => '—',
    };
  }

  String _karatLabel(AppLocalizations l10n, dynamic value) {
    return switch ((value ?? '').toString()) {
      'OTHER' => l10n.inventoryMetalOther,
      'FINE' => l10n.ratesFineSilver,
      _ => (value ?? '').toString(),
    };
  }

  String _makingModeLabel(AppLocalizations l10n, dynamic value) {
    return switch ((value ?? '').toString()) {
      'per_gram' => l10n.inventoryMakingModePerGram,
      'fixed' => l10n.inventoryMakingModeFixed,
      'percentage' => l10n.inventoryMakingModePercentage,
      _ => '—',
    };
  }
}
