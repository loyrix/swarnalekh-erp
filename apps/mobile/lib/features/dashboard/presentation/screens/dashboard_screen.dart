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
        StaggeredSection(
          index: 2,
          child: _SalesTrendChart(points: data.stats.salesTrend),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          index: 3,
          child: CompactStatStrip(stats: _stats(context, data.stats, isWide)),
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
        color: AppColors.success,
      ),
      (
        icon: Icons.account_balance_wallet_rounded,
        label: l10n.dashboardPendingInterest,
        value: _formatMoney(s.pendingMortgageInterest),
        color: AppColors.warning,
      ),
      (
        icon: Icons.account_balance_rounded,
        label: l10n.dashboardActiveLoans,
        value: '${s.activeLoans}',
        color: AppColors.info,
      ),
      (
        icon: Icons.point_of_sale_rounded,
        label: l10n.dashboardTodaysSales,
        value: _formatMoney(s.todaysSales),
        color: AppColors.success,
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
        color: AppColors.info,
      ),
    ];
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
                colors: [Color(0xFF1A1533), Color(0xFF261E42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF9F6F0), Color(0xFFEAE4D3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: AppColors.isDark(context) ? 0.15 : 0.3,
          ),
        ),
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
        AppColors.success,
        () => context.go('/billing'),
      ),
      if (canManage)
        _chip(
          context,
          Icons.add_box_rounded,
          l10n.inventoryAddItem,
          AppColors.info,
          () => context.go('/inventory'),
        ),
      if (canManage)
        _chip(
          context,
          Icons.account_balance_rounded,
          l10n.dashboardAddMortgage,
          AppColors.warning,
          () => context.go('/mortgage'),
        ),
      _chip(
        context,
        Icons.search_rounded,
        l10n.dashboardSearchProduct,
        AppColors.primary,
        () => context.go('/inventory'),
      ),
      _chip(
        context,
        Icons.person_search_rounded,
        l10n.dashboardSearchCustomer,
        AppColors.info,
        () => context.go('/customers'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardQuickActions,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.text2(context)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
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
          SizedBox(
            height: 240,
            child: maxTotal <= 0
                ? Center(
                    child: Text(
                      l10n.dashboardNoRecentSales,
                      style: TextStyle(color: AppColors.text3(context)),
                    ),
                  )
                : _buildChart(context, locale, maxTotal),
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
