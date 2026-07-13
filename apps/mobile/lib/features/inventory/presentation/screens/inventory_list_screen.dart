import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/categories/application/categories_providers.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
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

  /// Sold tab: sold-date window (lives here, not on the stock tab).
  StatPeriod _soldPeriod = StatPeriod.month;

  /// Stock tab: created-date window picked in the filter sheet.
  StatPeriod _stockPeriod = const StatPeriod(StatPeriodKind.all);

  SoldQuery get _soldQuery =>
      SoldQuery(search: _query.search, period: _soldPeriod);

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
      ref.invalidate(soldProductsProvider(_soldQuery));
      await ref.read(soldProductsProvider(_soldQuery).future);
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

  /// The one place all stock filters live: metal, status, category,
  /// branch, and time range (req §3.1 consolidation).
  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context)!;
    var metal = _query.metal;
    var status = _query.status;
    var categoryId = _query.categoryId;
    var period = _stockPeriod;
    final branchController = TextEditingController(text: _query.branch);
    final categories = await ref
        .read(categoriesProvider.future)
        .catchError((_) => <ShopCategory>[]);
    if (!mounted) return;

    await AppFilterSheet.show(
      context,
      onApply: () => setState(() {
        _stockPeriod = period;
        final dates = period.toDateQueryParameters();
        _query = _query.copyWith(
          metal: metal,
          status: status,
          categoryId: categoryId,
          branch: branchController.text,
          dateFrom: dates['dateFrom'] ?? '',
          dateTo: dates['dateTo'] ?? '',
        );
      }),
      onClear: () {
        metal = 'all';
        status = 'in_stock';
        categoryId = '';
        period = const StatPeriod(StatPeriodKind.all);
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
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.commonTimeRange,
                style: TextStyle(color: AppColors.text2(context), fontSize: 13),
              ),
            ),
            StatPeriodSelector(
              value: period,
              onChanged: (value) => setSheetState(() => period = value),
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
        DropdownButtonFormField<String>(
          initialValue:
              categories.any((c) => c.id == categoryId) && categoryId.isNotEmpty
              ? categoryId
              : '',
          decoration: InputDecoration(
            labelText: l10n.inventoryFilterCategory,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(l10n.inventoryAll)),
            for (final category in categories)
              DropdownMenuItem(
                value: category.id,
                child: Text(
                  category.prefix == null
                      ? category.name
                      : '${category.name} (${category.prefix})',
                ),
              ),
          ],
          onChanged: (value) =>
              setSheetState(() => categoryId = value ?? categoryId),
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
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _StatsStrip(
              stats: overview.stats,
              onGoldTap: () => _showKaratBreakdown(overview.stats, 'gold'),
              onSilverTap: () => _showKaratBreakdown(overview.stats, 'silver'),
              onProductsTap: () => _showMetalBreakdown(overview.stats),
            ),
            _AlertsRow(stats: overview.stats),
            _searchRow(l10n.inventorySearchHintStock),
            _metalChipsRow(l10n),
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

  /// One-tap Gold/Silver filter without opening the sheet (req §3.4).
  Widget _metalChipsRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final option in const ['all', 'gold', 'silver'])
            AppFilterChip(
              label: option == 'all'
                  ? l10n.inventoryAll
                  : inventoryMetalLabel(l10n, option),
              selected: _query.metal == option,
              onTap: () =>
                  setState(() => _query = _query.copyWith(metal: option)),
            ),
        ],
      ),
    );
  }

  /// Total Products tile → metal-wise counts (req §3.5).
  void _showMetalBreakdown(InventoryStats? stats) {
    if (stats == null || stats.metalBreakdown.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    AppDetailSheet.show(
      context,
      title: l10n.inventoryMetalBreakdownTitle,
      sections: [
        AppDetailSection(
          heading: l10n.inventoryTotalProducts,
          rows: [
            for (final metal in stats.metalBreakdown)
              AppDetailRow(
                inventoryMetalLabel(l10n, metal.metalType),
                '${metal.count} ${l10n.inventoryPiecesSuffix} · '
                '${inventoryWeightText(metal.totalWeight)}',
              ),
          ],
        ),
      ],
    );
  }

  /// Gold/Silver weight tiles → per-karat split (req §3.3).
  void _showKaratBreakdown(InventoryStats? stats, String metalType) {
    if (stats == null) return;
    final l10n = AppLocalizations.of(context)!;
    final breakdown = stats.karatBreakdown
        .where((b) => b.metalType == metalType)
        .toList();
    if (breakdown.isEmpty || breakdown.first.karats.isEmpty) return;
    AppDetailSheet.show(
      context,
      title: metalType == 'gold'
          ? l10n.inventoryGoldByKarat
          : l10n.inventorySilverByPurity,
      sections: [
        AppDetailSection(
          heading: inventoryMetalLabel(l10n, metalType),
          rows: [
            for (final slice in breakdown.first.karats)
              AppDetailRow(
                slice.karat,
                '${inventoryWeightText(slice.totalWeight)} · '
                '${slice.count} ${l10n.inventoryPiecesSuffix}',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSoldBody() {
    final async = ref.watch(soldProductsProvider(_soldQuery));
    return AppStateView<List<SoldProduct>>(
      value: async,
      onRetry: () => ref.invalidate(soldProductsProvider(_soldQuery)),
      data: (sold) {
        final l10n = AppLocalizations.of(context)!;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            _searchRow(l10n.inventorySearchHintSold, showFilter: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.inventorySoldProducts} · '
                    '${StatPeriodSelector.labelFor(context, _soldPeriod)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text3(context),
                    ),
                  ),
                  StatPeriodSelector(
                    value: _soldPeriod,
                    onChanged: (p) => setState(() => _soldPeriod = p),
                  ),
                ],
              ),
            ),
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

  /// Richer sold row (req §4.1): tag, category, karat, net weight, amount,
  /// customer, invoice number, and date — the full row width earns its keep.
  Widget _soldRow(SoldProduct row) {
    final l10n = AppLocalizations.of(context)!;
    final identity = [
      if (row.tagNumber != null) row.tagNumber!,
      if (row.categoryName != null) row.categoryName!,
      if (row.karat != null) row.karat!,
    ].join(' • ');
    return CompactDataRow(
      title: row.productName ?? '—',
      subtitle: [
        if (identity.isNotEmpty) identity,
        '${l10n.inventoryColumnInvoiceNumber}: ${row.invoiceNumber ?? '—'}'
            ' • ${inventoryShortDate(row.soldDate)}'
            ' • ${row.customerName ?? '—'}',
      ].join('\n'),
      metrics: [
        (l10n.inventoryCompactPrice, inventoryCurrencyText(row.sellingPrice)),
        if (row.netWeight != null)
          (l10n.inventoryCompactNet, inventoryOptionalWeight(row.netWeight)),
        (
          l10n.inventoryCompactPayment,
          inventoryReadableValue(row.paymentMethod),
        ),
      ],
    );
  }
}

// ===========================================================================

/// Stock-tab stat tiles. Sold figures live on the Sold tab only (req §3.1);
/// each tile taps through to its breakdown (req §3.3/§3.5).
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.stats,
    required this.onGoldTap,
    required this.onSilverTap,
    required this.onProductsTap,
  });

  final InventoryStats? stats;
  final VoidCallback onGoldTap;
  final VoidCallback onSilverTap;
  final VoidCallback onProductsTap;

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
      child: CompactStatStrip(
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
        ],
        onTaps: [onGoldTap, onSilverTap, onProductsTap],
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
    // Out-of-stock moved to the Dashboard (req §3.2, lands with R5's
    // threshold-based version) — no longer shown here.
    final items = [
      if (stats!.lowStock > 0)
        (l10n.inventoryAlertLowStock, stats!.lowStock, AppColors.warning),
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
