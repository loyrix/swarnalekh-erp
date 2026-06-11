import 'package:flutter/material.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/security/application/security_payloads.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _api = ApiClient();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isExportingBackup = false;
  String _entityFilter = 'all';
  String _actionFilter = 'all';
  List<Map<String, dynamic>> _logs = const [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/security/activity-logs',
        queryParameters: {
          'limit': 50,
          if (_searchController.text.trim().isNotEmpty)
            'search': _searchController.text.trim(),
          if (_entityFilter != 'all') 'entityType': _entityFilter,
          if (_actionFilter != 'all') 'action': _actionFilter,
        },
      );

      if (!mounted) return;
      setState(() {
        _logs = parseActivityLogs(response.data ?? const {});
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(context, 'Failed to load activity logs');
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isExportingBackup = true);
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/security/backup',
      );
      final payload = decodeBackupPayload(response.data ?? const {});
      final uri = Uri.dataFromBytes(payload.bytes, mimeType: payload.mimeType);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;
      setState(() => _isExportingBackup = false);
      if (launched) {
        AppToast.success(context, 'Backup generated: ${payload.fileName}');
      } else {
        _showBackupPreview(payload);
      }
      await _loadLogs();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isExportingBackup = false);
      AppToast.error(context, 'Failed to generate backup');
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onExportBackup: _exportBackup, isBusy: _isExportingBackup),
            const SizedBox(height: AppSpacing.lg),
            _buildBackupPanel(),
            const SizedBox(height: AppSpacing.lg),
            _buildFilters(),
            const SizedBox(height: AppSpacing.lg),
            _buildActivityLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupPanel() {
    final latest = _latestBackupLog();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Data Backup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Export tenant data for customers, inventory, billing, mortgage, reports source data, and activity logs.',
                  style: TextStyle(color: AppColors.text3(context)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  latest == null
                      ? 'No backup export recorded yet.'
                      : 'Last export: ${_formatDateTime(latest['createdAt'])}',
                  style: TextStyle(
                    color: AppColors.text2(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _latestBackupLog() {
    for (final log in _logs) {
      if (log['action']?.toString() == 'backup_export') {
        return log;
      }
    }
    return null;
  }

  Widget _buildFilters() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 780;
          final controls = [
            SizedBox(
              width: isWide ? 320 : constraints.maxWidth,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search activity logs',
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _loadLogs();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onSubmitted: (_) => _loadLogs(),
              ),
            ),
            SizedBox(
              width: isWide ? 180 : constraints.maxWidth,
              child: DropdownButtonFormField<String>(
                initialValue: _entityFilter,
                decoration: const InputDecoration(labelText: 'Area'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Areas')),
                  DropdownMenuItem(
                    value: 'inventory',
                    child: Text('Inventory'),
                  ),
                  DropdownMenuItem(
                    value: 'customers',
                    child: Text('Customers'),
                  ),
                  DropdownMenuItem(value: 'invoices', child: Text('Billing')),
                  DropdownMenuItem(value: 'mortgage', child: Text('Mortgage')),
                  DropdownMenuItem(value: 'daily_rate', child: Text('Rates')),
                  DropdownMenuItem(value: 'backup', child: Text('Backup')),
                ],
                onChanged: (value) {
                  setState(() => _entityFilter = value ?? 'all');
                  _loadLogs();
                },
              ),
            ),
            SizedBox(
              width: isWide ? 180 : constraints.maxWidth,
              child: DropdownButtonFormField<String>(
                initialValue: _actionFilter,
                decoration: const InputDecoration(labelText: 'Action'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Actions')),
                  DropdownMenuItem(value: 'create', child: Text('Create')),
                  DropdownMenuItem(value: 'update', child: Text('Update')),
                  DropdownMenuItem(value: 'delete', child: Text('Delete')),
                  DropdownMenuItem(value: 'payment', child: Text('Payment')),
                  DropdownMenuItem(value: 'close', child: Text('Close')),
                  DropdownMenuItem(
                    value: 'backup_export',
                    child: Text('Backup Export'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _actionFilter = value ?? 'all');
                  _loadLogs();
                },
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Refresh logs',
              onPressed: _loadLogs,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ];

          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: controls,
          );
        },
      ),
    );
  }

  Widget _buildActivityLogs() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Activity Logs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                '${_logs.length} shown',
                style: TextStyle(color: AppColors.text3(context)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No activity logs found.',
                  style: TextStyle(color: AppColors.text3(context)),
                ),
              ),
            )
          else
            ..._logs.map(_buildLogTile),
        ],
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final user = log['user'] is Map
        ? Map<String, dynamic>.from(log['user'] as Map)
        : const <String, dynamic>{};
    final action = log['action']?.toString() ?? 'activity';
    final entityType = log['entityType']?.toString() ?? 'system';
    final userName = user['name']?.toString() ?? 'System';
    final createdAt = _formatDateTime(log['createdAt']);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.div(context), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _actionColor(action).withValues(alpha: 0.12),
            child: Icon(
              _actionIcon(action),
              color: _actionColor(action),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusBadge(
                      label: _label(action),
                      color: _actionColor(action),
                    ),
                    StatusBadge(label: _label(entityType)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$userName performed ${_label(action)} on ${_label(entityType)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  createdAt,
                  style: TextStyle(color: AppColors.text3(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    final local = parsed.toLocal();
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

class _Header extends StatelessWidget {
  final VoidCallback onExportBackup;
  final bool isBusy;

  const _Header({required this.onExportBackup, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Features',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Activity logs and data backup for the shop.',
                style: TextStyle(color: AppColors.text3(context)),
              ),
            ],
          ),
        ),
        GoldButton(
          label: 'Export Backup',
          icon: Icons.cloud_download_rounded,
          isLoading: isBusy,
          onPressed: onExportBackup,
        ),
      ],
    );
  }
}
