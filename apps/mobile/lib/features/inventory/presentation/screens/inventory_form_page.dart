import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/categories/application/categories_providers.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
import 'package:swarnbook/features/inventory/application/inventory_image_payloads.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/features/inventory/presentation/inventory_format.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen Add/Edit Stock form. Stock intake only: identity (category →
/// auto tag), metal, weights in decimal grams, and a photo — no pricing here
/// (items price dynamically from the daily rate at bill time) and no
/// per-item branch. Returns `true` when saved.
class InventoryFormPage extends ConsumerStatefulWidget {
  const InventoryFormPage({super.key, this.item});

  final InventoryItem? item;

  /// Opens the form as a full-screen route. Returns `true` if a save occurred.
  static Future<bool?> open(BuildContext context, {InventoryItem? item}) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => InventoryFormPage(item: item),
    );
  }

  /// Item name = category name, with the optional details in parentheses.
  static String composeItemName(String categoryName, String details) {
    final d = details.trim();
    return d.isEmpty ? categoryName : '$categoryName ($d)';
  }

  /// Extracts the optional details part from a stored name given its category
  /// ("Chain (Hollow Rope)" → "Hollow Rope"; "Chain" → ""; anything else is
  /// shown verbatim so nothing is hidden from the user).
  static String detailsFromName(String? name, String? categoryName) {
    final n = name?.trim() ?? '';
    final c = categoryName?.trim() ?? '';
    if (n.isEmpty) return '';
    if (c.isEmpty) return n;
    if (n == c) return '';
    if (n.startsWith('$c (') && n.endsWith(')')) {
      return n.substring(c.length + 2, n.length - 1);
    }
    return n;
  }

  @override
  ConsumerState<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends ConsumerState<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _tagController;
  String? _originalItemName;
  late final TextEditingController _quantityController;
  late final TextEditingController _grossWeightController;
  late final TextEditingController _stoneWeightController;
  late final TextEditingController _netWeightController;
  String? _categoryId;
  late String _metalType;
  late String _stockType;
  String? _karat;
  late String _status;
  String _photoData = '';
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

  /// Weight inputs accept plain decimals up to 5 places (owner decision:
  /// 10.505 g, not separate gm/mg fields).
  static final TextInputFormatter _weightFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        return RegExp(r'^\d{0,7}(\.\d{0,5})?$').hasMatch(newValue.text)
            ? newValue
            : oldValue;
      });

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    // The name is derived from the category ("Chain" / "Chain (Hollow Rope)");
    // the field only edits the optional details part. Parse an existing name
    // back into details using the item's category name.
    _nameController = TextEditingController(
      text: InventoryFormPage.detailsFromName(
        item?.itemName,
        item?.categoryName,
      ),
    );
    _originalItemName = item?.itemName;
    _tagController = TextEditingController();
    _categoryId = item?.categoryId;
    _metalType = item?.metalType ?? 'gold';
    _stockType = item?.stockType ?? 'unique';
    _karat = item?.karat;
    _status = item?.status ?? 'in_stock';
    _quantityController = TextEditingController(text: '${item?.quantity ?? 1}');
    // No pre-filled zeros: a new form starts blank.
    _grossWeightController = TextEditingController(
      text: _weightText(item?.grossWeight),
    );
    _stoneWeightController = TextEditingController(
      text: _weightText(item?.stoneWeight),
    );
    _netWeightController = TextEditingController(
      text: _weightText(item?.netWeight),
    );
    _photoData = item?.photo ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _quantityController.dispose();
    _grossWeightController.dispose();
    _stoneWeightController.dispose();
    _netWeightController.dispose();
    super.dispose();
  }

  static String _weightText(double? value) {
    if (value == null || value == 0) return '';
    var text = value.toStringAsFixed(5);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return text;
  }

  double get _grossWeight =>
      double.tryParse(_grossWeightController.text.trim()) ?? 0;
  double get _stoneWeight =>
      double.tryParse(_stoneWeightController.text.trim()) ?? 0;

  /// Net weight is derived, never typed: gross − stone.
  double get _netWeight {
    final net = _grossWeight - _stoneWeight;
    return net > 0 ? net : 0;
  }

  void _syncNetWeight() {
    setState(() => _netWeightController.text = _weightText(_netWeight));
  }

  String? _selectedCategoryName() {
    final categories = ref.read(categoriesProvider).valueOrNull;
    if (categories != null) {
      for (final c in categories) {
        if (c.id == _categoryId) return c.name;
      }
    }
    // Fallback when the list isn't loaded but the item already carries it.
    if (_isEdit && widget.item?.categoryId == _categoryId) {
      return widget.item?.categoryName;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_categoryId == null) {
      AppToast.error(context, l10n.validationCategoryRequired);
      return;
    }
    if (_grossWeight <= 0) {
      AppToast.error(context, l10n.validationWeightGreaterThanZero);
      return;
    }
    if (_stoneWeight >= _grossWeight) {
      AppToast.error(context, l10n.validationStoneExceedsGross);
      return;
    }
    final categoryName = _selectedCategoryName();
    if (categoryName == null) {
      AppToast.error(context, l10n.validationCategoryRequired);
      return;
    }
    final details = _nameController.text.trim();
    // If the details still parse-match the original name under the selected
    // category, keep the stored name untouched (legacy names round-trip);
    // otherwise compose "<Category> (<details>)".
    final original = _originalItemName?.trim();
    final itemName =
        (_isEdit &&
            original != null &&
            original.isNotEmpty &&
            InventoryFormPage.detailsFromName(original, categoryName) ==
                details)
        ? original
        : InventoryFormPage.composeItemName(categoryName, details);
    setState(() => _isSaving = true);

    final tagNumber = _tagController.text.trim();
    final payload = {
      'itemName': itemName,
      'categoryId': _categoryId,
      // A typed tag wins ("2" → "PD-0002" server-side); blank = auto sequence.
      if (!_isEdit && tagNumber.isNotEmpty) 'tagNumber': tagNumber,
      'stockType': _stockType,
      'quantity': _stockType == 'bulk'
          ? int.parse(_quantityController.text.trim())
          : 1,
      'metalType': _metalType,
      'karat': _karat == null || _karat == 'OTHER' ? null : _karat,
      'grossWeight': _grossWeight,
      'netWeight': _netWeight,
      'stoneWeight': _stoneWeight > 0 ? _stoneWeight : null,
      'photoUrls': _photoData.isEmpty ? <String>[] : [_photoData],
      'status': _status,
    };

    try {
      if (_isEdit) {
        await _api.dio.put('/inventory/${widget.item!.id}', data: payload);
      } else {
        await _api.dio.post('/inventory', data: payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        // Surface the server's reason (e.g. validation / payload errors)
        // instead of a generic failure.
        final serverMessage = e is DioException ? e.message?.trim() : null;
        AppToast.error(
          context,
          (serverMessage == null || serverMessage.isEmpty)
              ? l10n.errorFailedSaveInventory
              : serverMessage,
        );
      }
    }
  }

  Future<void> _pickProductImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 1200,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? _mimeTypeForImage(image.name);
    final dataUri = inventoryImageDataUri(bytes: bytes, mimeType: mimeType);
    setState(() => _photoData = dataUri);
  }

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
          _categoryDropdown(l10n),
          const SizedBox(height: AppSpacing.md),
          // Optional variant/details — the item name itself derives from the
          // category ("Chain (Hollow Rope)"), so nothing is typed twice.
          _field(
            _nameController,
            l10n.inventoryFieldDetails,
            helperText: l10n.inventoryDetailsHint,
          ),
          if (_isEdit && widget.item?.tagNumber != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: widget.item!.tagNumber,
              enabled: false,
              decoration: InputDecoration(
                labelText: l10n.inventoryFieldTagNumber,
                border: const OutlineInputBorder(),
              ),
            ),
          ] else if (!_isEdit) ...[
            const SizedBox(height: AppSpacing.md),
            // Optional: leave blank for an auto sequence (RG-0001), type an
            // existing physical tag, or just a number ("2" → "PD-0002").
            _field(
              _tagController,
              l10n.inventoryFieldTagNumber,
              helperText: l10n.inventoryTagNumberHint,
            ),
          ],
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
          _weightField(
            _grossWeightController,
            l10n.inventoryFieldGrossWeight,
            requiredMessage: l10n.validationWeightGreaterThanZero,
            onChanged: (_) => _syncNetWeight(),
          ),
          const SizedBox(height: AppSpacing.md),
          _weightField(
            _stoneWeightController,
            l10n.inventoryFieldStoneWeight,
            onChanged: (_) => _syncNetWeight(),
          ),
          const SizedBox(height: AppSpacing.md),
          _weightField(
            _netWeightController,
            l10n.inventoryFieldNetWeight,
            readOnly: true,
            helperText: l10n.inventoryNetWeightHint,
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(l10n.inventoryUploadImage),
          _imageRow(l10n),
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

  /// Category comes from the shop's master list; the server assigns the next
  /// RG-01-style tag for it on save.
  Widget _categoryDropdown(AppLocalizations l10n) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        final selectable = categories
            .where((c) => c.active || c.id == _categoryId)
            .toList();
        final hasSelection = selectable.any((c) => c.id == _categoryId);
        return DropdownButtonFormField<String>(
          initialValue: hasSelection ? _categoryId : null,
          items: [
            for (final ShopCategory category in selectable)
              DropdownMenuItem<String>(
                value: category.id,
                child: Text(
                  category.prefix == null
                      ? category.name
                      : '${category.name} (${category.prefix})',
                ),
              ),
          ],
          onChanged: (value) => setState(() => _categoryId = value),
          validator: (value) =>
              value == null ? l10n.validationCategoryRequired : null,
          decoration: InputDecoration(
            labelText: l10n.inventoryFieldCategory,
            helperText: _isEdit ? null : l10n.inventoryTagAutoHint,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
        );
      },
      loading: () => TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: l10n.inventoryFieldCategory,
          helperText: l10n.commonLoading,
          border: const OutlineInputBorder(),
        ),
      ),
      error: (_, _) => TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: l10n.inventoryFieldCategory,
          helperText: l10n.commonErrorTitle,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(categoriesProvider),
          ),
        ),
      ),
    );
  }

  /// Compact photo row: thumbnail + gallery/camera/remove — no URL input,
  /// no oversized panel.
  Widget _imageRow(AppLocalizations l10n) {
    final imageSource = _photoData.isEmpty ? null : _photoData;
    return Row(
      children: [
        inventoryImagePreview(context, imageSource, size: 56),
        const SizedBox(width: AppSpacing.md),
        IconButton.filledTonal(
          tooltip: l10n.inventoryChooseProductImage,
          onPressed: () => _pickProductImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filledTonal(
          tooltip: l10n.inventoryTakePhoto,
          onPressed: () => _pickProductImage(ImageSource.camera),
          icon: const Icon(Icons.photo_camera_outlined),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filledTonal(
          tooltip: l10n.inventoryRemoveImage,
          onPressed: imageSource == null
              ? null
              : () => setState(() => _photoData = ''),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        if (imageSource != null) ...[
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ],
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

  Widget _weightField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    String? requiredMessage,
    String? helperText,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: readOnly ? null : [_weightFormatter],
      decoration: InputDecoration(
        labelText: label,
        suffixText: l10n.inventoryGramsSuffix,
        helperText: helperText,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (requiredMessage != null &&
            (text.isEmpty || (double.tryParse(text) ?? 0) <= 0)) {
          return requiredMessage;
        }
        if (text.isNotEmpty && double.tryParse(text) == null) {
          return l10n.validationValidNumber;
        }
        return null;
      },
    );
  }

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
}
