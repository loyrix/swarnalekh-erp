import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/categories/application/categories_providers.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
import 'package:swarnbook/features/categories/presentation/screens/category_form_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// Admin settings: the category master list driving tag prefixes (RG-01…)
/// and per-category minimum-stock thresholds.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _api = ApiClient();
  final _searchController = TextEditingController();
  String _search = '';
  bool _roleLoaded = false;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchCurrentUserRole(_api);
      if (!mounted) return;
      setState(() {
        _canManage = isAdminRole(role);
        _roleLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _roleLoaded = true);
    }
  }

  Future<void> _openForm({ShopCategory? category}) async {
    final changed = await CategoryFormPage.open(context, category: category);
    if (changed == true && mounted) ref.invalidate(categoriesProvider);
  }

  Future<void> _delete(ShopCategory category) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoryDeleteTitle),
        content: Text(l10n.categoryDeleteConfirm(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(categoriesRepositoryProvider).delete(category.id);
      if (!mounted) return;
      AppToast.success(context, l10n.categoryDeleted);
      ref.invalidate(categoriesProvider);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.errorFailedDeleteCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_roleLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_canManage) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: l10n.userRestrictedTitle,
        subtitle: l10n.userRestrictedSubtitle,
        iconColor: AppColors.warning,
      );
    }

    final async = ref.watch(categoriesProvider);
    return AppStateView<List<ShopCategory>>(
      value: async,
      onRetry: () => ref.invalidate(categoriesProvider),
      data: (categories) {
        final query = _search.trim().toLowerCase();
        final filtered = query.isEmpty
            ? categories
            : categories
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(query) ||
                        (c.prefix ?? '').toLowerCase().contains(query),
                  )
                  .toList();

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(categoriesProvider.future),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: l10n.categorySearchHint,
                          isDense: true,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      tooltip: l10n.categoryAddTitle,
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.categoryNoResults,
                          style: TextStyle(color: AppColors.text3(context)),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _row(l10n, filtered[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(AppLocalizations l10n, ShopCategory category) {
    final isLow = category.inStockCount <= category.minStockThreshold;
    return CompactDataRow(
      leading: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          category.prefix ?? '—',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      title: category.name,
      subtitle: category.prefix == null
          ? l10n.categoryNoPrefix
          : l10n.categoryTagPreview('${category.prefix}-01'),
      metrics: [
        (l10n.categoryInStock, '${category.inStockCount}'),
        (l10n.categoryFieldMinStock, '${category.minStockThreshold}'),
      ],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!category.active)
            StatusBadge(
              label: l10n.categoryStatusInactive,
              color: AppColors.warning,
            )
          else if (isLow)
            StatusBadge(label: l10n.categoryStatusLow, color: AppColors.error),
          ItemActionsMenu(
            actions: [
              ItemAction(
                type: ItemActionType.edit,
                onPressed: () => _openForm(category: category),
              ),
              if (category.itemCount == 0)
                ItemAction(
                  type: ItemActionType.delete,
                  onPressed: () => _delete(category),
                  isDestructive: true,
                ),
            ],
          ),
        ],
      ),
      onTap: () => _openForm(category: category),
    );
  }
}
