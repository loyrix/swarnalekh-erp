import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/shimmer_loading.dart';
import 'package:swarnbook/shared/widgets/quick_action_card.dart';
import 'package:swarnbook/shared/widgets/staggered_animation.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import 'package:swarnbook/shared/widgets/compact_stat_strip.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic> _stats = const {};
  bool _isLoading = true;

  // User info (would come from auth state in production)
  String _userName = '';
  String _shopName = '';
  String? _role;

  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.dashboardGoodMorning;
    if (hour < 17) return l10n.dashboardGoodAfternoon;
    return l10n.dashboardGoodEvening;
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/bootstrap');

      final payload = response.data as Map<String, dynamic>;
      final stats = payload['stats'] as Map<String, dynamic>? ?? {};
      final me = (payload['user'] as Map<String, dynamic>? ?? {});
      final tenant = (payload['tenant'] as Map<String, dynamic>? ?? {});

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _stats = stats;
          _userName = me['name'] ?? l10n.dashboardOwnerFallback;
          _role = me['role']?.toString();
          _shopName = tenant['shopName'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isLoading = false);
        AppToast.error(context, l10n.errorFailedLoadDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _isLoading ? _buildShimmerState() : _buildLoadedState(isWide),
      ),
    );
  }

  // ========================================
  // SHIMMER LOADING STATE
  // ========================================

  Widget _buildShimmerState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerWelcomeBanner(),
        const SizedBox(height: AppSpacing.lg),
        _buildShimmerQuickActions(),
        const SizedBox(height: AppSpacing.lg),
        _buildShimmerStatsGrid(),
      ],
    );
  }

  Widget _buildShimmerQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 5
            : constraints.maxWidth > 600
            ? 3
            : 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List.generate(
            5,
            (_) => SizedBox(
              width:
                  (constraints.maxWidth -
                      (crossAxisCount - 1) * AppSpacing.md) /
                  crossAxisCount,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.cardGrad(context),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.brd(context)),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: 42,
                      height: 42,
                      borderRadius: AppRadius.md,
                    ),
                    const Spacer(),
                    const ShimmerBox(width: 80, height: 13),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List.generate(
            8,
            (_) => SizedBox(
              width:
                  (constraints.maxWidth -
                      (crossAxisCount - 1) * AppSpacing.md) /
                  crossAxisCount,
              child: const ShimmerStatCard(),
            ),
          ),
        );
      },
    );
  }

  // ========================================
  // LOADED STATE
  // ========================================

  Widget _buildLoadedState(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredSection(index: 0, child: _buildWelcomeBanner(isWide)),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(index: 1, child: _buildQuickActions(isWide)),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(index: 2, child: _buildCharts()),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(index: 3, child: _buildStatsGrid(isWide)),
      ],
    );
  }

  Widget _buildWelcomeBanner(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _userName.isNotEmpty
        ? _userName
        : l10n.dashboardOwnerFallback;
    final shopDisplay = _shopName.isNotEmpty
        ? _shopName
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
                  _formattedDate(),
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

  String _formattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _buildQuickActions(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = isAdminRole(_role);

    if (!isWide) {
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickActionChip(
                Icons.receipt_long_rounded,
                l10n.dashboardNewBill,
                AppColors.success,
                () => context.go('/billing'),
              ),
              if (canManage) ...[
                _quickActionChip(
                  Icons.add_box_rounded,
                  l10n.inventoryAddItem,
                  AppColors.info,
                  () => context.go('/inventory'),
                ),
                _quickActionChip(
                  Icons.account_balance_rounded,
                  l10n.dashboardAddMortgage,
                  AppColors.warning,
                  () => context.go('/mortgage'),
                ),
              ],
              _quickActionChip(
                Icons.search_rounded,
                l10n.dashboardSearchProduct,
                AppColors.primary,
                () => context.go('/inventory?focus=search'),
              ),
              _quickActionChip(
                Icons.person_add_alt_1_rounded,
                l10n.dashboardNewContact,
                AppColors.info,
                () => context.go('/reports?focus=search'),
              ),
            ],
          ),
        ],
      );
    }

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
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 5
                : constraints.maxWidth > 600
                ? 3
                : 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width:
                      (constraints.maxWidth -
                          (crossAxisCount - 1) * AppSpacing.md) /
                      crossAxisCount,
                  child: QuickActionCard(
                    icon: Icons.receipt_long_rounded,
                    label: l10n.dashboardNewBill,
                    subtitle: l10n.dashboardCreateInvoice,
                    color: AppColors.success,
                    onTap: () => context.go('/billing'),
                  ),
                ),
                if (canManage)
                  SizedBox(
                    width:
                        (constraints.maxWidth -
                            (crossAxisCount - 1) * AppSpacing.md) /
                        crossAxisCount,
                    child: QuickActionCard(
                      icon: Icons.add_box_rounded,
                      label: l10n.inventoryAddItem,
                      subtitle: l10n.navInventory,
                      color: AppColors.info,
                      onTap: () => context.go('/inventory'),
                    ),
                  ),
                if (canManage)
                  SizedBox(
                    width:
                        (constraints.maxWidth -
                            (crossAxisCount - 1) * AppSpacing.md) /
                        crossAxisCount,
                    child: QuickActionCard(
                      icon: Icons.account_balance_rounded,
                      label: l10n.dashboardAddMortgage,
                      subtitle: l10n.navMortgage,
                      color: AppColors.warning,
                      onTap: () => context.go('/mortgage'),
                    ),
                  ),
                SizedBox(
                  width:
                      (constraints.maxWidth -
                          (crossAxisCount - 1) * AppSpacing.md) /
                      crossAxisCount,
                  child: QuickActionCard(
                    icon: Icons.search_rounded,
                    label: l10n.dashboardSearchProduct,
                    subtitle: l10n.navInventory,
                    color: AppColors.primary,
                    onTap: () => context.go('/inventory'),
                  ),
                ),
                SizedBox(
                  width:
                      (constraints.maxWidth -
                          (crossAxisCount - 1) * AppSpacing.md) /
                      crossAxisCount,
                  child: QuickActionCard(
                    icon: Icons.person_search_rounded,
                    label: l10n.dashboardSearchCustomer,
                    subtitle: l10n.navCustomers,
                    color: AppColors.info,
                    onTap: () => context.go('/customers'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _quickActionChip(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text1(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final chartHeight = 300.0;

        // Use a mock line chart for Revenue trend ending at actual monthly revenue
        final actualRevenue = _number(_stats['monthlyRevenue']);

        final revenueChart = GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardRevenueTrend,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.text1(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: chartHeight,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: actualRevenue > 0
                          ? actualRevenue / 4
                          : 1000,
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
                            if (value >= 0 && value < 4) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'W${value.toInt() + 1}',
                                  style: TextStyle(
                                    color: AppColors.text3(context),
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: actualRevenue > 0
                              ? actualRevenue / 4
                              : 1000,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatMoney(value),
                              style: TextStyle(
                                color: AppColors.text3(context),
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, actualRevenue * 0.2),
                          FlSpot(1, actualRevenue * 0.4),
                          FlSpot(2, actualRevenue * 0.7),
                          FlSpot(3, actualRevenue),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
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
                ),
              ),
            ],
          ),
        );

        return isWide
            ? Row(children: [Expanded(child: revenueChart)])
            : revenueChart;
      },
    );
  }

  Widget _buildStatsGrid(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = <_DashboardMetric>[
      _DashboardMetric(
        icon: Icons.scale_rounded,
        label: l10n.dashboardTotalGoldStock,
        value: _formatWeight(_stats['totalGoldStock']),
        subtitle: l10n.dashboardAvailableNetWeight,
        accentColor: AppColors.gold,
      ),
      _DashboardMetric(
        icon: Icons.scale_outlined,
        label: l10n.dashboardTotalSilverStock,
        value: _formatWeight(_stats['totalSilverStock']),
        subtitle: l10n.dashboardAvailableNetWeight,
        accentColor: AppColors.silver,
      ),
      _DashboardMetric(
        icon: Icons.inventory_2_rounded,
        label: l10n.dashboardInventoryValue,
        value: _formatMoney(_stats['totalInventoryValue']),
        subtitle: l10n.dashboardAvailableStockValue,
        accentColor: AppColors.primary,
      ),
      _DashboardMetric(
        icon: Icons.trending_up_rounded,
        label: l10n.dashboardMonthlyRevenue,
        value: _formatMoney(_stats['monthlyRevenue']),
        subtitle: l10n.dashboardThisMonth,
        accentColor: AppColors.success,
      ),
      _DashboardMetric(
        icon: Icons.account_balance_wallet_rounded,
        label: l10n.dashboardPendingInterest,
        value: _formatMoney(_stats['pendingMortgageInterest']),
        subtitle: l10n.dashboardMortgageDues,
        accentColor: AppColors.warning,
      ),
      _DashboardMetric(
        icon: Icons.account_balance_rounded,
        label: l10n.dashboardActiveLoans,
        value: _formatCount(_stats['activeLoans']),
        subtitle: l10n.dashboardMortgageAccounts,
        accentColor: AppColors.info,
      ),
      _DashboardMetric(
        icon: Icons.point_of_sale_rounded,
        label: l10n.dashboardTodaysSales,
        value: _formatMoney(_stats['todaysSales']),
        subtitle: l10n.dashboardBilledToday,
        accentColor: AppColors.success,
      ),
      _DashboardMetric(
        icon: Icons.receipt_long_rounded,
        label: l10n.dashboardTotalBills,
        value: _formatCount(_stats['totalBillsGenerated']),
        subtitle: l10n.dashboardGeneratedInvoices,
        accentColor: AppColors.primary,
      ),
      _DashboardMetric(
        icon: Icons.shopping_bag_rounded,
        label: l10n.dashboardSoldProducts,
        value: _formatCount(_stats['soldProductsThisMonth']),
        subtitle: l10n.dashboardSoldThisMonthSubtitle,
        accentColor: AppColors.info,
      ),
    ];

    if (!isWide) {
      final top4 = <({IconData icon, String label, String value, Color color})>[
        (
          icon: Icons.scale_rounded,
          label: l10n.dashboardGold,
          value: _formatWeight(_stats['totalGoldStock']),
          color: AppColors.gold,
        ),
        (
          icon: Icons.scale_outlined,
          label: l10n.dashboardSilver,
          value: _formatWeight(_stats['totalSilverStock']),
          color: AppColors.silver,
        ),
        (
          icon: Icons.trending_up_rounded,
          label: l10n.dashboardRevenue,
          value: _formatMoney(_stats['monthlyRevenue']),
          color: AppColors.success,
        ),
        (
          icon: Icons.account_balance_rounded,
          label: l10n.dashboardLoans,
          value: _formatCount(_stats['activeLoans']),
          color: AppColors.info,
        ),
      ];
      return Column(
        children: [
          CompactStatStrip(stats: top4),
          const SizedBox(height: AppSpacing.sm),
          ExpansionTile(
            title: Text(
              l10n.dashboardViewAllStats(metrics.length),
              style: TextStyle(fontSize: 13, color: AppColors.text2(context)),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: metrics
                        .map(
                          (metric) => SizedBox(
                            width:
                                (constraints.maxWidth -
                                    (crossAxisCount - 1) * AppSpacing.md) /
                                crossAxisCount,
                            child: _DashboardStatCard(metric: metric),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width:
                      (constraints.maxWidth -
                          (crossAxisCount - 1) * AppSpacing.md) /
                      crossAxisCount,
                  child: _DashboardStatCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }

  double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatCount(dynamic value) => _number(value).round().toString();

  String _formatWeight(dynamic value) {
    final grams = _number(value);
    if (grams >= 1000) return '${(grams / 1000).toStringAsFixed(2)} kg';
    return '${grams.toStringAsFixed(3)} g';
  }

  String _formatMoney(dynamic value) {
    final amount = _number(value);
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}

class _DashboardMetric {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;

  const _DashboardMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });
}

class _DashboardStatCard extends StatelessWidget {
  final _DashboardMetric metric;

  const _DashboardStatCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = metric.accentColor;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(metric.icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            metric.value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text1(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metric.label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.text2(context)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metric.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
