import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/features/auth/application/auth_controller.dart';
import 'package:swarnbook/features/auth/presentation/screens/login_screen.dart';
import 'package:swarnbook/features/auth/presentation/screens/signup_screen.dart';
import 'package:swarnbook/features/auth/presentation/screens/welcome_screen.dart';
import 'package:swarnbook/shared/layouts/app_shell.dart';
import 'package:swarnbook/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:swarnbook/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:swarnbook/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:swarnbook/features/billing/presentation/screens/billing_screen.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/mortgage_screen.dart';
import 'package:swarnbook/features/rates/presentation/screens/rates_screen.dart';
import 'package:swarnbook/features/reports/presentation/screens/reports_screen.dart';
import 'package:swarnbook/features/search/presentation/screens/search_screen.dart';
import 'package:swarnbook/features/security/presentation/screens/security_screen.dart';
import 'package:swarnbook/features/tenant/presentation/screens/tenant_profile_screen.dart';
import 'package:swarnbook/features/categories/presentation/screens/categories_screen.dart';
import 'package:swarnbook/features/users/presentation/screens/user_management_screen.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isAuth = ref.watch(
    authControllerProvider.select((s) => s.isAuthenticated),
  );

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final matchedLocation = state.matchedLocation;
      // Welcome is the unauthenticated landing page; login and signup are
      // reached from it, so all three must stay open to signed-out visitors.
      const authRoutes = {'/welcome', '/login', '/signup'};
      final isAuthRoute = authRoutes.contains(matchedLocation);

      if (!isAuth && !isAuthRoute) {
        return '/welcome';
      }
      if (isAuth && isAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final title = _getPageTitle(context, state.matchedLocation);
          return AppShell(
            currentIndex: _getSelectedIndex(state.matchedLocation),
            currentTitle: title,
            currentLocation: state.matchedLocation,
            onNavigate: (index) {
              final routes = [
                '/dashboard',
                '/inventory',
                '/mortgage',
                '/billing',
                '/reports',
              ];
              context.go(routes[index]);
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const CustomerListScreen(),
            ),
          ),
          GoRoute(
            path: '/inventory',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const InventoryListScreen(),
            ),
          ),
          GoRoute(
            path: '/mortgage',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const MortgageScreen(),
            ),
          ),
          GoRoute(
            path: '/billing',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const BillingScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/rates',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const RatesScreen(),
            ),
          ),
          GoRoute(
            path: '/shop-profile',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const TenantProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/security',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const SecurityScreen(),
            ),
          ),
          GoRoute(
            path: '/user-management',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const UserManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const CategoriesScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

// ========================================
// CUSTOM PAGE TRANSITIONS
// ========================================

/// Fade transition for auth screens
CustomTransitionPage _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnim = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      final scaleAnim = Tween<double>(
        begin: 0.98,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return ColoredBox(
        color: AppColors.bg(context),
        child: FadeTransition(
          opacity: fadeAnim,
          child: ScaleTransition(scale: scaleAnim, child: child),
        ),
      );
    },
  );
}

/// Slide-up transition for drill-down pages
CustomTransitionPage _slideTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnim = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      final slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return ColoredBox(
        color: AppColors.bg(context),
        child: FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(position: slideAnim, child: child),
        ),
      );
    },
  );
}

// ========================================
// INDEX MAPPING
// ========================================

int _getSelectedIndex(String location) {
  if (location.startsWith('/dashboard')) return 0;
  if (location.startsWith('/inventory')) return 1;
  if (location.startsWith('/mortgage')) return 2;
  if (location.startsWith('/billing')) return 3;
  if (location.startsWith('/reports')) return 4;
  return 0;
}

String _getPageTitle(BuildContext context, String location) {
  final l10n = AppLocalizations.of(context)!;
  if (location.startsWith('/shop-profile')) return l10n.pageShopProfile;
  if (location.startsWith('/security')) return l10n.pageSecurity;
  if (location.startsWith('/user-management')) return l10n.pageUserManagement;
  if (location.startsWith('/categories')) return l10n.pageCategories;
  if (location.startsWith('/dashboard')) return l10n.navDashboard;
  if (location.startsWith('/customers')) return l10n.navCustomers;
  if (location.startsWith('/inventory')) return l10n.navInventory;
  if (location.startsWith('/mortgage')) return l10n.navMortgage;
  if (location.startsWith('/billing')) return l10n.navBilling;
  if (location.startsWith('/reports')) return l10n.navReports;
  return l10n.appTitle;
}
