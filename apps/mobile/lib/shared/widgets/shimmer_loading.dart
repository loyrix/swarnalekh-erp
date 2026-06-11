import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

/// Gold-tinted shimmer animation for premium loading states.
///
/// Usage:
///   ShimmerBox(width: 200, height: 20)
///   ShimmerStatCard()
///   ShimmerRateRow()
///   ShimmerListTile()

class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final baseColor = isDark
        ? const Color(0xFF1E1E2D)
        : const Color(0xFFE8E5DF);
    final highlightColor = isDark
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.06);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer skeleton that mirrors the StatCard layout
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cardGrad(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.isDark(context)
              ? AppColors.glassBorder
              : AppColors.glassBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerBox(width: 42, height: 42, borderRadius: AppRadius.md),
          const SizedBox(height: AppSpacing.md),
          const ShimmerBox(width: 60, height: 28),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(width: 80, height: 14),
          const SizedBox(height: AppSpacing.xs),
          const ShimmerBox(width: 100, height: 12),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for a rate row in the dashboard
class ShimmerRateRow extends StatelessWidget {
  const ShimmerRateRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ShimmerBox(width: 10, height: 10, borderRadius: AppRadius.full),
          const SizedBox(width: 12),
          const ShimmerBox(width: 70, height: 14),
          const Spacer(),
          const ShimmerBox(width: 90, height: 16),
          const SizedBox(width: 12),
          ShimmerBox(width: 50, height: 22, borderRadius: AppRadius.full),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for customer list tile
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          ShimmerBox(width: 46, height: 46, borderRadius: AppRadius.md),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 14, borderRadius: 6),
                const SizedBox(height: 6),
                ShimmerBox(width: 90, height: 12, borderRadius: 6),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerBox(width: 60, height: 14, borderRadius: 6),
              const SizedBox(height: 4),
              ShimmerBox(width: 40, height: 11, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for inventory grid card
class ShimmerGridCard extends StatelessWidget {
  const ShimmerGridCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.cardGrad(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 50, height: 20, borderRadius: AppRadius.sm),
              ShimmerBox(width: 60, height: 20, borderRadius: AppRadius.full),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ShimmerBox(width: 48, height: 48, borderRadius: AppRadius.md),
          const SizedBox(height: AppSpacing.md),
          const ShimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(width: 80, height: 12),
          const Spacer(),
          Row(
            children: [
              const ShimmerBox(width: 50, height: 12),
              const SizedBox(width: 14),
              const ShimmerBox(width: 40, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the welcome banner
class ShimmerWelcomeBanner extends StatelessWidget {
  const ShimmerWelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cardGrad(context),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.brd(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 220, height: 24, borderRadius: 8),
                const SizedBox(height: AppSpacing.sm),
                ShimmerBox(width: 160, height: 15, borderRadius: 6),
              ],
            ),
          ),
          ShimmerBox(width: 80, height: 80, borderRadius: AppRadius.lg),
        ],
      ),
    );
  }
}
