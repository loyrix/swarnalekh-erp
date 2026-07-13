import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/categories/data/categories_repository.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Full-screen Add/Edit category form. Returns `true` when saved.
class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({super.key, this.category});

  final ShopCategory? category;

  static Future<bool?> open(BuildContext context, {ShopCategory? category}) {
    return AppFormScaffold.push<bool>(
      context,
      builder: (_) => CategoryFormPage(category: category),
    );
  }

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CategoriesRepository();
  final _name = TextEditingController();
  final _prefix = TextEditingController();
  final _minStock = TextEditingController();
  bool _isSaving = false;
  bool _active = true;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    if (category != null) {
      _name.text = category.name;
      _prefix.text = category.prefix ?? '';
      _minStock.text = category.minStockThreshold.toString();
      _active = category.active;
    } else {
      _minStock.text = '0';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _prefix.dispose();
    _minStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final prefix = _prefix.text.trim().toUpperCase();
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      if (prefix.isNotEmpty) 'prefix': prefix,
      'minStockThreshold': int.tryParse(_minStock.text.trim()) ?? 0,
      if (_isEditing) 'active': _active,
    };

    try {
      await _repo.save(payload, id: widget.category?.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(
        context,
        AppLocalizations.of(context)!.errorFailedSaveCategory,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: AppFormScaffold(
        title: _isEditing ? l10n.categoryEditTitle : l10n.categoryAddTitle,
        isSaving: _isSaving,
        onSave: _save,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.categoryFieldName,
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? l10n.validationCategoryName
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _prefix,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: l10n.categoryFieldPrefix,
              helperText: l10n.categoryPrefixHelp,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return null; // server derives one
              if (text.length < 2) return l10n.validationCategoryPrefix;
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _minStock,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.categoryFieldMinStock,
              helperText: l10n.categoryMinStockHelp,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.commonActive),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        ],
      ),
    );
  }
}
