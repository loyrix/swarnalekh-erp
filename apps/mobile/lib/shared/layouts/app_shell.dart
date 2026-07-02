import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/localization/locale_notifier.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/auth/application/auth_controller.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:swarnbook/shared/widgets/brand_mark.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;
  final String currentTitle;
  final String currentLocation;
  final Function(int) onNavigate;
  final Future<String?> Function()? loadRole;
  final Future<CurrentUserContext> Function()? loadUserContext;
  final Future<void> Function()? signOut;

  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.currentTitle,
    required this.currentLocation,
    required this.onNavigate,
    this.loadRole,
    this.loadUserContext,
    this.signOut,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isExpanded = true;
  String? _role;
  String _profileInitials = 'SL';

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Enforce role restrictions on mid-session navigation (e.g. a staff user
    // typing an admin-only URL) using the already-cached role, no extra fetch.
    if (oldWidget.currentLocation != widget.currentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectIfRestricted(_role);
      });
    }
  }

  Future<void> _loadUserContext() async {
    try {
      String? role;
      if (widget.loadUserContext != null) {
        final userContext = await widget.loadUserContext!();
        if (mounted) {
          role = userContext.role;
          _profileInitials = profileInitialsFromName(
            userContext.shopName ?? userContext.userName,
          );
        }
      } else if (widget.loadRole != null) {
        role = await widget.loadRole!();
      } else {
        final userContext = await fetchCurrentUserContext(ApiClient());
        if (mounted) {
          _profileInitials = profileInitialsFromName(
            userContext.shopName ?? userContext.userName,
          );
        }
        role = userContext.role;
      }
      if (mounted) {
        setState(() => _role = role);
        _redirectIfRestricted(role);
      }
    } catch (_) {
      if (mounted) setState(() => _role = null);
    }
  }

  void _redirectIfRestricted(String? role) {
    if (!mounted) return;
    if (isRestrictedRoute(role, widget.currentLocation)) {
      context.go('/dashboard');
    }
  }

  Future<void> _signOut() async {
    await (widget.signOut ??
        () => ref.read(authControllerProvider.notifier).logout())();
    if (mounted) {
      context.go('/login');
    }
  }

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded),
    _NavItem(icon: Icons.inventory_2_rounded),
    _NavItem(icon: Icons.account_balance_rounded),
    _NavItem(icon: Icons.receipt_long_rounded),
    _NavItem(icon: Icons.bar_chart_rounded),
  ];

  List<_NavItem> get _visibleNavItems =>
      isAdminRole(_role) ? _navItems : _navItems.take(4).toList();

  List<String> _navLabels(AppLocalizations l10n) => [
    l10n.navDashboard,
    l10n.navInventory,
    l10n.navMortgage,
    l10n.navBilling,
    l10n.navReports,
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('NO'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('YES'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: SafeArea(
          bottom: !isWide,
          child: Row(
            children: [
              // Sidebar
              if (isWide) _buildSidebar(),

              // Main content
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isWide),
                    Expanded(
                      child: isWide
                          ? widget.child
                          : SafeArea(
                              top: false,
                              left: false,
                              right: false,
                              child: widget.child,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isWide ? null : _buildBottomNav(),
      ),
    );
  }

  Widget _buildSidebar() {
    final l10n = AppLocalizations.of(context)!;
    final navLabels = _navLabels(l10n);
    final navItems = _visibleNavItems;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _isExpanded ? 240 : 72,
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        border: Border(
          right: BorderSide(color: AppColors.brd(context), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? AppSpacing.lg : AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                const BrandMark(size: 36, padding: 2, elevated: false),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.appTitle,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(color: AppColors.div(context), height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Nav items
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = widget.currentIndex == index;
                return _buildNavItem(item, index, navLabels[index], isSelected);
              },
            ),
          ),

          Divider(color: AppColors.div(context), height: 1),

          // Collapse toggle
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: IconButton(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              icon: Icon(
                _isExpanded
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.text3(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    _NavItem item,
    int index,
    String label,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onNavigate(index),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 14 : 0,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: _isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.text3(context),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.text2(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final showSearch = screenWidth >= 1120;
    final showSecondaryActions = screenWidth >= 980;
    return Container(
      height: isWide ? 64 : 56,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.lg : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        border: Border(
          bottom: BorderSide(color: AppColors.brd(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Page title
          Expanded(
            child: Text(
              widget.currentTitle,
              style: isWide
                  ? Theme.of(context).textTheme.headlineMedium
                  : Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Search — tappable pill on wide layouts, icon-only elsewhere.
          if (showSearch) ...[
            InkWell(
              onTap: () => context.go('/search'),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 280,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfL(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.brd(context)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.text3(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.searchGlobalHint,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text3(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ] else
            IconButton(
              visualDensity: isWide
                  ? VisualDensity.standard
                  : VisualDensity.compact,
              icon: Icon(Icons.search_rounded, color: AppColors.text2(context)),
              onPressed: () => context.go('/search'),
              tooltip: l10n.searchGlobalHint,
            ),
          // Theme toggle
          IconButton(
            visualDensity: isWide
                ? VisualDensity.standard
                : VisualDensity.compact,
            icon: Icon(
              AppColors.isDark(context)
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: AppColors.text2(context),
            ),
            onPressed: () => themeNotifier.toggle(),
            tooltip: l10n.appShellToggleTheme,
          ),
          if (showSecondaryActions) const SizedBox(width: AppSpacing.xs),
          // Notifications
          if (showSecondaryActions)
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: AppColors.text2(context),
              ),
              onPressed: () {},
            ),
          if (isWide) ...[
            SizedBox(width: AppSpacing.sm),
            _buildLanguageMenu(showSecondaryActions),
            SizedBox(width: AppSpacing.sm),
          ],
          PopupMenuButton<_ProfileAction>(
            tooltip: l10n.pageShopProfile,
            color: AppColors.surfL(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: AppColors.brd(context)),
            ),
            onSelected: (value) async {
              if (value == _ProfileAction.profile) {
                context.go('/shop-profile');
                return;
              }
              if (value == _ProfileAction.security) {
                context.go('/security');
                return;
              }
              if (value == _ProfileAction.users) {
                context.go('/user-management');
                return;
              }
              if (value == _ProfileAction.langEn) {
                setAppLocale(const Locale('en'));
                return;
              }
              if (value == _ProfileAction.langHi) {
                setAppLocale(const Locale('hi'));
                return;
              }
              if (value == _ProfileAction.langGu) {
                setAppLocale(const Locale('gu'));
                return;
              }

              await _signOut();
            },
            itemBuilder: (context) => [
              if (isAdminRole(_role))
                PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.profile,
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(l10n.menuShopProfile),
                    ],
                  ),
                ),
              if (isAdminRole(_role))
                PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.security,
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(l10n.appShellSecurity),
                    ],
                  ),
                ),
              if (isAdminRole(_role))
                PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.users,
                  child: Row(
                    children: [
                      const Icon(Icons.manage_accounts_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(l10n.appShellUserManagement),
                    ],
                  ),
                ),
              if (!isWide) ...[
                const PopupMenuDivider(),
                PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.language,
                  enabled: false,
                  child: Text(
                    l10n.menuLanguage,
                    style: TextStyle(
                      color: AppColors.text3(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.langEn,
                  child: Row(
                    children: [
                      const SizedBox(width: 28),
                      Text(l10n.languageEnglish),
                    ],
                  ),
                ),
                PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.langHi,
                  child: Row(
                    children: [
                      const SizedBox(width: 28),
                      Text(l10n.languageHindi),
                    ],
                  ),
                ),
                PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.langGu,
                  child: Row(
                    children: [
                      const SizedBox(width: 28),
                      Text(l10n.languageGujarati),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.logout,
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(l10n.menuLogout),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Center(
                child: Text(
                  _profileInitials,
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final l10n = AppLocalizations.of(context)!;
    final navLabels = _navLabels(l10n);
    final navItems = _visibleNavItems;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        border: Border(
          top: BorderSide(color: AppColors.brd(context), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 72,
          selectedIndex: widget.currentIndex.clamp(0, navItems.length - 1),
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          onDestinationSelected: widget.onNavigate,
          destinations: navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return NavigationDestination(
              icon: Icon(item.icon, color: AppColors.text3(context)),
              selectedIcon: Icon(item.icon, color: AppColors.primary),
              label: navLabels[index],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLanguageMenu(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<Locale?>(
      tooltip: l10n.menuLanguage,
      color: AppColors.surfL(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.brd(context)),
      ),
      onSelected: (locale) => setAppLocale(locale),
      itemBuilder: (context) => [
        PopupMenuItem<Locale?>(
          value: const Locale('en'),
          child: Text(l10n.languageEnglish),
        ),
        PopupMenuItem<Locale?>(
          value: const Locale('hi'),
          child: Text(l10n.languageHindi),
        ),
        PopupMenuItem<Locale?>(
          value: const Locale('gu'),
          child: Text(l10n.languageGujarati),
        ),
      ],
      child: Container(
        width: isWide ? null : 40,
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: isWide ? 10 : 0, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfL(context),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.brd(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language_rounded,
              size: 16,
              color: AppColors.text2(context),
            ),
            if (isWide) ...[
              const SizedBox(width: 6),
              Text(
                l10n.menuLanguage,
                style: TextStyle(
                  color: AppColors.text2(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  const _NavItem({required this.icon});
}

enum _ProfileAction {
  profile,
  security,
  users,
  language,
  langEn,
  langHi,
  langGu,
  logout,
}
