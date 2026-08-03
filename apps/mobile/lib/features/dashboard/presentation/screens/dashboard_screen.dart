import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/dashboard/application/dashboard_providers.dart';
import 'package:swarnbook/features/dashboard/data/models/dashboard_data.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/staggered_animation.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    return AppStateView<DashboardData>(
      value: async,
      loading: const _DashboardShimmer(),
      onRetry: () => ref.invalidate(dashboardProvider),
      data: (data) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _DashboardContent(data: data),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final isWide = AppDensity.isExpanded(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredSection(index: 0, child: _WelcomeBanner(data: data)),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(index: 1, child: _QuickActions(role: data.role)),
        const SizedBox(height: AppSpacing.lg),
        // The overview numbers are what the owner checks first.
        StaggeredSection(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: AppLocalizations.of(context)!.dashboardBusinessOverview,
              ),
              const SizedBox(height: AppSpacing.sm),
              CompactStatStrip(stats: _stats(context, data.stats, isWide)),
            ],
          ),
        ),
        if (data.stats.categoryStockAlerts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            index: 3,
            child: _StockAlertsCard(alerts: data.stats.categoryStockAlerts),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const StaggeredSection(index: 4, child: _SecurityAssuranceCard()),
      ],
    );
  }

  List<({IconData icon, String label, String value, Color color})> _stats(
    BuildContext context,
    DashboardStats s,
    bool isWide,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return [
      (
        icon: Icons.scale_rounded,
        label: l10n.dashboardTotalGoldStock,
        value: _formatWeight(s.totalGoldStock),
        color: AppColors.gold,
      ),
      (
        icon: Icons.scale_outlined,
        label: l10n.dashboardTotalSilverStock,
        value: _formatWeight(s.totalSilverStock),
        color: AppColors.silver,
      ),
      (
        icon: Icons.inventory_2_rounded,
        label: l10n.dashboardInventoryValue,
        value: _formatMoney(s.totalInventoryValue),
        color: AppColors.primary,
      ),
      (
        icon: Icons.trending_up_rounded,
        label: l10n.dashboardMonthlyRevenue,
        value: _formatMoney(s.monthlyRevenue),
        color: AppColors.primary,
      ),
      (
        icon: Icons.account_balance_wallet_rounded,
        label: l10n.dashboardPendingInterest,
        value: _formatMoney(s.pendingMortgageInterest),
        // Amber is a genuine "needs attention" cue (interest owed).
        color: AppColors.warning,
      ),
      (
        icon: Icons.account_balance_rounded,
        label: l10n.dashboardActiveLoans,
        value: '${s.activeLoans}',
        color: AppColors.primary,
      ),
      (
        icon: Icons.point_of_sale_rounded,
        label: l10n.dashboardTodaysSales,
        value: _formatMoney(s.todaysSales),
        color: AppColors.primary,
      ),
      (
        icon: Icons.receipt_long_rounded,
        label: l10n.dashboardTotalBills,
        value: '${s.totalBillsGenerated}',
        color: AppColors.primary,
      ),
      (
        icon: Icons.shopping_bag_rounded,
        label: l10n.dashboardSoldProducts,
        value: '${s.soldProductsThisMonth}',
        color: AppColors.primary,
      ),
    ];
  }
}

// ==========================================================================
// STOCK ALERTS (out of stock / low stock by category threshold — req §3.2)
// ==========================================================================

class _StockAlertsCard extends StatelessWidget {
  const _StockAlertsCard({required this.alerts});

  final List<CategoryStockAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final outCount = alerts.where((a) => a.isOut).length;
    final color = outCount > 0 ? AppColors.error : AppColors.warning;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _showAlerts(context, l10n),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.production_quantity_limits_rounded, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardStockAlertsTitle,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      l10n.dashboardStockAlertsSubtitle(alerts.length),
                      style: TextStyle(
                        color: AppColors.text2(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.text3(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlerts(BuildContext context, AppLocalizations l10n) {
    final out = alerts.where((a) => a.isOut).toList();
    final low = alerts.where((a) => !a.isOut).toList();
    AppDetailSheet.show(
      context,
      title: l10n.dashboardStockAlertsTitle,
      sections: [
        if (out.isNotEmpty)
          AppDetailSection(
            heading: l10n.dashboardStockAlertOut,
            rows: [
              for (final alert in out)
                AppDetailRow(
                  alert.prefix == null
                      ? alert.name
                      : '${alert.name} (${alert.prefix})',
                  l10n.dashboardStockAlertCounts(
                    alert.inStockCount,
                    alert.minStockThreshold,
                  ),
                ),
            ],
          ),
        if (low.isNotEmpty)
          AppDetailSection(
            heading: l10n.dashboardStockAlertLow,
            rows: [
              for (final alert in low)
                AppDetailRow(
                  alert.prefix == null
                      ? alert.name
                      : '${alert.name} (${alert.prefix})',
                  l10n.dashboardStockAlertCounts(
                    alert.inStockCount,
                    alert.minStockThreshold,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ==========================================================================
// WELCOME BANNER
// ==========================================================================

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.data});

  final DashboardData data;

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.dashboardGoodMorning;
    if (hour < 17) return l10n.dashboardGoodAfternoon;
    return l10n.dashboardGoodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = AppDensity.isExpanded(context);
    final locale = Localizations.localeOf(context).toString();
    final displayName = data.userName.isNotEmpty
        ? data.userName
        : l10n.dashboardOwnerFallback;
    final shopDisplay = data.shopName.isNotEmpty
        ? data.shopName
        : l10n.dashboardShopFallback;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.isDark(context)
            ? const LinearGradient(
                colors: [Color(0xFF201D16), Color(0xFF2B2619)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF9F7F3), Color(0xFFF1ECE3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: AppColors.isDark(context) ? 0.22 : 0.3,
          ),
        ),
        boxShadow: AppShadows.soft(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting(l10n)}, $displayName',
                  style: isWide
                      ? Theme.of(context).textTheme.displaySmall
                      : Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                ),
                if (isWide) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    shopDisplay,
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DateFormat.yMMMMEEEEd(locale).format(DateTime.now()),
                  style: TextStyle(
                    color: AppColors.text3(context),
                    fontSize: isWide ? 12 : 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: isWide ? 80 : 48,
            height: isWide ? 80 : 48,
            decoration: BoxDecoration(
              gradient: AppColors.goldShimmer,
              borderRadius: BorderRadius.circular(
                isWide ? AppRadius.lg : AppRadius.md,
              ),
              boxShadow: AppShadows.goldGlow,
            ),
            child: Icon(
              Icons.diamond_rounded,
              color: AppColors.textOnPrimary,
              size: isWide ? 36 : 24,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// QUICK ACTIONS
// ==========================================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = isAdminRole(role);

    // New Bill / Add Item / Add Mortgage deliberately omitted — they already sit
    // in the main menu bar, so repeating them here is pure duplication.
    final actions = <Widget>[
      if (canManage)
        _chip(
          context,
          Icons.sell_rounded,
          l10n.dashboardSetRates,
          () => context.go('/rates'),
        ),
      _chip(
        context,
        Icons.search_rounded,
        l10n.dashboardSearchProduct,
        () => context.go('/search'),
      ),
      _chip(
        context,
        Icons.person_search_rounded,
        l10n.dashboardSearchCustomer,
        () => context.go('/customers'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.dashboardQuickActions),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    // Uniform gold action chips — one brand accent, not a rainbow.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text1(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// SECURITY ASSURANCE
// ==========================================================================

/// Quiet trust panel for the shop owner.
///
/// Every line here states something the app **actually does today**:
///   - passwords are hashed with bcrypt (`bcryptjs`, apps/api)
///   - session tokens live in `flutter_secure_storage` (Keychain / Keystore)
///   - every API query is tenant-scoped, so shops cannot see each other's data
///
/// Do not add claims here (encryption at rest, backups, device lock,
/// certifications) until they are genuinely implemented — an overstated promise
/// about a jeweller's business records is worse than saying nothing.
class _SecurityAssuranceCard extends StatelessWidget {
  const _SecurityAssuranceCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        // A soft champagne wash instead of a flat surface, so the panel reads
        // as a seal closing the page rather than one more stat card.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.32)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _emblem(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.dashboardSecurityTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: AppColors.text1(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _badge(context, l10n.dashboardSecurityBadge),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.dashboardSecuritySubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.text2(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
          const SizedBox(height: AppSpacing.md),
          _point(context, Icons.lock_rounded, l10n.dashboardSecurityPointLogin),
          const SizedBox(height: 10),
          _point(
            context,
            Icons.phonelink_lock_rounded,
            l10n.dashboardSecurityPointDevice,
          ),
          const SizedBox(height: 10),
          _point(
            context,
            Icons.storefront_rounded,
            l10n.dashboardSecurityPointIsolation,
          ),
        ],
      ),
    );
  }

  /// Gold shield plate — the single focal point that carries the reassurance.
  Widget _emblem() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.verified_user_rounded,
        size: 24,
        color: AppColors.textOnPrimary,
      ),
    );
  }

  /// Small "Protected" pill. Success green is the one non-gold accent allowed
  /// here, because it is a status and not decoration.
  Widget _badge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 11,
            color: AppColors.success,
          ),
          const SizedBox(width: 3),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _point(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Icon(icon, size: 13, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.text2(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// SHIMMER
// ==========================================================================

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWelcomeBanner(),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: List.generate(
              4,
              (_) => const SizedBox(width: 150, child: ShimmerStatCard()),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// FORMATTERS
// ==========================================================================

double _num(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _formatWeight(dynamic value) {
  final grams = _num(value);
  if (grams >= 1000) return '${(grams / 1000).toStringAsFixed(2)} kg';
  return '${grams.toStringAsFixed(3)} g';
}

String _formatMoney(dynamic value) {
  final amount = _num(value);
  if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
  if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)}L';
  if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
  return '₹${amount.toStringAsFixed(0)}';
}
