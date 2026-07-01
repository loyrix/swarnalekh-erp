import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

/// Full-screen, keyboard-safe form shell with a pinned bottom action bar.
///
/// This replaces fixed-width `AlertDialog` forms (which clip on phones). Push
/// it with [AppFormScaffold.push] so heavy create/edit forms get their own
/// route, reachable from multiple entry points.
///
/// ```dart
/// final saved = await AppFormScaffold.push<bool>(
///   context,
///   title: l10n.inventoryAddStock,
///   builder: (ctx) => AddStockForm(...),
/// );
/// ```
class AppFormScaffold extends StatelessWidget {
  const AppFormScaffold({
    super.key,
    required this.title,
    required this.children,
    this.onSave,
    this.onCancel,
    this.saveLabel,
    this.cancelLabel,
    this.isSaving = false,
    this.footer,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String title;

  /// Form fields, laid out in a scrollable, keyboard-aware column.
  final List<Widget> children;

  /// Save action. When null the save button is disabled.
  final VoidCallback? onSave;

  /// Cancel action. Defaults to popping the route.
  final VoidCallback? onCancel;

  final String? saveLabel;
  final String? cancelLabel;

  /// Shows a spinner in the save button and blocks re-taps.
  final bool isSaving;

  /// Optional content shown just above the action bar (e.g. a total preview).
  final Widget? footer;

  final EdgeInsets padding;

  /// Pushes a form as a full-screen dialog route. [builder] should return an
  /// [AppFormScaffold] (which supplies its own title bar and action bar).
  static Future<T?> push<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute<T>(fullscreenDialog: true, builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: l10n.commonClose,
          icon: const Icon(Icons.close_rounded),
          onPressed: isSaving
              ? null
              : (onCancel ?? () => Navigator.of(context).maybePop()),
        ),
      ),
      body: KeyboardDismissRegion(
        child: KeyboardAwareScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
      bottomNavigationBar: _ActionBar(
        footer: footer,
        isSaving: isSaving,
        saveLabel: saveLabel ?? l10n.commonSave,
        cancelLabel: cancelLabel ?? l10n.commonCancel,
        onSave: onSave,
        onCancel: isSaving
            ? null
            : (onCancel ?? () => Navigator.of(context).maybePop()),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.saveLabel,
    required this.cancelLabel,
    required this.isSaving,
    this.footer,
    this.onSave,
    this.onCancel,
  });

  final String saveLabel;
  final String cancelLabel;
  final bool isSaving;
  final Widget? footer;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          border: Border(top: BorderSide(color: AppColors.brd(context))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (footer != null) ...[
              footer!,
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: GoldButton(
                    label: cancelLabel,
                    isOutlined: true,
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GoldButton(
                    label: saveLabel,
                    icon: Icons.check_rounded,
                    isLoading: isSaving,
                    onPressed: isSaving ? null : onSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
