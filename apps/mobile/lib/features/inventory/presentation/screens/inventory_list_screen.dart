import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/inventory/application/inventory_providers.dart';
import 'package:swarnbook/features/inventory/data/inventory_repository.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/features/inventory/presentation/inventory_format.dart';
import 'package:swarnbook/features/inventory/presentation/screens/inventory_form_page.dart';
import 'package:swarnbook/features/inventory/presentation/screens/ocr_review_page.dart';
import 'package:swarnbook/features/inventory/presentation/widgets/inventory_detail_sheet.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/data_export.dart';
import 'package:swarnbook/shared/application/stat_period.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/stat_period_selector.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final ApiClient _api = ApiClient();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  InventoryQuery _query = const InventoryQuery();
  String _section = 'view';
  bool _canManage = false;
  bool _isOcrUploading = false;
  StatPeriod _soldPeriod = StatPeriod.month;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchCurrentUserRole(_api);
      if (!mounted) return;
      setState(() {
        _canManage = isAdminRole(role);
        if (!_canManage && _section == 'add') _section = 'view';
      });
    } catch (_) {
      if (mounted) setState(() => _canManage = false);
    }
  }

  void _selectSection(String value) {
    if (value == 'add' && !_canManage) return;
    setState(() {
      _section = value;
      if (value == 'sold') {
        _query = _query.copyWith(status: 'sold');
      } else if (value == 'view') {
        _query = _query.copyWith(status: 'in_stock');
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = _query.copyWith(search: value));
    });
  }

  Future<void> _refresh() async {
    if (_section == 'sold') {
      ref.invalidate(soldProductsProvider(_query.search));
      await ref.read(soldProductsProvider(_query.search).future);
    } else {
      ref.invalidate(inventoryOverviewProvider(_query));
      await ref.read(inventoryOverviewProvider(_query).future);
    }
  }

  Future<void> _openForm({InventoryItem? item}) async {
    if (!_canManage) return;
    final changed = await InventoryFormPage.open(context, item: item);
    if (changed == true && mounted) {
      ref.invalidate(inventoryOverviewProvider(_query));
    }
  }

  Future<void> _delete(InventoryItem item) async {
    if (!_canManage) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inventoryDeleteTitle),
        content: Text(
          l10n.inventoryDeleteConfirm(item.itemName ?? l10n.inventoryThisItem),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(inventoryRepositoryProvider).delete(item.id);
      if (!mounted) return;
      AppToast.success(context, l10n.inventoryDeleted);
      ref.invalidate(inventoryOverviewProvider(_query));
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.errorFailedDeleteInventory);
    }
  }

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context)!;
    var metal = _query.metal;
    var status = _query.status;
    final categoryController = TextEditingController(text: _query.category);
    final branchController = TextEditingController(text: _query.branch);

    await AppFilterSheet.show(
      context,
      onApply: () => setState(() {
        _query = _query.copyWith(
          metal: metal,
          status: status,
          category: categoryController.text,
          branch: branchController.text,
        );
      }),
      onClear: () {
        metal = 'all';
        status = 'in_stock';
        categoryController.clear();
        branchController.clear();
      },
      builder: (context, setSheetState) => [
        Text(
          l10n.inventoryFieldMetalType,
          style: TextStyle(color: AppColors.text2(context), fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final option in const ['all', 'gold', 'silver'])
              AppFilterChip(
                label: option == 'all'
                    ? l10n.inventoryAll
                    : inventoryMetalLabel(l10n, option),
                selected: metal == option,
                onTap: () => setSheetState(() => metal = option),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: status,
          decoration: InputDecoration(
            labelText: l10n.inventoryFilterStatus,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          items: [
            for (final s in const ['in_stock', 'sold', 'reserved'])
              DropdownMenuItem(
                value: s,
                child: Text(inventoryStatusLabel(l10n, s)),
              ),
          ],
          onChanged: (value) => setSheetState(() => status = value ?? status),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: categoryController,
          decoration: InputDecoration(
            labelText: l10n.inventoryFilterCategory,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: branchController,
          decoration: InputDecoration(
            labelText: l10n.inventoryFilterBranch,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ],
    );

    categoryController.dispose();
    branchController.dispose();
  }

  // ---- OCR receipt scan ---------------------------------------------------

  Future<void> _showReceiptSourceSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.inventoryTakePhoto),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.inventoryChooseFromGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _scanReceipt(source);
  }

  Future<void> _scanReceipt(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 86,
        maxWidth: 2200,
      );
      if (image == null) return;

      setState(() => _isOcrUploading = true);
      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'receipt': MultipartFile.fromBytes(
          bytes,
          filename: image.name,
          contentType: _safeMediaType(
            image.mimeType ?? _mimeTypeForImage(image.name),
          ),
        ),
      });

      final response = await _api.dio.post(
        '/inventory/ocr-preview',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      if (!mounted) return;
      setState(() => _isOcrUploading = false);

      final payload = response.data as Map<String, dynamic>? ?? {};
      final rows = (payload['rows'] as List<dynamic>? ?? [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      if (rows.isEmpty) {
        AppToast.warning(context, l10n.inventoryNoRowsFound);
        return;
      }

      final imported = await AppFormScaffold.push<bool>(
        context,
        builder: (_) => OcrReviewPage(rows: rows),
      );

      if (imported == true && mounted) {
        AppToast.success(context, l10n.inventoryImported);
        setState(() => _section = 'view');
        ref.invalidate(inventoryOverviewProvider(_query));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isOcrUploading = false);
      AppToast.error(context, _ocrErrorMessage(error));
    }
  }

  String _ocrErrorMessage(Object error) {
    final l10n = AppLocalizations.of(context)!;
    if (error is DioException && error.message != null) return error.message!;
    final details = error.toString();
    if (details.trim().isEmpty || details == 'null') {
      return l10n.inventoryFailedScanHuid;
    }
    return details;
  }

  DioMediaType? _safeMediaType(String value) {
    try {
      return DioMediaType.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _mimeTypeForImage(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppSectionScaffold(
      sections: [
        SectionItem(
          value: 'view',
          label: l10n.inventoryViewInventory,
          icon: Icons.inventory_2_outlined,
        ),
        if (_canManage)
          SectionItem(
            value: 'add',
            label: l10n.inventoryAddStock,
            icon: Icons.add_box_outlined,
          ),
        SectionItem(
          value: 'sold',
          label: l10n.inventorySoldProducts,
          icon: Icons.shopping_bag_outlined,
        ),
      ],
      activeSection: _section,
      onSectionChanged: _selectSection,
      onRefresh: _section == 'add' ? null : _refresh,
      body: switch (_section) {
        'add' => _AddSection(
          isUploading: _isOcrUploading,
          onScan: _isOcrUploading ? null : _showReceiptSourceSheet,
          onManual: _isOcrUploading ? null : () => _openForm(),
        ),
        'sold' => _buildSoldBody(),
        _ => _buildStockBody(),
      },
    );
  }

  Widget _buildStockBody() {
    final async = ref.watch(inventoryOverviewProvider(_query));
    return AppStateView<InventoryOverview>(
      value: async,
      onRetry: () => ref.invalidate(inventoryOverviewProvider(_query)),
      data: (overview) {
        final l10n = AppLocalizations.of(context)!;
        // The "sold" count follows the selected period; other figures are
        // period-neutral. Falls back to the overview stats while loading.
        final periodStats =
            ref.watch(inventoryStatsProvider(_soldPeriod)).valueOrNull ??
            overview.stats;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _StatsStrip(
              stats: periodStats,
              soldPeriod: _soldPeriod,
              onSoldPeriodChanged: (p) => setState(() => _soldPeriod = p),
            ),
            _AlertsRow(stats: overview.stats),
            _searchRow(l10n.inventorySearchHintStock),
            if (overview.items.isEmpty)
              EmptyState.inventory(
                onAction: _canManage ? () => _openForm() : null,
              )
            else ...[
              for (final item in overview.items) _itemRow(item),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSoldBody() {
    final async = ref.watch(soldProductsProvider(_query.search));
    return AppStateView<List<SoldProduct>>(
      value: async,
      onRetry: () => ref.invalidate(soldProductsProvider(_query.search)),
      data: (sold) {
        final l10n = AppLocalizations.of(context)!;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _searchRow(l10n.inventorySearchHintSold, showFilter: false),
            if (sold.isEmpty)
              EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: l10n.inventoryNoSoldFound,
                subtitle: l10n.inventoryNoSoldSubtitle,
                iconColor: AppColors.success,
              )
            else
              for (final row in sold) _soldRow(row),
          ],
        );
      },
    );
  }

  Widget _searchRow(String hint, {bool showFilter = true}) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          if (showFilter) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: l10n.commonFilters,
              onPressed: _openFilters,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
          if (_canManage) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: l10n.exportCsv,
              onPressed: () => exportAndShareCsv(context, 'inventory'),
              icon: const Icon(Icons.file_download_outlined),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemRow(InventoryItem item) {
    final l10n = AppLocalizations.of(context)!;
    return CompactDataRow(
      leading: inventoryImagePreview(context, item.photo, size: 42),
      title: item.itemName ?? l10n.inventoryUnnamedItem,
      subtitle:
          '${item.categoryName ?? '—'} • ${inventoryPurityText(item)} • ${inventoryDesignTag(item)}',
      metrics: [
        (l10n.inventoryCompactNet, inventoryOptionalWeight(item.netWeight)),
        (
          l10n.inventoryCompactPrice,
          inventoryCurrencyText(item.estimatedSellingPrice),
        ),
      ],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(label: inventoryStatusLabel(l10n, item.status)),
          ItemActionsMenu(
            actions: [
              ItemAction(
                type: ItemActionType.view,
                customLabel: l10n.inventoryView,
                onPressed: () => showInventoryDetail(context, item),
              ),
              if (_canManage)
                ItemAction(
                  type: ItemActionType.edit,
                  customLabel: l10n.commonEdit,
                  onPressed: () => _openForm(item: item),
                ),
              if (_canManage)
                ItemAction(
                  type: ItemActionType.delete,
                  customLabel: l10n.commonDelete,
                  onPressed: () => _delete(item),
                  isDestructive: true,
                ),
            ],
          ),
        ],
      ),
      onTap: () => showInventoryDetail(context, item),
    );
  }

  Widget _soldRow(SoldProduct row) {
    final l10n = AppLocalizations.of(context)!;
    return CompactDataRow(
      title: row.productName ?? '—',
      subtitle:
          '${l10n.inventoryColumnInvoiceNumber}: ${row.invoiceNumber ?? '—'} • ${inventoryShortDate(row.soldDate)}',
      metrics: [
        (l10n.inventoryCompactPrice, inventoryCurrencyText(row.sellingPrice)),
        (
          l10n.inventoryCompactPayment,
          inventoryReadableValue(row.paymentMethod),
        ),
      ],
      trailing: Text(
        row.customerName ?? '—',
        style: TextStyle(fontSize: 11, color: AppColors.text3(context)),
      ),
    );
  }
}

// ===========================================================================

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.stats,
    required this.soldPeriod,
    required this.onSoldPeriodChanged,
  });

  final InventoryStats? stats;
  final StatPeriod soldPeriod;
  final ValueChanged<StatPeriod> onSoldPeriodChanged;

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.inventorySoldProducts} · ${StatPeriodSelector.labelFor(context, soldPeriod)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text3(context),
                  ),
                ),
                StatPeriodSelector(
                  value: soldPeriod,
                  onChanged: onSoldPeriodChanged,
                ),
              ],
            ),
          ),
          CompactStatStrip(
            stats: [
              (
                icon: Icons.scale_rounded,
                label: l10n.inventoryTotalGoldWeight,
                value: inventoryWeightText(stats!.totalGoldWeight),
                color: AppColors.gold,
              ),
              (
                icon: Icons.scale_outlined,
                label: l10n.inventoryTotalSilverWeight,
                value: inventoryWeightText(stats!.totalSilverWeight),
                color: AppColors.silver,
              ),
              (
                icon: Icons.inventory_2_rounded,
                label: l10n.inventoryTotalProducts,
                value: '${stats!.totalProducts}',
                color: AppColors.primary,
              ),
              (
                icon: Icons.shopping_bag_rounded,
                label: l10n.inventorySoldProducts,
                value: '${stats!.soldThisMonth}',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertsRow extends StatelessWidget {
  const _AlertsRow({required this.stats});

  final InventoryStats? stats;

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final items = [
      if (stats!.lowStock > 0)
        (l10n.inventoryAlertLowStock, stats!.lowStock, AppColors.warning),
      if (stats!.outOfStock > 0)
        (l10n.inventoryAlertOutOfStock, stats!.outOfStock, AppColors.error),
      if (stats!.highValueProducts > 0)
        (
          l10n.inventoryAlertHighValue,
          stats!.highValueProducts,
          AppColors.primary,
        ),
      if (stats!.unsoldProducts > 0)
        (l10n.inventoryAlertUnsold, stats!.unsoldProducts, AppColors.info),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: item.$3.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: item.$3.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${item.$1}: ${item.$2}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: item.$3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddSection extends StatelessWidget {
  const _AddSection({
    required this.isUploading,
    required this.onScan,
    required this.onManual,
  });

  final bool isUploading;
  final VoidCallback? onScan;
  final VoidCallback? onManual;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _card(
          context,
          icon: Icons.camera_alt_outlined,
          title: l10n.inventoryScanHuidReceipt,
          subtitle: l10n.inventoryScanHuidSubtitle,
          onTap: onScan,
        ),
        const SizedBox(height: AppSpacing.md),
        _card(
          context,
          icon: Icons.edit_note_rounded,
          title: l10n.inventoryAddManually,
          subtitle: l10n.inventoryAddManuallySubtitle,
          onTap: onManual,
        ),
        if (isUploading) ...[
          const SizedBox(height: AppSpacing.lg),
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.inventoryReadingHuid,
            style: TextStyle(color: AppColors.text2(context)),
          ),
        ],
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: TextStyle(color: AppColors.text2(context))),
        ],
      ),
    );
  }
}
