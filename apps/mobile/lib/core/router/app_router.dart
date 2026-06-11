import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/features/auth/data/auth_provider.dart';
import 'package:swarnbook/features/auth/presentation/screens/login_screen.dart';
import 'package:swarnbook/features/auth/presentation/screens/registration_screen.dart';
import 'package:swarnbook/features/auth/presentation/screens/signup_screen.dart';
import 'package:swarnbook/shared/layouts/app_shell.dart';
import 'package:swarnbook/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:swarnbook/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:swarnbook/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:swarnbook/features/billing/presentation/screens/billing_screen.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/mortgage_screen.dart';
import 'package:swarnbook/features/rates/presentation/screens/rates_screen.dart';
import 'package:swarnbook/features/reports/presentation/screens/reports_screen.dart';
import 'package:swarnbook/features/security/presentation/screens/security_screen.dart';
import 'package:swarnbook/features/tenant/presentation/screens/tenant_profile_screen.dart';
import 'package:swarnbook/features/users/presentation/screens/user_management_screen.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final session = authState.value?.session;

  if (session != null) {
    ApiClient().setAuthToken(session.accessToken);
  } else {
    ApiClient().clearAuthToken();
  }

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) async {
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/register';

      final isAuth = session != null;

      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      if (!isAuth) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const RegistrationScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final title = _getPageTitle(context, state.matchedLocation);
          return AppShell(
            currentIndex: _getSelectedIndex(state.matchedLocation),
            currentTitle: title,
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
      return ColoredBox(
        color: AppColors.bg(context),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
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
  if (location.startsWith('/security')) return 'Security';
  if (location.startsWith('/user-management')) return 'User Management';
  if (location.startsWith('/dashboard')) return l10n.navDashboard;
  if (location.startsWith('/customers')) return l10n.navCustomers;
  if (location.startsWith('/inventory')) return l10n.navInventory;
  if (location.startsWith('/mortgage')) return l10n.navMortgage;
  if (location.startsWith('/billing')) return l10n.navBilling;
  if (location.startsWith('/reports')) return l10n.navReports;
  return l10n.appTitle;
}
