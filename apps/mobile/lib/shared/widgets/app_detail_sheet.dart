import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

/// A single labelled value in an [AppDetailSheet].
class AppDetailRow {
  const AppDetailRow(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;

  /// Renders the value bolder/primary-coloured (e.g. a total).
  final bool emphasize;
}

/// A grouped set of [AppDetailRow]s under an optional heading.
class AppDetailSection {
  const AppDetailSection({this.heading, required this.rows});

  final String? heading;
  final List<AppDetailRow> rows;
}

/// Canonical read-only detail view (product / invoice / loan) shown as a
/// draggable bottom sheet. Consistent header, label/value rows, and actions.
class AppDetailSheet extends StatelessWidget {
  const AppDetailSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.sections = const [],
    this.actions = const [],
    this.extra,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<AppDetailSection> sections;

  /// Optional action buttons pinned under the content.
  final List<Widget> actions;

  /// Optional custom content rendered above the sections.
  final Widget? extra;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? leading,
    List<AppDetailSection> sections = const [],
    List<Widget> actions = const [],
    Widget? extra,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        maxWidth: 640,
      ),
      builder: (_) => AppDetailSheet(
        title: title,
        subtitle: subtitle,
        leading: leading,
        sections: sections,
        actions: actions,
        extra: extra,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1(context),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.text3(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonClose,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            if (extra != null) ...[
              const SizedBox(height: AppSpacing.md),
              extra!,
            ],
            for (final section in sections) ...[
              const SizedBox(height: AppSpacing.lg),
              if (section.heading != null) ...[
                Text(
                  section.heading!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.text3(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              // Group the section's rows into a single card with hairline
              // dividers — richer, clearer grouping without taller rows.
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfL(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.brd(context).withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    for (var i = 0; i < section.rows.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, color: AppColors.div(context)),
                      _DetailRowTile(row: section.rows[i]),
                    ],
                  ],
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRowTile extends StatelessWidget {
  const _DetailRowTile({required this.row});

  final AppDetailRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              row.label,
              style: TextStyle(fontSize: 13, color: AppColors.text3(context)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 5,
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: row.emphasize ? 15 : 13,
                fontWeight: row.emphasize ? FontWeight.w800 : FontWeight.w500,
                color: row.emphasize
                    ? AppColors.primary
                    : AppColors.text1(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
