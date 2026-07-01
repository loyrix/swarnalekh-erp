import 'package:flutter/material.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen review of HUID-receipt OCR rows before import.
/// Replaces the old horizontally-scrolling DataTable dialog with stacked,
/// touch-friendly cards inside an [AppFormScaffold].
class OcrReviewPage extends StatefulWidget {
  const OcrReviewPage({super.key, required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  State<OcrReviewPage> createState() => _OcrReviewPageState();
}

class _OcrReviewPageState extends State<OcrReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();
  final List<_OcrRow> _rows = [];
  bool _isSaving = false;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final rows = _rows.map((row) {
      final quantity = int.tryParse(row.quantity.text.trim()) ?? 1;
      return {
        'itemName': row.itemName.text.trim(),
        'tagNumber': null,
        'huid': row.huid.text.trim().isEmpty ? null : row.huid.text.trim(),
        'hallmarkNumber': row.hallmark.text.trim().isEmpty
            ? null
            : row.hallmark.text.trim(),
        'metalType': row.metalType,
        'karat': row.karat.text.trim().isEmpty ? null : row.karat.text.trim(),
        'grossWeight': double.parse(row.grossWeight.text.trim()),
        'netWeight': double.parse(row.netWeight.text.trim()),
        'quantity': quantity,
        'stockType': quantity > 1 ? 'bulk' : 'unique',
        'status': 'in_stock',
        'source': 'ocr',
      };
    }).toList();

    try {
      await _api.dio.post('/inventory/import', data: {'rows': rows});
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        AppLocalizations.of(context)!.inventoryFailedImportRows,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            _OcrRowCard(row: _rows[i], index: i),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _OcrRowCard extends StatelessWidget {
  const _OcrRowCard({required this.row, required this.index});

  final _OcrRow row;
  final int index;

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
                  row.netWeight,
                  l10n.inventoryColumnNetWeight,
                  number: true,
                  required: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _field(
                  row.quantity,
                  l10n.inventoryQuantity,
                  integer: true,
                  required: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _field(row.huid, l10n.inventoryHuid)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _field(row.hallmark, l10n.inventoryHallmark)),
            ],
          ),
        ],
      ),
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
    bool integer = false,
    bool required = false,
  }) {
    return _OcrField(
      controller: controller,
      label: label,
      number: number,
      integer: integer,
      required: required,
    );
  }
}

class _OcrField extends StatelessWidget {
  const _OcrField({
    required this.controller,
    required this.label,
    required this.number,
    required this.integer,
    required this.required,
  });

  final TextEditingController controller;
  final String label;
  final bool number;
  final bool integer;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: number || integer
          ? TextInputType.numberWithOptions(decimal: !integer)
          : null,
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
        if (integer && int.tryParse(text) == null) {
          return l10n.validationEnterNumber;
        }
        if (number && double.tryParse(text) == null) {
          return l10n.validationEnterNumber;
        }
        if (integer && (int.tryParse(text) ?? 0) < 1) {
          return l10n.validationMinQuantity;
        }
        if (number && (double.tryParse(text) ?? 0) <= 0) {
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
  final TextEditingController hallmark;
  final TextEditingController karat;
  final TextEditingController grossWeight;
  final TextEditingController netWeight;
  final TextEditingController quantity;
  final List<String> warnings;
  String metalType;

  _OcrRow({
    required this.itemName,
    required this.huid,
    required this.hallmark,
    required this.metalType,
    required this.karat,
    required this.grossWeight,
    required this.netWeight,
    required this.quantity,
    required this.warnings,
  });

  factory _OcrRow.fromRow(Map<String, dynamic> row) {
    final warnings = (row['warnings'] as List<dynamic>? ?? const [])
        .map((warning) => warning.toString())
        .toList();
    return _OcrRow(
      itemName: TextEditingController(text: row['itemName']?.toString() ?? ''),
      huid: TextEditingController(text: row['huid']?.toString() ?? ''),
      hallmark: TextEditingController(
        text: row['hallmarkNumber']?.toString() ?? '',
      ),
      metalType: row['metalType']?.toString() ?? 'gold',
      karat: TextEditingController(text: row['karat']?.toString() ?? ''),
      grossWeight: TextEditingController(
        text: row['grossWeight']?.toString() ?? '',
      ),
      netWeight: TextEditingController(
        text: row['netWeight']?.toString() ?? '',
      ),
      quantity: TextEditingController(text: row['quantity']?.toString() ?? '1'),
      warnings: warnings,
    );
  }

  void dispose() {
    itemName.dispose();
    huid.dispose();
    hallmark.dispose();
    karat.dispose();
    grossWeight.dispose();
    netWeight.dispose();
    quantity.dispose();
  }
}
