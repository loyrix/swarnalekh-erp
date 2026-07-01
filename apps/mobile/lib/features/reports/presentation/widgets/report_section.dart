import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';

/// View-model for one report row (already resolved to display strings).
class ReportRow {
  const ReportRow({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.statusColor,
    this.metrics = const [],
  });

  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color? statusColor;
  final List<(String, String)> metrics;
}

/// A titled report card: heading + subtitle + headline metric + export action,
/// then a list of rows rendered with the canonical [CompactDataRow].
class ReportSection extends StatelessWidget {
  const ReportSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.rows,
    this.metricValue,
    this.metricColor,
    this.onExport,
  });

  final String title;
  final String subtitle;
  final String emptyText;
  final List<ReportRow> rows;
  final String? metricValue;
  final Color? metricColor;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.text3(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                metricValue ?? '${rows.length}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: metricColor ?? AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ExportMenu(onExportPdf: onExport),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfL(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.brd(context)),
              ),
              child: Text(
                emptyText,
                style: TextStyle(color: AppColors.text3(context)),
              ),
            )
          else
            for (final row in rows)
              CompactDataRow(
                leading: _iconLeading(context, row.leadingIcon),
                title: row.title,
                subtitle: row.subtitle,
                metrics: row.metrics,
                trailing: StatusBadge(
                  label: row.statusLabel,
                  color: row.statusColor,
                ),
              ),
        ],
      ),
    );
  }

  Widget _iconLeading(BuildContext context, IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 18, color: AppColors.primary),
    );
  }
}
