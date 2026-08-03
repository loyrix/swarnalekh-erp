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
///
/// ## Why this keeps the last result on screen
///
/// Most list screens watch a *family* provider keyed by their query
/// (`itemsProvider(query)`). Changing the search text builds a **new** provider
/// instance, which starts life as `AsyncLoading` with no previous value — so a
/// naive `value.when(...)` swaps the entire body for a skeleton on every
/// keystroke. Because these screens render their search field and filters
/// *inside* the data builder, that teardown takes the search box with it and
/// the page visibly reloads while typing.
///
/// So this widget retains the last resolved value and keeps rendering it while
/// the next one loads, surfacing a thin progress bar instead. The skeleton is
/// reserved for the genuine first load, when there is nothing to show yet.
class AppStateView<T> extends StatefulWidget {
  const AppStateView({
    super.key,
    required this.value,
    required this.data,
    this.isEmpty,
    this.loading,
    this.empty,
    this.onRetry,
    this.resetKey,
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

  /// Change this to drop the retained value and show the skeleton again.
  ///
  /// Pass it when the same view switches to genuinely unrelated content (a tab
  /// or section change), where briefly showing the old list would be wrong.
  /// Query and filter changes should *not* reset — holding the previous results
  /// through those is the entire point.
  final Object? resetKey;

  @override
  State<AppStateView<T>> createState() => _AppStateViewState<T>();
}

class _AppStateViewState<T> extends State<AppStateView<T>> {
  /// Last successfully resolved value, kept so an in-flight reload doesn't
  /// blank the screen.
  T? _retained;

  @override
  void didUpdateWidget(covariant AppStateView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetKey != oldWidget.resetKey) {
      _retained = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;

    // Cache on the way through. Safe during build: it only ever feeds the very
    // next frame, and never triggers a rebuild of its own.
    if (value.hasValue && !value.hasError) {
      _retained = value.value;
    }

    if (value.hasError && !value.hasValue) {
      return AppErrorView(error: value.error, onRetry: widget.onRetry);
    }

    final resolved = value.hasValue ? value.value as T : _retained;

    // Genuine first load — nothing worth keeping on screen.
    if (resolved == null) {
      return widget.loading ?? const _ShimmerList();
    }

    final body = (widget.isEmpty?.call(resolved) ?? false)
        ? (widget.empty ?? EmptyState.noResults())
        : widget.data(resolved);

    if (!value.isLoading) return body;

    // Reloading over results already on screen: keep them, and say so quietly.
    return Stack(
      children: [
        body,
        const Positioned(top: 0, left: 0, right: 0, child: _RefreshingBar()),
      ],
    );
  }
}

/// Hairline progress bar shown while results already on screen are refreshed.
class _RefreshingBar extends StatelessWidget {
  const _RefreshingBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        minHeight: 2,
        backgroundColor: Colors.transparent,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
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
