import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/shared/widgets/section_switch.dart';

/// Standard layout for a module screen: an optional header (e.g. a stat strip),
/// an optional in-page [SectionSwitch] (Stock/Sold/Reports style tabs), and a
/// body — all wired for pull-to-refresh.
///
/// The header and section switch stay pinned; only [body] scrolls/refreshes.
/// Pair [body] with an `AppStateView` so loading/empty/error/data are handled.
class AppSectionScaffold extends StatelessWidget {
  const AppSectionScaffold({
    super.key,
    required this.body,
    this.header,
    this.sections,
    this.activeSection,
    this.onSectionChanged,
    this.onRefresh,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.bodyPadding = EdgeInsets.zero,
  });

  /// Pinned content above the section switch (stat strip, alerts, etc.).
  final Widget? header;

  /// In-page tabs. When null (or empty), no switch is rendered.
  final List<SectionItem>? sections;
  final String? activeSection;
  final ValueChanged<String>? onSectionChanged;

  /// Enables pull-to-refresh around [body] when provided.
  final Future<void> Function()? onRefresh;

  /// The scrollable body — typically an `AppStateView`.
  final Widget body;

  /// Padding applied to [header] and the section switch.
  final EdgeInsets padding;

  /// Padding applied around [body].
  final EdgeInsets bodyPadding;

  bool get _hasSections =>
      sections != null &&
      sections!.isNotEmpty &&
      activeSection != null &&
      onSectionChanged != null;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: bodyPadding, child: body);
    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.primary,
        child: content,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: padding.copyWith(bottom: AppSpacing.sm),
            child: header,
          ),
        if (_hasSections)
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              header == null ? padding.top : 0,
              padding.right,
              AppSpacing.sm,
            ),
            child: SectionSwitch(
              activeValue: activeSection!,
              items: sections!,
              onChanged: onSectionChanged!,
            ),
          ),
        Expanded(child: content),
      ],
    );
  }
}
