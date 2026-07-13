import 'package:fl_chart/fl_chart.dart';
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
        // Overview before the trend graph (req §5.1) — the numbers are what
        // the owner checks first.
        StaggeredSection(
          index: 2,
          child: CompactStatStrip(stats: _stats(context, data.stats, isWide)),
        ),
        if (data.stats.categoryStockAlerts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            index: 3,
            child: _StockAlertsCard(alerts: data.stats.categoryStockAlerts),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          index: 4,
          child: _SalesTrendChart(points: data.stats.salesTrend),
        ),
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

    final actions = <Widget>[
      _chip(
        context,
        Icons.receipt_long_rounded,
        l10n.dashboardNewBill,
        () => context.go('/billing'),
      ),
      if (canManage)
        _chip(
          context,
          Icons.add_box_rounded,
          l10n.inventoryAddItem,
          () => context.go('/inventory'),
        ),
      if (canManage)
        _chip(
          context,
          Icons.account_balance_rounded,
          l10n.dashboardAddMortgage,
          () => context.go('/mortgage'),
        ),
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
// SALES TREND CHART (real 7-day data)
// ==========================================================================

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.points});

  final List<SalesTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final maxTotal = points.fold<double>(
      0,
      (m, p) => p.total > m ? p.total : m,
    );

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardSalesLast7Days,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.text1(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (maxTotal <= 0)
            // Compact empty state — no giant dead box.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 18,
                    color: AppColors.text3(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.dashboardNoRecentSales,
                    style: TextStyle(color: AppColors.text3(context)),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 240,
              child: _buildChart(context, locale, maxTotal),
            ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, String locale, double maxTotal) {
    final interval = maxTotal / 4;
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppColors.div(context), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final date = points[i].parsedDate;
                final label = date == null
                    ? ''
                    : DateFormat.E(locale).format(date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.text3(context),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                _formatMoney(value),
                style: TextStyle(color: AppColors.text3(context), fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].total),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),
        ],
      ),
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
