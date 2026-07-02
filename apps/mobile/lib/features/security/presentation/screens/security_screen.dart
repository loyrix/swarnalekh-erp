import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/security/application/security_payloads.dart';
import 'package:swarnbook/features/security/application/security_providers.dart';
import 'package:swarnbook/features/security/data/models/activity_log.dart';
import 'package:swarnbook/features/security/data/security_repository.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _searchController = TextEditingController();

  SecurityQuery _query = const SecurityQuery();
  bool _isExportingBackup = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(activityLogsProvider(_query));
    await ref.read(activityLogsProvider(_query).future);
  }

  void _submitSearch(String value) {
    setState(() => _query = _query.copyWith(search: value));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = _query.copyWith(search: ''));
  }

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context)!;
    String entity = _query.entityType;
    String action = _query.action;

    await AppFilterSheet.show(
      context,
      title: l10n.commonFilters,
      onApply: () => setState(
        () => _query = _query.copyWith(entityType: entity, action: action),
      ),
      onClear: () {
        entity = 'all';
        action = 'all';
      },
      builder: (context, setSheetState) => [
        DropdownButtonFormField<String>(
          initialValue: entity,
          decoration: InputDecoration(
            labelText: l10n.securityFilterArea,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(l10n.securityFilterAllAreas),
            ),
            DropdownMenuItem(
              value: 'inventory',
              child: Text(l10n.securityFilterInventory),
            ),
            DropdownMenuItem(
              value: 'customers',
              child: Text(l10n.securityFilterCustomers),
            ),
            DropdownMenuItem(
              value: 'invoices',
              child: Text(l10n.securityFilterBilling),
            ),
            DropdownMenuItem(
              value: 'mortgage',
              child: Text(l10n.securityFilterMortgage),
            ),
            DropdownMenuItem(
              value: 'daily_rate',
              child: Text(l10n.securityFilterRates),
            ),
            DropdownMenuItem(
              value: 'backup',
              child: Text(l10n.securityFilterBackup),
            ),
          ],
          onChanged: (value) => setSheetState(() => entity = value ?? 'all'),
        ),
        DropdownButtonFormField<String>(
          initialValue: action,
          decoration: InputDecoration(
            labelText: l10n.securityFilterAction,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(l10n.securityFilterAllActions),
            ),
            DropdownMenuItem(
              value: 'create',
              child: Text(l10n.securityActionCreate),
            ),
            DropdownMenuItem(
              value: 'update',
              child: Text(l10n.securityActionUpdate),
            ),
            DropdownMenuItem(
              value: 'delete',
              child: Text(l10n.securityActionDelete),
            ),
            DropdownMenuItem(
              value: 'payment',
              child: Text(l10n.securityActionPayment),
            ),
            DropdownMenuItem(
              value: 'close',
              child: Text(l10n.securityActionClose),
            ),
            DropdownMenuItem(
              value: 'backup_export',
              child: Text(l10n.securityActionBackupExport),
            ),
          ],
          onChanged: (value) => setSheetState(() => action = value ?? 'all'),
        ),
      ],
    );
  }

  Future<void> _exportBackup() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExportingBackup = true);
    try {
      final payload = await ref.read(securityRepositoryProvider).createBackup();
      final uri = Uri.dataFromBytes(payload.bytes, mimeType: payload.mimeType);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      setState(() => _isExportingBackup = false);
      if (launched) {
        AppToast.success(context, l10n.securityBackupReady(payload.fileName));
      } else {
        _showBackupPreview(payload);
      }
      ref.invalidate(activityLogsProvider(_query));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isExportingBackup = false);
      AppToast.error(context, l10n.errorFailedGenerateBackup);
    }
  }

  void _showBackupPreview(BackupPayload payload) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(payload.fileName),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: SelectableText(
              payload.text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(activityLogsProvider(_query));
    final latestBackup = async.valueOrNull?.latestBackup;

    return AppSectionScaffold(
      onRefresh: _refresh,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackupPanel(
            latestBackup: latestBackup,
            isBusy: _isExportingBackup,
            onExport: _exportBackup,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _submitSearch,
                  decoration: InputDecoration(
                    hintText: l10n.securitySearchLogs,
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.commonClearSearch,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: _clearSearch,
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: l10n.commonFilters,
                onPressed: _openFilters,
                icon: Badge(
                  isLabelVisible: _query.hasActiveFilters,
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AppStateView<ActivityLogPage>(
        value: async,
        onRetry: () => ref.invalidate(activityLogsProvider(_query)),
        data: (page) {
          if (page.logs.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Icons.shield_outlined,
                  title: l10n.securityNoLogsFound,
                  subtitle: l10n.securitySubtitle,
                  iconColor: AppColors.primary,
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: page.logs.length,
            itemBuilder: (context, index) => _logRow(l10n, page.logs[index]),
          );
        },
      ),
    );
  }

  Widget _logRow(AppLocalizations l10n, ActivityLog log) {
    final color = _actionColor(log.action);
    return CompactDataRow(
      leading: Container(
        alignment: Alignment.center,
        color: color.withValues(alpha: 0.12),
        child: Icon(_actionIcon(log.action), color: color, size: 20),
      ),
      title: _label(log.entityType),
      subtitle: [
        log.userName ?? l10n.securityFeatures,
        _formatDateTime(log.createdAt),
      ].join(' • '),
      trailing: StatusBadge(label: _label(log.action), color: color),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  String _label(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Color _actionColor(String action) {
    return switch (action) {
      'delete' => AppColors.error,
      'update' => AppColors.info,
      'payment' => AppColors.success,
      'close' => AppColors.warning,
      'backup_export' => AppColors.primary,
      _ => AppColors.success,
    };
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'delete' => Icons.delete_outline_rounded,
      'update' => Icons.edit_rounded,
      'payment' => Icons.payments_rounded,
      'close' => Icons.lock_rounded,
      'backup_export' => Icons.cloud_download_rounded,
      _ => Icons.add_rounded,
    };
  }
}

class _BackupPanel extends StatelessWidget {
  const _BackupPanel({
    required this.latestBackup,
    required this.isBusy,
    required this.onExport,
  });

  final ActivityLog? latestBackup;
  final bool isBusy;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.cloud_download_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.securityDataBackup,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  latestBackup == null
                      ? l10n.securityNoBackupYet
                      : l10n.securityLastExport(
                          _formatDate(latestBackup!.createdAt),
                        ),
                  style: TextStyle(
                    color: AppColors.text3(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GoldButton(
            label: l10n.securityExportBackup,
            icon: Icons.cloud_download_rounded,
            isLoading: isBusy,
            onPressed: isBusy ? null : onExport,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
