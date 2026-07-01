import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';

/// Standard "advanced filters" bottom sheet. The search field stays visible on
/// the screen (via `SearchFilterBar`); everything else — date/category/branch/
/// status — lives here so mobile screens aren't buried under filter rows.
///
/// The caller owns filter state and rebuilds [builder] via the provided
/// `setState`, so selections reflect immediately inside the sheet.
///
/// ```dart
/// AppFilterSheet.show(
///   context,
///   onApply: () => applyFilters(),
///   onClear: () => clearFilters(),
///   builder: (context, setSheetState) => [ ...filter controls... ],
/// );
/// ```
class AppFilterSheet extends StatelessWidget {
  const AppFilterSheet({
    super.key,
    required this.children,
    this.onApply,
    this.onClear,
    this.title,
  });

  final List<Widget> children;
  final VoidCallback? onApply;
  final VoidCallback? onClear;
  final String? title;

  static Future<void> show(
    BuildContext context, {
    required List<Widget> Function(
      BuildContext context,
      StateSetter setSheetState,
    )
    builder,
    VoidCallback? onApply,
    VoidCallback? onClear,
    String? title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: 640,
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => AppFilterSheet(
            title: title,
            onApply: onApply == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onApply();
                  },
            onClear: onClear == null ? null : () => setSheetState(onClear),
            children: builder(context, setSheetState),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              title ?? l10n.commonFilters,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text1(context),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final child in children) ...[
                    child,
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: GoldButton(
                    label: l10n.commonClear,
                    isOutlined: true,
                    onPressed: onClear,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GoldButton(
                    label: l10n.commonApply,
                    icon: Icons.check_rounded,
                    onPressed: onApply,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
