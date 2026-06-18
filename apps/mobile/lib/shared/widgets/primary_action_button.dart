import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

enum PrimaryActionStyle { fab, goldButton, outlined, text }

class PrimaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final PrimaryActionStyle style;
  final bool isLoading;
  final bool isWide;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final String? heroTag;

  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.style = PrimaryActionStyle.goldButton,
    this.isLoading = false,
    this.isWide = true,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.heroTag,
  });

  factory PrimaryActionButton.fab({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    bool isLoading = false,
    String? heroTag,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return PrimaryActionButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      style: PrimaryActionStyle.fab,
      isLoading: isLoading,
      isWide: false,
      heroTag: heroTag,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }

  factory PrimaryActionButton.goldButton({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    bool isLoading = false,
    bool isWide = true,
    String? tooltip,
  }) {
    return PrimaryActionButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      style: PrimaryActionStyle.goldButton,
      isLoading: isLoading,
      isWide: isWide,
      tooltip: tooltip,
    );
  }

  factory PrimaryActionButton.outlined({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    bool isLoading = false,
    String? tooltip,
  }) {
    return PrimaryActionButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      style: PrimaryActionStyle.outlined,
      isLoading: isLoading,
      isWide: true,
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon;
    switch (style) {
      case PrimaryActionStyle.fab:
        return FloatingActionButton.small(
          heroTag: heroTag ?? 'primaryAction',
          onPressed: isLoading ? null : onPressed,
          tooltip: tooltip ?? label,
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor ?? AppColors.textOnPrimary,
                  ),
                )
              : Icon(effectiveIcon ?? Icons.add_rounded),
        );

      case PrimaryActionStyle.goldButton:
        if (!isWide) {
          return FloatingActionButton.small(
            heroTag: heroTag ?? 'primaryAction',
            onPressed: isLoading ? null : onPressed,
            tooltip: tooltip ?? label,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Icon(effectiveIcon ?? Icons.add_rounded),
          );
        }
        return _GoldButtonWidget(
          label: label,
          icon: effectiveIcon,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
        );

      case PrimaryActionStyle.outlined:
        if (effectiveIcon != null) {
          return OutlinedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(effectiveIcon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(label),
        );

      case PrimaryActionStyle.text:
        if (effectiveIcon != null) {
          return TextButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(effectiveIcon, size: 18),
            label: Text(label),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          );
        }
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: Text(label),
        );
    }
  }
}

class _GoldButtonWidget extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoldButtonWidget({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppColors.goldGradient : null,
        color: onPressed == null ? AppColors.surfL(context) : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: onPressed == null
            ? Border.all(color: AppColors.brd(context))
            : null,
        boxShadow: onPressed != null ? AppShadows.goldGlow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: 18, color: AppColors.textOnPrimary),
                if (icon != null || isLoading) const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: onPressed != null
                        ? AppColors.textOnPrimary
                        : AppColors.text3(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
