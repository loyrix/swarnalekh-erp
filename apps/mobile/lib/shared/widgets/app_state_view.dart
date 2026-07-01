import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/empty_state.dart';
import 'package:swarnbook/shared/widgets/shimmer_loading.dart';

/// Canonical async-state wrapper for every data view in the app.
///
/// Renders exactly one of the four states (loading / error / empty / data)
/// from a Riverpod [AsyncValue], so screens never re-implement this branching.
///
/// ```dart
/// AppStateView<List<Item>>(
///   value: ref.watch(itemsProvider),
///   isEmpty: (items) => items.isEmpty,
///   onRetry: () => ref.invalidate(itemsProvider),
///   empty: EmptyState.inventory(onAction: addItem),
///   data: (items) => ItemList(items),
/// )
/// ```
class AppStateView<T> extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.value,
    required this.data,
    this.isEmpty,
    this.loading,
    this.empty,
    this.onRetry,
  });

  /// The async state to render.
  final AsyncValue<T> value;

  /// Builds the success UI. Only called for non-empty data.
  final Widget Function(T data) data;

  /// Predicate deciding whether loaded [data] should show the empty state.
  final bool Function(T data)? isEmpty;

  /// Optional custom loading skeleton. Defaults to a shimmer list.
  final Widget? loading;

  /// Optional custom empty view. Defaults to a generic "no results" state.
  final Widget? empty;

  /// Invoked by the error view's retry button. Hidden when null.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: false,
      loading: () => loading ?? const _ShimmerList(),
      error: (error, _) => AppErrorView(error: error, onRetry: onRetry),
      data: (resolved) {
        if (isEmpty?.call(resolved) ?? false) {
          return empty ?? EmptyState.noResults();
        }
        return data(resolved);
      },
    );
  }
}

/// Standard error state with an optional retry action. Public so screens that
/// don't use [AsyncValue] can still render a consistent error UI.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.error, this.onRetry, this.message});

  final Object? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.commonErrorTitle,
              style: TextStyle(
                color: AppColors.text1(context),
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ?? _describe(error) ?? l10n.commonErrorBody,
              style: TextStyle(
                color: AppColors.text3(context),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GoldButton(
                label: l10n.commonRetry,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _describe(Object? error) {
    if (error == null) return null;
    final text = error.toString();
    return text.isEmpty ? null : text;
  }
}

/// Default loading skeleton: a short shimmer list that reads as content.
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: const [
        ShimmerListTile(),
        ShimmerListTile(),
        ShimmerListTile(),
        ShimmerListTile(),
        ShimmerListTile(),
      ],
    );
  }
}
