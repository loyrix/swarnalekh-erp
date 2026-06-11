import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

class KeyboardDismissRegion extends StatelessWidget {
  final Widget child;

  const KeyboardDismissRegion({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}

class KeyboardAwareScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool centerContent;
  final Alignment alignment;
  final bool safeArea;
  final ScrollController? controller;

  const KeyboardAwareScrollView({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.centerContent = false,
    this.alignment = Alignment.center,
    this.safeArea = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    Widget scrollView = LayoutBuilder(
      builder: (context, constraints) {
        final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
        final effectivePadding = padding.copyWith(
          bottom: padding.bottom + keyboardBottom,
        );
        final minHeight = math.max(
          0.0,
          constraints.maxHeight - effectivePadding.vertical,
        );

        final content = ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: centerContent
              ? Align(alignment: alignment, child: child)
              : child,
        );

        return SingleChildScrollView(
          controller: controller,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: effectivePadding,
          child: content,
        );
      },
    );

    if (safeArea) {
      scrollView = SafeArea(child: scrollView);
    }

    return scrollView;
  }
}
