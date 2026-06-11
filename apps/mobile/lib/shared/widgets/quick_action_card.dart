import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

/// Dashboard quick action card with icon, label, and tap animation.
///
/// Usage:
///   QuickActionCard(
///     icon: Icons.receipt_long_rounded,
///     label: 'New Bill',
///     color: AppColors.success,
///     onTap: () => context.go('/billing'),
///   )
class QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: _isHovered
                  ? LinearGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.12),
                        widget.color.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppColors.cardGrad(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.3)
                    : AppColors.isDark(context)
                    ? AppColors.glassBorder
                    : AppColors.glassBorderLight,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : AppShadows.forCard(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(height: AppSpacing.md),

                // Label
                Text(
                  widget.label,
                  style: TextStyle(
                    color: AppColors.text1(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),

                // Subtitle
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: AppColors.text3(context),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
