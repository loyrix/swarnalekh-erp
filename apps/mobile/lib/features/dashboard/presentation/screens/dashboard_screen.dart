import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/shimmer_loading.dart';
import 'package:swarnbook/shared/widgets/quick_action_card.dart';
import 'package:swarnbook/shared/widgets/staggered_animation.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
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
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _isLoading ? _buildShimmerState() : _buildLoadedState(),
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

  Widget _buildLoadedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredSection(index: 0, child: _buildWelcomeBanner()),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(index: 1, child: _buildQuickActions()),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(index: 2, child: _buildStatsGrid()),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _userName.isNotEmpty
        ? _userName
        : l10n.dashboardOwnerFallback;
    final shopDisplay = _shopName.isNotEmpty
        ? _shopName
        : l10n.dashboardShopFallback;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  shopDisplay,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Date display
                Text(
                  _formattedDate(),
                  style: TextStyle(
                    color: AppColors.text3(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.goldShimmer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.goldGlow,
            ),
            child: const Icon(
              Icons.diamond_rounded,
              color: AppColors.textOnPrimary,
              size: 36,
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

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context)!;
    final canManage = isAdminRole(_role);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 5
            : constraints.maxWidth > 600
            ? 3
            : 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardQuickActions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text2(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    final l10n = AppLocalizations.of(context)!;
    final metrics = [
      _DashboardMetric(
        icon: Icons.scale_rounded,
        label: 'Total Gold Stock',
        value: _formatWeight(_stats['totalGoldStock']),
        subtitle: 'Available net weight',
        accentColor: AppColors.gold,
      ),
      _DashboardMetric(
        icon: Icons.scale_outlined,
        label: 'Total Silver Stock',
        value: _formatWeight(_stats['totalSilverStock']),
        subtitle: 'Available net weight',
        accentColor: AppColors.silver,
      ),
      _DashboardMetric(
        icon: Icons.inventory_2_rounded,
        label: 'Inventory Value',
        value: _formatMoney(_stats['totalInventoryValue']),
        subtitle: 'Available stock value',
        accentColor: AppColors.primary,
      ),
      _DashboardMetric(
        icon: Icons.trending_up_rounded,
        label: 'Monthly Revenue',
        value: _formatMoney(_stats['monthlyRevenue']),
        subtitle: 'This month',
        accentColor: AppColors.success,
      ),
      _DashboardMetric(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Pending Interest',
        value: _formatMoney(_stats['pendingMortgageInterest']),
        subtitle: 'Mortgage dues',
        accentColor: AppColors.warning,
      ),
      _DashboardMetric(
        icon: Icons.account_balance_rounded,
        label: 'Active Loans',
        value: _formatCount(_stats['activeLoans']),
        subtitle: 'Mortgage accounts',
        accentColor: AppColors.info,
      ),
      _DashboardMetric(
        icon: Icons.point_of_sale_rounded,
        label: "Today's Sales",
        value: _formatMoney(_stats['todaysSales']),
        subtitle: 'Billed today',
        accentColor: AppColors.success,
      ),
      _DashboardMetric(
        icon: Icons.receipt_long_rounded,
        label: 'Total Bills',
        value: _formatCount(_stats['totalBillsGenerated']),
        subtitle: 'Generated invoices',
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
