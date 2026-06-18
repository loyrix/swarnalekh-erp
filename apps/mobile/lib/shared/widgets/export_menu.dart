import 'package:flutter/material.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

enum ExportFormat { pdf, excel, csv }

class ExportMenu extends StatelessWidget {
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportCsv;
  final bool isLoading;
  final String? tooltip;
  final IconData? icon;

  const ExportMenu({
    super.key,
    this.onExportPdf,
    this.onExportExcel,
    this.onExportCsv,
    this.isLoading = false,
    this.tooltip,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPdf = onExportPdf != null;
    final hasExcel = onExportExcel != null;
    final hasCsv = onExportCsv != null;

    if (!hasPdf && !hasExcel && !hasCsv) return const SizedBox.shrink();

    return PopupMenuButton<ExportFormat>(
      tooltip: tooltip ?? l10n.reportsExportPdf,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.text2(context),
              ),
            )
          : Icon(
              icon ?? Icons.download_outlined,
              color: AppColors.text2(context),
            ),
      color: AppColors.surfL(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.brd(context)),
      ),
      onSelected: (format) {
        switch (format) {
          case ExportFormat.pdf:
            onExportPdf?.call();
            break;
          case ExportFormat.excel:
            onExportExcel?.call();
            break;
          case ExportFormat.csv:
            onExportCsv?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (hasPdf)
          PopupMenuItem<ExportFormat>(
            value: ExportFormat.pdf,
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 10),
                Text(l10n.reportsExportPdf),
              ],
            ),
          ),
        if (hasExcel)
          PopupMenuItem<ExportFormat>(
            value: ExportFormat.excel,
            child: Row(
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Text('Export as Excel'),
              ],
            ),
          ),
        if (hasCsv)
          PopupMenuItem<ExportFormat>(
            value: ExportFormat.csv,
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text('Export as CSV'),
              ],
            ),
          ),
      ],
    );
  }
}

class ExportButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;
  final IconData? icon;

  const ExportButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton.filledTonal(
      tooltip: label ?? l10n.reportsExportPdf,
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textOnPrimary,
              ),
            )
          : Icon(icon ?? Icons.download_outlined, size: 18),
    );
  }
}
