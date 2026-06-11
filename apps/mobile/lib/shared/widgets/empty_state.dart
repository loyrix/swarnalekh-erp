import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';

/// Premium empty state widget with animated entrance, icon, and optional CTA.
///
/// Usage:
///   EmptyState.customers(onAction: () => addCustomer())
///   EmptyState.inventory(onAction: () => addItem())
///   EmptyState(icon: Icons.search, title: 'No results', subtitle: '...')
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  /// Pre-configured empty state for customers
  factory EmptyState.customers({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.people_outline_rounded,
      title: 'No customers yet',
      subtitle:
          'Start building your customer base by adding your first customer.',
      actionLabel: 'Add Customer',
      onAction: onAction,
      iconColor: AppColors.info,
    );
  }

  /// Pre-configured empty state for inventory
  factory EmptyState.inventory({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Your inventory is empty',
      subtitle: 'Add jewellery items to track stock, pricing, and sales.',
      actionLabel: 'Add First Item',
      onAction: onAction,
      iconColor: AppColors.primary,
    );
  }

  /// Pre-configured empty state for search with no results
  factory EmptyState.noResults({String query = ''}) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      subtitle: query.isNotEmpty
          ? 'No matches for "$query". Try a different search term.'
          : 'Try adjusting your filters or search term.',
      iconColor: AppColors.warning,
    );
  }

  /// Pre-configured empty state for billing
  factory EmptyState.billing({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No invoices yet',
      subtitle: 'Create your first bill to start tracking sales and revenue.',
      actionLabel: 'Create Bill',
      onAction: onAction,
      iconColor: AppColors.success,
    );
  }

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? AppColors.text3(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon container
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: color.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 40,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppColors.text1(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: AppColors.text3(context),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                // CTA button
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  GoldButton(
                    label: widget.actionLabel!,
                    icon: Icons.add_rounded,
                    onPressed: widget.onAction,
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
