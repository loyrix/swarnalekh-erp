import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/inventory/application/inventory_image_payloads.dart';
import 'package:swarnbook/features/inventory/application/inventory_pricing_calculations.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/shimmer_loading.dart';
import 'package:swarnbook/shared/widgets/empty_state.dart';
import 'package:swarnbook/shared/widgets/staggered_animation.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/compact_data_row.dart';
import 'package:swarnbook/shared/widgets/compact_stat_strip.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final ApiClient _api = ApiClient();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryFilterController =
      TextEditingController();
  final TextEditingController _branchFilterController = TextEditingController();
  List<dynamic> _items = [];
  List<dynamic> _soldProducts = [];
  Map<String, dynamic>? _stats;
  Timer? _searchDebounce;
  bool _isLoading = true;
  bool _isOcrUploading = false;
  bool _canManageInventory = false;
  String _filterMetal = 'all';
  String _filterStatus = 'in_stock';
  String _activeSection = 'view';

  static const List<Map<String, String>> _metalOptions = [
    {'label': 'Gold', 'value': 'gold'},
    {'label': 'Silver', 'value': 'silver'},
  ];

  static const List<Map<String, String>> _statusOptions = [
    {'label': 'In Stock', 'value': 'in_stock'},
    {'label': 'Sold', 'value': 'sold'},
    {'label': 'Reserved', 'value': 'reserved'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadData();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchCurrentUserRole(_api);
      if (mounted) {
        setState(() {
          _canManageInventory = isAdminRole(role);
          if (!_canManageInventory && _activeSection == 'add') {
            _activeSection = 'view';
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _canManageInventory = false);
    }
  }

  Future<void> _loadData() async {
    try {
      final overviewFuture = _api.dio.get(
        '/inventory/overview',
        queryParameters: {
          'status': _filterStatus,
          if (_filterMetal != 'all') 'metalType': _filterMetal,
          if (_searchController.text.trim().isNotEmpty)
            'search': _searchController.text.trim(),
          if (_categoryFilterController.text.trim().isNotEmpty)
            'categoryName': _categoryFilterController.text.trim(),
          if (_branchFilterController.text.trim().isNotEmpty)
            'location': _branchFilterController.text.trim(),
        },
      );
      final soldProductsFuture = _activeSection == 'sold'
          ? _api.dio.get(
              '/inventory/sold-products',
              queryParameters: {
                if (_searchController.text.trim().isNotEmpty)
                  'search': _searchController.text.trim(),
              },
            )
          : null;
      final response = await overviewFuture;
      final soldProductsResponse = soldProductsFuture == null
          ? null
          : await soldProductsFuture;
      final payload = response.data as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        _items = (payload['items'] as List<dynamic>? ?? []);
        _soldProducts =
            (soldProductsResponse?.data as List<dynamic>? ?? _soldProducts);
        _stats = payload['stats'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isLoading = false);
        AppToast.error(context, l10n.errorFailedLoadInventory);
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _categoryFilterController.dispose();
    _branchFilterController.dispose();
    super.dispose();
  }

  void _selectSection(String value) {
    if (value == 'add' && !_canManageInventory) return;
    setState(() {
      _activeSection = value;
      if (value == 'sold') {
        _filterStatus = 'sold';
      } else if (value == 'view') {
        _filterStatus = 'in_stock';
      }
    });
    _loadData();
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadData);
  }

  Future<void> _openInventoryForm({Map<String, dynamic>? item}) async {
    if (!_canManageInventory) return;
    final changed = await showResponsiveDialog<bool>(
      context: context,
      builder: (context) => _InventoryFormDialog(api: _api, item: item),
    );

    if (changed == true && mounted) {
      _loadData();
    }
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

      final imported = await showResponsiveDialog<bool>(
        context: context,
        builder: (context) => _OcrReviewDialog(api: _api, rows: rows),
      );

      if (imported == true && mounted) {
        AppToast.success(context, l10n.inventoryImported);
        setState(() => _activeSection = 'manage');
        _loadData();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isOcrUploading = false);
      AppToast.error(context, _ocrErrorMessage(error));
    }
  }

  String _ocrErrorMessage(Object error) {
    final l10n = AppLocalizations.of(context)!;
    if (error is DioException && error.message != null) {
      return error.message!;
    }
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

  Future<void> _deleteInventoryItem(Map<String, dynamic> item) async {
    if (!_canManageInventory) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inventoryDeleteTitle),
        content: Text(
          l10n.inventoryDeleteConfirm(
            (item['itemName'] ?? l10n.inventoryThisItem).toString(),
          ),
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
      await _api.dio.delete('/inventory/${item['id']}');
      if (!mounted) return;
      AppToast.success(context, l10n.inventoryDeleted);
      _loadData();
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.errorFailedDeleteInventory);
    }
  }

  List<dynamic> get _filtered {
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerState();
    }

    final isWide = MediaQuery.of(context).size.width > 768;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionSwitch(),
            const SizedBox(height: AppSpacing.lg),
            if (_activeSection == 'add')
              _buildAddInventorySection()
            else ...[
              _buildStatsRow(isWide),
              const SizedBox(height: AppSpacing.md),
              _buildInventoryAlerts(isWide),
              const SizedBox(height: AppSpacing.lg),
              _buildFilters(isWide),
              const SizedBox(height: AppSpacing.md),
              _activeSection == 'sold'
                  ? _buildSoldProductsView(isWide)
                  : _buildListView(isWide),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.inventoryManagement,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionSwitch() {
    final l10n = AppLocalizations.of(context)!;
    return SectionSwitch(
      activeValue: _activeSection,
      onChanged: _selectSection,
      items: [
        SectionItem(
          value: 'view',
          label: l10n.inventoryViewInventory,
          icon: Icons.inventory_2_outlined,
        ),
        if (_canManageInventory)
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
    );
  }

  Widget _buildAddInventorySection() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _addInventoryAction(
                icon: Icons.camera_alt_outlined,
                title: l10n.inventoryScanHuidReceipt,
                subtitle: l10n.inventoryScanHuidSubtitle,
                onTap: _isOcrUploading ? null : () => _showReceiptSourceSheet(),
              ),
              _addInventoryAction(
                icon: Icons.edit_note_rounded,
                title: l10n.inventoryAddManually,
                subtitle: l10n.inventoryAddManuallySubtitle,
                onTap: _isOcrUploading ? null : () => _openInventoryForm(),
              ),
            ],
          ),
          if (_isOcrUploading) ...[
            const SizedBox(height: AppSpacing.lg),
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.inventoryReadingHuid,
              style: TextStyle(color: AppColors.text2(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addInventoryAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    return GlassCard(
      width: width > 760 ? 340 : double.infinity,
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

    if (source != null) {
      await _scanReceipt(source);
    }
  }

  Widget _buildShimmerState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats shimmer
          Row(
            children: [
              Expanded(child: ShimmerStatCard()),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: ShimmerStatCard()),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: ShimmerStatCard()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Filter chips shimmer
          Row(
            children: [
              ShimmerBox(width: 60, height: 34, borderRadius: AppRadius.full),
              const SizedBox(width: 8),
              ShimmerBox(width: 60, height: 34, borderRadius: AppRadius.full),
              const SizedBox(width: 8),
              ShimmerBox(width: 60, height: 34, borderRadius: AppRadius.full),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Grid shimmer
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1000
                    ? 4
                    : constraints.maxWidth > 700
                    ? 3
                    : 2;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => const ShimmerGridCard(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final stats = <({IconData icon, String label, String value, Color color})>[
      (
        icon: Icons.scale_rounded,
        label: l10n.inventoryTotalGoldWeight,
        value: _weightText(_stats?['totalGoldWeight']),
        color: AppColors.gold,
      ),
      (
        icon: Icons.scale_outlined,
        label: l10n.inventoryTotalSilverWeight,
        value: _weightText(_stats?['totalSilverWeight']),
        color: AppColors.silver,
      ),
      (
        icon: Icons.inventory_2_rounded,
        label: l10n.inventoryTotalProducts,
        value: '${_stats?['totalProducts'] ?? 0}',
        color: AppColors.primary,
      ),
      (
        icon: Icons.shopping_bag_rounded,
        label: l10n.inventorySoldProducts,
        value: '${_stats?['soldThisMonth'] ?? 0}',
        color: AppColors.success,
      ),
    ];

    if (!isWide) {
      return CompactStatStrip(stats: stats);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 920 ? 4 : 2;
        final width =
            (constraints.maxWidth - (crossAxisCount - 1) * AppSpacing.md) /
            crossAxisCount;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var index = 0; index < stats.length; index++)
              SizedBox(
                width: width,
                child: StaggeredFadeSlide(
                  index: index,
                  child: StatCard(
                    icon: stats[index].icon,
                    label: stats[index].label,
                    value: stats[index].value,
                    accentColor: stats[index].color,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInventoryAlerts(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final alerts = (_stats?['alerts'] as Map<String, dynamic>? ?? {});
    final items = [
      if ((alerts['lowStock'] ?? 0) > 0)
        (
          label: l10n.inventoryAlertLowStock,
          value: alerts['lowStock'],
          icon: Icons.low_priority_rounded,
          color: AppColors.warning,
        ),
      if ((alerts['outOfStock'] ?? 0) > 0)
        (
          label: l10n.inventoryAlertOutOfStock,
          value: alerts['outOfStock'],
          icon: Icons.remove_shopping_cart_outlined,
          color: AppColors.error,
        ),
      if ((alerts['highValueProducts'] ?? 0) > 0)
        (
          label: l10n.inventoryAlertHighValue,
          value: alerts['highValueProducts'],
          icon: Icons.diamond_outlined,
          color: AppColors.primary,
        ),
      if ((alerts['unsoldProducts'] ?? 0) > 0)
        (
          label: l10n.inventoryAlertUnsold,
          value: alerts['unsoldProducts'],
          icon: Icons.hourglass_bottom_rounded,
          color: AppColors.info,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    if (!isWide) {
      return SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: item.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 12, color: item.color),
                  const SizedBox(width: 4),
                  Text(
                    '${item.value}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.color,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          Chip(
            avatar: Icon(item.icon, size: 16, color: item.color),
            label: Text('${item.label}: ${item.value}'),
            backgroundColor: item.color.withValues(alpha: 0.1),
            side: BorderSide(color: item.color.withValues(alpha: 0.2)),
          ),
      ],
    );
  }

  Widget _buildFilters(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    if (_activeSection == 'sold') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            searchHint: l10n.inventorySearchHintSold,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.inventoryCountSold(_soldProducts.length),
            style: TextStyle(color: AppColors.text3(context), fontSize: 13),
          ),
        ],
      );
    }

    return SearchFilterBar(
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      searchHint: l10n.inventorySearchHintStock,
      onRefresh: _loadData,
      isLoading: _isLoading,
      filterBuilder: (_) => [
        AppFilterChip(
          label: l10n.inventoryAll,
          selected: _filterMetal == 'all',
          onTap: () {
            setState(() => _filterMetal = 'all');
            _loadData();
          },
        ),
        ..._metalOptions.map(
          (option) => AppFilterChip(
            label: _metalLabel(l10n, option['value']!),
            selected: _filterMetal == option['value'],
            onTap: () {
              setState(() => _filterMetal = option['value']!);
              _loadData();
            },
          ),
        ),
        SizedBox(
          width: 160,
          child: TextField(
            controller: _categoryFilterController,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: l10n.inventoryFilterCategory,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 160,
          child: TextField(
            controller: _branchFilterController,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: l10n.inventoryFilterBranch,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        FilterDropdown<String>(
          value: _filterStatus,
          label: l10n.inventoryFilterStatus,
          width: 160,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _filterStatus = value);
            _loadData();
          },
          items: _statusOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(_statusLabel(l10n, option['value'])),
                ),
              )
              .toList(),
        ),
        if ((_stats?['valuationDate'] as String?) != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '${l10n.inventoryRatesPrefix} ${_shortDate(_stats?['valuationDate'])}',
              style: TextStyle(color: AppColors.text3(context), fontSize: 12),
            ),
          ),
        Text(
          '${_filtered.length} ${l10n.inventoryItemsSuffix}',
          style: TextStyle(color: AppColors.text3(context), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildListView(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final list = _filtered;
    if (list.isEmpty) {
      return EmptyState.inventory(
        onAction: _canManageInventory ? () => _openInventoryForm() : null,
      );
    }

    if (!isWide) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index] as Map<String, dynamic>;
          final purity = _purityText(item);
          final designTag =
              (item['designNumber'] ??
                      item['barcode'] ??
                      item['tagNumber'] ??
                      '—')
                  .toString();
          return CompactDataRow(
            leading: _productImage(item),
            title: (item['itemName'] ?? l10n.inventoryUnnamedItem).toString(),
            subtitle: '${item['categoryName'] ?? '—'} • $purity • $designTag',
            metrics: [
              (l10n.inventoryCompactNet, '${item['netWeight'] ?? '0'}g'),
              (
                l10n.inventoryCompactPrice,
                _currencyText(item['estimatedSellingPrice']),
              ),
            ],
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(
                  label: _statusLabel(l10n, item['status'] ?? 'in_stock'),
                ),
                ItemActionsMenu(
                  actions: [
                    ItemAction(
                      type: ItemActionType.view,
                      customLabel: l10n.inventoryView,
                      onPressed: () => _openProductDetails(item),
                    ),
                    if (_canManageInventory)
                      ItemAction(
                        type: ItemActionType.edit,
                        customLabel: l10n.commonEdit,
                        onPressed: () => _openInventoryForm(item: item),
                      ),
                    if (_canManageInventory)
                      ItemAction(
                        type: ItemActionType.delete,
                        customLabel: l10n.commonDelete,
                        onPressed: () => _deleteInventoryItem(item),
                        isDestructive: true,
                      ),
                  ],
                ),
              ],
            ),
            onTap: () => _openProductDetails(item),
          );
        },
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(label: Text(l10n.inventoryColumnItem)),
              DataColumn(label: Text(l10n.inventoryColumnCategory)),
              DataColumn(label: Text(l10n.inventoryColumnDesignNumber)),
              DataColumn(label: Text(l10n.inventoryColumnPurity)),
              DataColumn(label: Text(l10n.inventoryColumnNetWeight)),
              DataColumn(label: Text(l10n.inventoryColumnSellingPrice)),
              DataColumn(label: Text(l10n.inventoryColumnStatus)),
              DataColumn(label: Text(l10n.inventoryColumnActions)),
            ],
            rows: list.map<DataRow>((item) {
              final inventoryItem = item as Map<String, dynamic>;
              return DataRow(
                onSelectChanged: (_) => _openProductDetails(inventoryItem),
                cells: [
                  DataCell(
                    Text(
                      (inventoryItem['itemName'] ?? l10n.inventoryUnnamedItem)
                          .toString(),
                    ),
                  ),
                  DataCell(
                    Text(
                      (inventoryItem['categoryName'] ??
                              inventoryItem['category']?['name'] ??
                              '—')
                          .toString(),
                    ),
                  ),
                  DataCell(
                    Text(
                      (inventoryItem['designNumber'] ??
                              inventoryItem['barcode'] ??
                              inventoryItem['tagNumber'] ??
                              '—')
                          .toString(),
                    ),
                  ),
                  DataCell(Text(_purityText(inventoryItem))),
                  DataCell(Text('${inventoryItem['netWeight'] ?? '0'} g')),
                  DataCell(
                    Text(_currencyText(inventoryItem['estimatedSellingPrice'])),
                  ),
                  DataCell(
                    StatusBadge(
                      label: _statusLabel(
                        l10n,
                        inventoryItem['status'] ?? 'in_stock',
                      ),
                    ),
                  ),
                  DataCell(
                    ItemActionsRow(
                      actions: [
                        ItemAction(
                          type: ItemActionType.view,
                          customLabel: l10n.inventoryViewDetails,
                          onPressed: () => _openProductDetails(inventoryItem),
                        ),
                        if (_canManageInventory) ...[
                          ItemAction(
                            type: ItemActionType.edit,
                            customLabel: l10n.inventoryEditItem,
                            onPressed: () =>
                                _openInventoryForm(item: inventoryItem),
                          ),
                          ItemAction(
                            type: ItemActionType.delete,
                            customLabel: l10n.inventoryDeleteItem,
                            onPressed: () =>
                                _deleteInventoryItem(inventoryItem),
                            isDestructive: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSoldProductsView(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    if (_soldProducts.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: l10n.inventoryNoSoldFound,
        subtitle: l10n.inventoryNoSoldSubtitle,
        iconColor: AppColors.success,
      );
    }

    if (!isWide) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _soldProducts.length,
        itemBuilder: (context, index) {
          final row = Map<String, dynamic>.from(_soldProducts[index] as Map);
          return CompactDataRow(
            title: _textValue(row['productName']),
            subtitle:
                'Invoice: ${_textValue(row['invoiceNumber'])} • ${_shortDate(row['soldDate'])}',
            metrics: [
              (l10n.inventoryCompactPrice, _currencyText(row['sellingPrice'])),
              (
                l10n.inventoryCompactPayment,
                _readableValue(row['paymentMethod']),
              ),
            ],
            trailing: Text(
              _textValue(row['customerName']),
              style: TextStyle(fontSize: 11, color: AppColors.text3(context)),
            ),
          );
        },
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(label: Text(l10n.inventoryColumnInvoiceNumber)),
              DataColumn(label: Text(l10n.inventoryColumnCustomerName)),
              DataColumn(label: Text(l10n.inventoryColumnProductName)),
              DataColumn(label: Text(l10n.inventoryColumnSoldDate)),
              DataColumn(label: Text(l10n.inventoryColumnSellingPrice)),
              DataColumn(label: Text(l10n.inventoryColumnPaymentMethod)),
            ],
            rows: _soldProducts.map<DataRow>((entry) {
              final row = Map<String, dynamic>.from(entry as Map);
              return DataRow(
                cells: [
                  DataCell(Text(_textValue(row['invoiceNumber']))),
                  DataCell(Text(_textValue(row['customerName']))),
                  DataCell(Text(_textValue(row['productName']))),
                  DataCell(Text(_shortDate(row['soldDate']))),
                  DataCell(Text(_currencyText(row['sellingPrice']))),
                  DataCell(Text(_readableValue(row['paymentMethod']))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _productImage(Map<String, dynamic> item) {
    return _inventoryImagePreview(
      context,
      firstInventoryImage(item['photos']),
      size: 42,
    );
  }

  Future<void> _openProductDetails(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text((item['itemName'] ?? l10n.inventoryUnnamedItem).toString()),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _inventoryImagePreview(
                    context,
                    firstInventoryImage(item['photos']),
                    size: 180,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _detailsGroup(l10n.inventoryProductInfo, [
                  (l10n.inventoryProductName, item['itemName'] ?? '—'),
                  (
                    l10n.inventoryProductCode,
                    item['productCode'] ?? item['tagNumber'],
                  ),
                  (
                    l10n.inventoryFieldDesignNumber,
                    item['designNumber'] ?? item['barcode'] ?? '—',
                  ),
                  (
                    l10n.inventoryFieldCategory,
                    item['categoryName'] ?? item['category']?['name'] ?? '—',
                  ),
                  (l10n.inventoryColumnPurity, _purityText(item)),
                  (l10n.inventoryFieldBranch, item['location'] ?? '—'),
                ]),
                const SizedBox(height: AppSpacing.md),
                _detailsGroup(l10n.inventoryWeightDetails, [
                  (l10n.inventoryGrossWeight, '${item['grossWeight'] ?? 0} g'),
                  (
                    l10n.inventoryStoneWeight,
                    _optionalWeightText(item['stoneWeight']),
                  ),
                  (l10n.inventoryCalcNetWeight, '${item['netWeight'] ?? 0} g'),
                ]),
                const SizedBox(height: AppSpacing.md),
                _detailsGroup(l10n.inventoryPriceDetails, [
                  (l10n.inventoryPurchasePrice, _purchasePriceText(item)),
                  (
                    l10n.inventoryFieldSellingPrice,
                    _currencyText(item['estimatedSellingPrice']),
                  ),
                  (l10n.inventoryMakingCharges, _makingText(item)),
                  (l10n.inventoryGstInfo, l10n.inventoryGstInfo),
                ]),
                const SizedBox(height: AppSpacing.md),
                _detailsGroup(l10n.inventoryStatusInfo, [
                  (
                    l10n.inventoryFormStatus,
                    _statusLabel(l10n, item['status']),
                  ),
                  (l10n.inventoryQuantity, item['quantity'] ?? 1),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.inventoryClose),
          ),
        ],
      ),
    );
  }

  Widget _detailsGroup(String title, List<(String, dynamic)> rows) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      row.$1,
                      style: TextStyle(color: AppColors.text3(context)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      (row.$2 ?? '—').toString(),
                      style: TextStyle(
                        color: AppColors.text1(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _makingText(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final perGram = item['makingChargesPerGram'];
    final fixed = item['makingChargesFixed'];
    final percent = item['makingChargesPercent'];
    if (perGram != null) return '${l10n.inventoryMakingPrefix} ₹$perGram/g';
    if (fixed != null) return '${l10n.inventoryMakingPrefix} ₹$fixed';
    if (percent != null) return '${l10n.inventoryMakingPrefix} $percent%';
    return '${l10n.inventoryMakingPrefix} —';
  }

  String _purchasePriceText(Map<String, dynamic> item) {
    final purchaseRate = double.tryParse(
      item['purchaseRate']?.toString() ?? '',
    );
    if (purchaseRate == null) return '—';
    final netWeight = double.tryParse(item['netWeight']?.toString() ?? '') ?? 0;
    final quantity = int.tryParse(item['quantity']?.toString() ?? '') ?? 1;
    return _currencyText(purchaseRate * netWeight * quantity);
  }

  String _purityText(Map<String, dynamic> item) {
    final karat = item['karat'];
    final purity = item['purity'];
    if (karat != null) return karat.toString();
    if (purity != null) return '${purity.toString()}%';
    return '—';
  }

  String _optionalWeightText(dynamic value) {
    if (value == null) return '—';
    return '${value.toString()} g';
  }

  String _weightText(dynamic value) {
    final weight = double.tryParse(value?.toString() ?? '') ?? 0;
    if (weight >= 1000) return '${(weight / 1000).toStringAsFixed(2)} kg';
    return '${weight.toStringAsFixed(3)} g';
  }

  String _currencyText(dynamic value) {
    if (value == null) return '—';
    return '₹${value.toString()}';
  }

  String _textValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '—' : text;
  }

  String _readableValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '—';
    return text
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _shortDate(dynamic value) {
    if (value == null) return '—';
    return value.toString().split('T').first;
  }

  String _metalLabel(AppLocalizations l10n, dynamic value) {
    return switch ((value ?? '').toString()) {
      'gold' => l10n.inventoryMetalGold,
      'silver' => l10n.inventoryMetalSilver,
      'platinum' => l10n.inventoryMetalPlatinum,
      'other' => l10n.inventoryMetalOther,
      _ => '—',
    };
  }

  String _statusLabel(AppLocalizations l10n, dynamic value) {
    return switch ((value ?? '').toString()) {
      'in_stock' => l10n.inventoryInStock,
      'sold' => l10n.inventorySold,
      'on_approval' => l10n.inventoryOnApproval,
      'reserved' => l10n.inventoryReserved,
      _ => '—',
    };
  }
}

Widget _inventoryImagePreview(
  BuildContext context,
  String? imageSource, {
  required double size,
}) {
  final fallback = Container(
    width: size,
    height: size,
    color: AppColors.primary.withValues(alpha: 0.1),
    child: Icon(
      Icons.diamond_outlined,
      color: AppColors.primary,
      size: size > 80 ? 52 : 22,
    ),
  );

  Widget child = fallback;
  if (imageSource != null && imageSource.isNotEmpty) {
    if (isInventoryDataImage(imageSource)) {
      try {
        child = Image.memory(
          decodeInventoryDataImage(imageSource),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } catch (_) {
        child = fallback;
      }
    } else {
      child = Image.network(
        imageSource,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(
      size > 80 ? AppRadius.md : AppRadius.sm,
    ),
    child: SizedBox(width: size, height: size, child: child),
  );
}

class _OcrReviewDialog extends StatefulWidget {
  final ApiClient api;
  final List<Map<String, dynamic>> rows;

  const _OcrReviewDialog({required this.api, required this.rows});

  @override
  State<_OcrReviewDialog> createState() => _OcrReviewDialogState();
}

class _OcrReviewDialogState extends State<_OcrReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<_OcrRowControllers> _rows = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rows.addAll(widget.rows.map(_OcrRowControllers.fromRow));
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
        'hallmarkNumber': row.hallmarkNumber.text.trim().isEmpty
            ? null
            : row.hallmarkNumber.text.trim(),
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
      await widget.api.dio.post('/inventory/import', data: {'rows': rows});
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final l10n = AppLocalizations.of(context)!;
      AppToast.error(context, l10n.inventoryFailedImportRows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.inventoryReviewHuidTitle),
      content: SizedBox(
        width: 980,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inventoryReviewHuidSubtitle,
                  style: TextStyle(color: AppColors.text2(context)),
                ),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Tag')),
                      DataColumn(label: Text('HUID')),
                      DataColumn(label: Text('Hallmark')),
                      DataColumn(label: Text('Metal')),
                      DataColumn(label: Text('Karat')),
                      DataColumn(label: Text('Gross')),
                      DataColumn(label: Text('Net')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Warnings')),
                    ],
                    rows: [
                      for (final row in _rows)
                        DataRow(
                          cells: [
                            DataCell(
                              _ocrTextField(
                                row.itemName,
                                width: 150,
                                required: true,
                              ),
                            ),
                            const DataCell(
                              SizedBox(
                                width: 110,
                                child: Text('Auto-generated'),
                              ),
                            ),
                            DataCell(_ocrTextField(row.huid, width: 120)),
                            DataCell(
                              _ocrTextField(row.hallmarkNumber, width: 120),
                            ),
                            DataCell(_metalDropdown(row)),
                            DataCell(_ocrTextField(row.karat, width: 80)),
                            DataCell(
                              _ocrTextField(
                                row.grossWeight,
                                width: 82,
                                number: true,
                                required: true,
                              ),
                            ),
                            DataCell(
                              _ocrTextField(
                                row.netWeight,
                                width: 82,
                                number: true,
                                required: true,
                              ),
                            ),
                            DataCell(
                              _ocrTextField(
                                row.quantity,
                                width: 70,
                                integer: true,
                                required: true,
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 170,
                                child: Text(
                                  row.warnings.isEmpty
                                      ? 'OK'
                                      : row.warnings.join(', '),
                                  style: TextStyle(
                                    color: row.warnings.isEmpty
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        PrimaryActionButton.goldButton(
          label: l10n.inventoryImportItems,
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _metalDropdown(_OcrRowControllers row) {
    return SizedBox(
      width: 110,
      child: DropdownButtonFormField<String>(
        initialValue: row.metalType,
        items: const [
          DropdownMenuItem(value: 'gold', child: Text('Gold')),
          DropdownMenuItem(value: 'silver', child: Text('Silver')),
        ],
        onChanged: (value) => row.metalType = value ?? 'gold',
      ),
    );
  }

  Widget _ocrTextField(
    TextEditingController controller, {
    required double width,
    bool number = false,
    bool integer = false,
    bool required = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: number || integer
            ? TextInputType.numberWithOptions(decimal: !integer)
            : null,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return 'Required';
          if (integer && int.tryParse(text) == null) return 'Number';
          if (number && double.tryParse(text) == null) return 'Number';
          if (integer && (int.tryParse(text) ?? 0) < 1) return 'Min 1';
          if (number && (double.tryParse(text) ?? 0) <= 0) return 'Min > 0';
          return null;
        },
      ),
    );
  }
}

class _OcrRowControllers {
  final TextEditingController itemName;
  final TextEditingController huid;
  final TextEditingController hallmarkNumber;
  final TextEditingController karat;
  final TextEditingController grossWeight;
  final TextEditingController netWeight;
  final TextEditingController quantity;
  final List<String> warnings;
  String metalType;

  _OcrRowControllers({
    required this.itemName,
    required this.huid,
    required this.hallmarkNumber,
    required this.metalType,
    required this.karat,
    required this.grossWeight,
    required this.netWeight,
    required this.quantity,
    required this.warnings,
  });

  factory _OcrRowControllers.fromRow(Map<String, dynamic> row) {
    final warnings = (row['warnings'] as List<dynamic>? ?? [])
        .map((warning) => warning.toString())
        .toList();
    return _OcrRowControllers(
      itemName: TextEditingController(text: row['itemName']?.toString() ?? ''),
      huid: TextEditingController(text: row['huid']?.toString() ?? ''),
      hallmarkNumber: TextEditingController(
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
    hallmarkNumber.dispose();
    karat.dispose();
    grossWeight.dispose();
    netWeight.dispose();
    quantity.dispose();
  }
}

class _InventoryFormDialog extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic>? item;

  const _InventoryFormDialog({required this.api, this.item});

  @override
  State<_InventoryFormDialog> createState() => _InventoryFormDialogState();
}

class _InventoryFormDialogState extends State<_InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
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
  late bool _sellingPriceTouched;

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
    _nameController = TextEditingController(
      text: item?['itemName']?.toString() ?? '',
    );
    _tagController = TextEditingController(
      text: item?['tagNumber']?.toString() ?? '',
    );
    _designNumberController = TextEditingController(
      text:
          item?['designNumber']?.toString() ??
          item?['barcode']?.toString() ??
          '',
    );
    _categoryController = TextEditingController(
      text:
          item?['categoryName']?.toString() ??
          item?['category']?['name']?.toString() ??
          '',
    );
    _metalType = item?['metalType']?.toString() ?? 'gold';
    _stockType = item?['stockType']?.toString() ?? 'unique';
    _karat = item?['karat']?.toString();
    _status = item?['status']?.toString() ?? 'in_stock';
    _quantityController = TextEditingController(
      text: (item?['quantity']?.toString() ?? '1'),
    );
    final grossWeight = splitInventoryWeight(item?['grossWeight']);
    final netWeight = splitInventoryWeight(item?['netWeight']);
    _grossWeightGramsController = TextEditingController(
      text: grossWeight.grams,
    );
    _grossWeightMgController = TextEditingController(
      text: grossWeight.milligrams,
    );
    _netWeightGramsController = TextEditingController(text: netWeight.grams);
    _netWeightMgController = TextEditingController(text: netWeight.milligrams);
    _stoneWeightController = TextEditingController(
      text: item?['stoneWeight']?.toString() ?? '',
    );
    _stoneValueController = TextEditingController(
      text: item?['stoneValue']?.toString() ?? '',
    );
    _purchaseRateController = TextEditingController(
      text: item?['purchaseRate']?.toString() ?? '',
    );
    _sellingPriceController = TextEditingController(
      text:
          item?['sellingPrice']?.toString() ??
          item?['estimatedSellingPrice']?.toString() ??
          '',
    );
    _sellingPriceTouched = item?['sellingPrice'] != null;
    if (item?['makingChargesPercent'] != null) {
      _makingMode = inventoryMakingModePercentage;
    } else if (item?['makingChargesFixed'] != null) {
      _makingMode = inventoryMakingModeFixed;
    } else {
      _makingMode = inventoryMakingModePerGram;
    }
    _makingController = TextEditingController(
      text:
          item?['makingChargesPercent']?.toString() ??
          item?['makingChargesPerGram']?.toString() ??
          item?['makingChargesFixed']?.toString() ??
          '',
    );
    _locationController = TextEditingController(
      text: item?['location']?.toString() ?? '',
    );
    _photoUrlController = TextEditingController(
      text: firstInventoryImage(item?['photos']) ?? '',
    );
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
        await widget.api.dio.put(
          '/inventory/${widget.item!['id']}',
          data: payload,
        );
      } else {
        await widget.api.dio.post('/inventory', data: payload);
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

  void _clearProductImage() {
    setState(() => _photoUrlController.clear());
  }

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
      _syncSellingPriceFromCalculation();
    });
  }

  void _onPricingChanged() {
    setState(_syncSellingPriceFromCalculation);
  }

  void _onSellingPriceChanged(String value) {
    if (value.trim().isEmpty) {
      _sellingPriceTouched = false;
      _onPricingChanged();
      return;
    }
    setState(() => _sellingPriceTouched = true);
  }

  void _syncSellingPriceFromCalculation() {
    if (_sellingPriceTouched) return;
    final value = _calculatedFinalSellingPrice;
    _sellingPriceController.text = value <= 0 ? '' : value.toStringAsFixed(2);
  }

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

  double get _calculatedFinalSellingPrice {
    return calculateInventoryFinalSellingPrice(
      netWeight: _currentNetWeight,
      purchasePrice: _currentPurchaseRate,
      makingCharges: _calculatedMakingCharges,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(_isEdit ? l10n.inventoryEditTitle : l10n.inventoryAddTitle),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formSectionTitle(l10n.inventoryProductDetails),
                _field(
                  _nameController,
                  l10n.inventoryFieldItemName,
                  requiredMessage: l10n.validationItemNameRequired,
                ),
                const SizedBox(height: AppSpacing.md),
                _field(_tagController, l10n.inventoryFieldTagNumber),
                const SizedBox(height: AppSpacing.md),
                _field(
                  _designNumberController,
                  l10n.inventoryFieldDesignNumber,
                ),
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
                      if (_stockType == 'unique') {
                        _quantityController.text = '1';
                      }
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
                  labelBuilder: (value) => _metalLabel(l10n, value),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _metalType = value;
                      final validKarats =
                          _karatOptions[_metalType]
                              ?.map((e) => e['value'])
                              .toSet() ??
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
                  allowEmpty: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                _formSectionTitle(l10n.inventoryWeightDetails),
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
                _formSectionTitle(l10n.inventoryPriceDetails),
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
                      _syncSellingPriceFromCalculation();
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
                ),
                const SizedBox(height: AppSpacing.md),
                _autoCalculationSummary(),
                const SizedBox(height: AppSpacing.lg),
                _field(_locationController, l10n.inventoryFieldBranch),
                const SizedBox(height: AppSpacing.lg),
                _formSectionTitle(l10n.inventoryUploadImage),
                _imageUploadField(),
                const SizedBox(height: AppSpacing.lg),
                _formSectionTitle(l10n.inventoryFormStatus),
                _dropdownField(
                  label: l10n.inventoryColumnStatus,
                  value: _status,
                  items: _statusOptions,
                  labelBuilder: (value) => _statusLabel(l10n, value),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        PrimaryActionButton.goldButton(
          label: _isEdit ? l10n.commonUpdate : l10n.commonCreate,
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _formSectionTitle(String title) {
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
              _inventoryImagePreview(context, imageSource, size: 96),
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
                Icon(
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
                border: OutlineInputBorder(),
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

  String _currencyValue(double value) {
    return '₹${value.toStringAsFixed(2)}';
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
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (requiredMessage != null && text.isEmpty) {
          return requiredMessage;
        }
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String _metalLabel(AppLocalizations l10n, dynamic value) {
    return switch ((value ?? '').toString()) {
      'gold' => l10n.inventoryMetalGold,
      'silver' => l10n.inventoryMetalSilver,
      'platinum' => l10n.inventoryMetalPlatinum,
      'other' => l10n.inventoryMetalOther,
      _ => '—',
    };
  }

  String _statusLabel(AppLocalizations l10n, dynamic value) {
    return switch ((value ?? '').toString()) {
      'in_stock' => l10n.inventoryInStock,
      'sold' => l10n.inventorySold,
      'on_approval' => l10n.inventoryOnApproval,
      'reserved' => l10n.inventoryReserved,
      _ => '—',
    };
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
