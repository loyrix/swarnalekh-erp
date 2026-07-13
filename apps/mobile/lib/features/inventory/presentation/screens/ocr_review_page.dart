import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/categories/application/categories_providers.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen review of HUID-receipt OCR rows before import. Each row picks
/// a category (pre-matched from the scan when possible) that drives the
/// server-generated tag; stone weight is shown explicitly so the gross→net
/// deduction is self-explanatory. The server blocks HUIDs already in stock.
class OcrReviewPage extends ConsumerStatefulWidget {
  const OcrReviewPage({super.key, required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  ConsumerState<OcrReviewPage> createState() => _OcrReviewPageState();
}

class _OcrReviewPageState extends ConsumerState<OcrReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();
  final List<_OcrRow> _rows = [];
  bool _isSaving = false;
  bool _categoriesMatched = false;

  @override
  void initState() {
    super.initState();
    _rows.addAll(widget.rows.map(_OcrRow.fromRow));
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// Pre-select each row's category by matching the scan's guess against the
  /// shop's master list ("Anklet" matches "Anklet (Payal)"). Runs once when
  /// categories arrive; rows the scan couldn't classify stay unselected and
  /// the user picks manually (req §2.3 fallback).
  void _matchDetectedCategories(List<ShopCategory> categories) {
    if (_categoriesMatched) return;
    _categoriesMatched = true;
    for (final row in _rows) {
      final guess = _normalize(row.detectedCategory ?? '');
      if (guess.isEmpty) continue;
      for (final category in categories) {
        if (!category.active) continue;
        if (_normalize(category.name) == guess) {
          row.categoryId = category.id;
          break;
        }
      }
    }
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s*\(.*\)\s*'), '').trim();

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final rows = _rows.map((row) {
      final gross = double.parse(row.grossWeight.text.trim());
      final stone = double.tryParse(row.stoneWeight.text.trim()) ?? 0;
      return {
        'itemName': row.itemName.text.trim(),
        'huid': row.huid.text.trim().isEmpty ? null : row.huid.text.trim(),
        'categoryId': row.categoryId,
        'metalType': row.metalType,
        'karat': row.karat.text.trim().isEmpty ? null : row.karat.text.trim(),
        'grossWeight': gross,
        'netWeight': row.netWeight,
        'stoneWeight': stone > 0 ? stone : null,
        'stockType': 'unique',
        'status': 'in_stock',
        'source': 'ocr',
      };
    }).toList();

    try {
      await _api.dio.post('/inventory/import', data: {'rows': rows});
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      // Surface the server's duplicate-HUID message when present.
      final data = error.response?.data;
      final message = data is Map ? data['message'] : null;
      AppToast.error(
        context,
        message is String && message.isNotEmpty
            ? message
            : l10n.inventoryFailedImportRows,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(context, l10n.inventoryFailedImportRows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    if (categories.isNotEmpty) _matchDetectedCategories(categories);

    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: l10n.inventoryReviewHuidTitle,
        isSaving: _isSaving,
        saveLabel: l10n.inventoryImportItems,
        onSave: _save,
        children: [
          Text(
            l10n.inventoryReviewHuidSubtitle,
            style: TextStyle(color: AppColors.text2(context)),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < _rows.length; i++) ...[
            _OcrRowCard(
              row: _rows[i],
              index: i,
              categories: categories,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _OcrRowCard extends StatelessWidget {
  const _OcrRowCard({
    required this.row,
    required this.index,
    required this.categories,
    required this.onChanged,
  });

  final _OcrRow row;
  final int index;
  final List<ShopCategory> categories;
  final VoidCallback onChanged;

  /// Weight inputs accept plain decimals up to 5 places.
  static final TextInputFormatter _weightFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        return RegExp(r'^\d{0,7}(\.\d{0,5})?$').hasMatch(newValue.text)
            ? newValue
            : oldValue;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.inventoryReviewItemNumber(index + 1),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (row.warnings.isNotEmpty)
                Flexible(
                  child: Text(
                    row.warnings.join(', '),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _field(row.itemName, l10n.inventoryFieldItemName, required: true),
          const SizedBox(height: AppSpacing.sm),
          _categoryDropdown(l10n),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _metalDropdown(context, row, l10n)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _field(row.karat, l10n.inventoryKarat)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _field(
                  row.grossWeight,
                  l10n.inventoryGrossWeight,
                  number: true,
                  required: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _field(
                  row.stoneWeight,
                  l10n.inventoryStoneWeight,
                  number: true,
                  allowZero: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Net is derived (gross − stone) and read-only: the deduction
              // is visible instead of silently applied.
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.inventoryColumnNetWeight,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    row.netWeight > 0 ? _trim(row.netWeight) : '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _field(row.huid, l10n.inventoryHuid),
        ],
      ),
    );
  }

  static String _trim(double value) {
    var text = value.toStringAsFixed(5);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return text;
  }

  Widget _categoryDropdown(AppLocalizations l10n) {
    final selectable = categories
        .where((c) => c.active || c.id == row.categoryId)
        .toList();
    final hasSelection = selectable.any((c) => c.id == row.categoryId);
    return DropdownButtonFormField<String>(
      // Rebuild when the async match fills the selection in.
      key: ValueKey('cat-$index-${row.categoryId ?? ''}'),
      initialValue: hasSelection ? row.categoryId : null,
      decoration: InputDecoration(
        labelText: l10n.inventoryFieldCategory,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      items: [
        for (final category in selectable)
          DropdownMenuItem<String>(
            value: category.id,
            child: Text(
              category.prefix == null
                  ? category.name
                  : '${category.name} (${category.prefix})',
            ),
          ),
      ],
      onChanged: (value) {
        row.categoryId = value;
        onChanged();
      },
      validator: (value) =>
          value == null ? l10n.validationCategoryRequired : null,
    );
  }

  Widget _metalDropdown(
    BuildContext context,
    _OcrRow row,
    AppLocalizations l10n,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: row.metalType,
      decoration: InputDecoration(
        labelText: l10n.inventoryMetal,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      items: [
        DropdownMenuItem(value: 'gold', child: Text(l10n.inventoryMetalGold)),
        DropdownMenuItem(
          value: 'silver',
          child: Text(l10n.inventoryMetalSilver),
        ),
      ],
      onChanged: (value) => row.metalType = value ?? 'gold',
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool required = false,
    bool allowZero = false,
  }) {
    return _OcrField(
      controller: controller,
      label: label,
      number: number,
      required: required,
      allowZero: allowZero,
      formatter: number ? _weightFormatter : null,
      onChanged: number ? (_) => onChanged() : null,
    );
  }
}

class _OcrField extends StatelessWidget {
  const _OcrField({
    required this.controller,
    required this.label,
    required this.number,
    required this.required,
    required this.allowZero,
    this.formatter,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool number;
  final bool required;
  final bool allowZero;
  final TextInputFormatter? formatter;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      inputFormatters: formatter == null ? null : [formatter!],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return l10n.validationRequired;
        if (number && text.isNotEmpty && double.tryParse(text) == null) {
          return l10n.validationEnterNumber;
        }
        if (number && required && (double.tryParse(text) ?? 0) <= 0) {
          return l10n.validationMinGreaterZero;
        }
        if (number &&
            !allowZero &&
            text.isNotEmpty &&
            (double.tryParse(text) ?? 0) <= 0) {
          return l10n.validationMinGreaterZero;
        }
        return null;
      },
    );
  }
}

class _OcrRow {
  final TextEditingController itemName;
  final TextEditingController huid;
  final TextEditingController karat;
  final TextEditingController grossWeight;
  final TextEditingController stoneWeight;
  final List<String> warnings;
  final String? detectedCategory;
  String metalType;
  String? categoryId;

  _OcrRow({
    required this.itemName,
    required this.huid,
    required this.metalType,
    required this.karat,
    required this.grossWeight,
    required this.stoneWeight,
    required this.warnings,
    required this.detectedCategory,
  });

  double get netWeight {
    final gross = double.tryParse(grossWeight.text.trim()) ?? 0;
    final stone = double.tryParse(stoneWeight.text.trim()) ?? 0;
    final net = gross - stone;
    return net > 0 ? net : 0;
  }

  factory _OcrRow.fromRow(Map<String, dynamic> row) {
    final warnings = (row['warnings'] as List<dynamic>? ?? const [])
        .map((warning) => warning.toString())
        .toList();
    return _OcrRow(
      itemName: TextEditingController(text: row['itemName']?.toString() ?? ''),
      huid: TextEditingController(text: row['huid']?.toString() ?? ''),
      metalType: row['metalType']?.toString() ?? 'gold',
      karat: TextEditingController(text: row['karat']?.toString() ?? ''),
      grossWeight: TextEditingController(
        text: row['grossWeight']?.toString() ?? '',
      ),
      stoneWeight: TextEditingController(
        text: row['stoneWeight']?.toString() ?? '',
      ),
      warnings: warnings,
      detectedCategory: row['category']?.toString(),
    );
  }

  void dispose() {
    itemName.dispose();
    huid.dispose();
    karat.dispose();
    grossWeight.dispose();
    stoneWeight.dispose();
  }
}
