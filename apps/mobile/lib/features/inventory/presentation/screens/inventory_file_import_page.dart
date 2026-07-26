import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/categories/application/categories_providers.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
import 'package:swarnbook/features/inventory/application/inventory_import_parser.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Imports inventory from a CSV/Excel file exported by another jewellery ERP.
/// The file is parsed on-device; columns are auto-mapped (editable), rows are
/// validated (weights, metal, duplicate tags), and the reviewed rows are sent
/// to the existing `/inventory/import` endpoint — which preserves supplied tag
/// numbers, generates tags only for rows without one, and 409s on a tag that
/// is already in stock.
class InventoryFileImportPage extends ConsumerStatefulWidget {
  const InventoryFileImportPage({super.key});

  @override
  ConsumerState<InventoryFileImportPage> createState() =>
      _InventoryFileImportPageState();
}

class _InventoryFileImportPageState
    extends ConsumerState<InventoryFileImportPage> {
  final ApiClient _api = ApiClient();

  String? _fileName;
  ParsedSheet? _sheet;
  Map<ImportField, int> _mapping = {};
  bool _importing = false;

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null || file.bytes == null) return;

      final name = file.name;
      final sheet = name.toLowerCase().endsWith('.xlsx')
          ? parseXlsxSheet(file.bytes!)
          : parseCsvSheet(utf8.decode(file.bytes!, allowMalformed: true));

      if (sheet.isEmpty) {
        if (mounted) AppToast.error(context, l10n.inventoryImportEmptyFile);
        return;
      }
      setState(() {
        _fileName = name;
        _sheet = sheet;
        _mapping = autoDetectMapping(sheet.headers);
      });
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.inventoryImportParseFailed);
    }
  }

  /// Column value for a field, or null when unmapped.
  int? _col(ImportField f) => _mapping[f];

  void _setColumn(ImportField f, int? column) {
    setState(() {
      // Keep the mapping one-to-one: free the column from any other field.
      if (column != null) {
        _mapping.removeWhere((key, value) => value == column && key != f);
      }
      if (column == null) {
        _mapping.remove(f);
      } else {
        _mapping[f] = column;
      }
    });
  }

  List<ImportRowResult> get _rows {
    final sheet = _sheet;
    if (sheet == null) return const [];
    return sheet.rows.map((r) => buildImportRow(r, _mapping)).toList();
  }

  /// Resolves a category name to an existing category id (case-insensitive,
  /// ignoring a parenthetical suffix like "Anklet (Payal)").
  String? _categoryId(String? name, List<ShopCategory> categories) {
    if (name == null) return null;
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'\s*\(.*\)\s*'), '').trim();
    final target = norm(name);
    for (final c in categories) {
      if (norm(c.name) == target) return c.id;
    }
    return null;
  }

  Future<void> _import(List<ShopCategory> categories) async {
    final l10n = AppLocalizations.of(context)!;
    final results = _rows;
    final valid = results.where((r) => r.isValid).toList();
    if (valid.isEmpty) {
      AppToast.error(context, l10n.inventoryImportNoValidRows);
      return;
    }

    final rows = valid.map((r) {
      final payload = Map<String, dynamic>.from(r.payload!);
      final categoryName = payload.remove('categoryName') as String?;
      final id = _categoryId(categoryName, categories);
      if (id != null) payload['categoryId'] = id;
      return payload;
    }).toList();

    setState(() => _importing = true);
    try {
      await _api.dio.post('/inventory/import', data: {'rows': rows});
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _importing = false);
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
      setState(() => _importing = false);
      AppToast.error(context, l10n.inventoryFailedImportRows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final sheet = _sheet;
    final results = _rows;
    final validCount = results.where((r) => r.isValid).length;
    final errorCount = results.length - validCount;

    final tags = results
        .where((r) => r.isValid)
        .map((r) => r.payload!['tagNumber'] as String?);
    final dupTags = duplicateTagsInFile(tags);

    return AppFormScaffold(
      title: l10n.inventoryImportFile,
      isSaving: _importing,
      saveLabel: l10n.inventoryImportItems,
      onSave: sheet == null || validCount == 0 || dupTags.isNotEmpty
          ? null
          : () => _import(categories),
      children: [
        Text(
          l10n.inventoryImportFileHelp,
          style: TextStyle(color: AppColors.text2(context)),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _importing ? null : _pickFile,
          icon: const Icon(Icons.folder_open_outlined),
          label: Text(_fileName ?? l10n.inventoryImportChooseFile),
        ),
        if (sheet != null) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.inventoryImportMapColumns),
          const SizedBox(height: AppSpacing.sm),
          for (final field in ImportField.values)
            _mappingRow(l10n, sheet, field),
          const SizedBox(height: AppSpacing.lg),
          _summary(l10n, validCount, errorCount, dupTags),
          if (errorCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _errorList(l10n, results),
          ],
        ],
      ],
    );
  }

  Widget _mappingRow(
    AppLocalizations l10n,
    ParsedSheet sheet,
    ImportField field,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _fieldLabel(l10n, field) + (field.required ? ' *' : ''),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int?>(
              initialValue: _col(field),
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.inventoryImportSkipColumn),
                ),
                for (var i = 0; i < sheet.headers.length; i++)
                  DropdownMenuItem<int?>(
                    value: i,
                    child: Text(
                      sheet.headers[i].isEmpty
                          ? 'Column ${i + 1}'
                          : sheet.headers[i],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => _setColumn(field, v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
    AppLocalizations l10n,
    int valid,
    int errors,
    Set<String> dupTags,
  ) {
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
          Text(
            l10n.inventoryImportSummary(valid, errors),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (dupTags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.inventoryImportDuplicateTags(dupTags.length),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorList(AppLocalizations l10n, List<ImportRowResult> results) {
    final rows = <Widget>[];
    for (var i = 0; i < results.length; i++) {
      if (results[i].isValid) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            l10n.inventoryImportRowError(i + 2, results[i].errors.join(', ')),
            style: TextStyle(fontSize: 12, color: AppColors.text2(context)),
          ),
        ),
      );
      if (rows.length >= 20) break; // cap the on-screen list
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  String _fieldLabel(AppLocalizations l10n, ImportField field) =>
      switch (field) {
        ImportField.tagNumber => l10n.inventoryFieldTagNumber,
        ImportField.itemName => l10n.inventoryFieldItemName,
        ImportField.categoryName => l10n.inventoryFieldCategory,
        ImportField.metalType => l10n.inventoryMetal,
        ImportField.karat => l10n.inventoryKarat,
        ImportField.grossWeight => l10n.inventoryGrossWeight,
        ImportField.netWeight => l10n.inventoryColumnNetWeight,
        ImportField.quantity => l10n.billingQty,
        ImportField.sellingPrice => l10n.billingPrice,
        ImportField.huid => l10n.inventoryHuid,
      };
}
