import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/audit/presentation/audit_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/management/presentation/management_screen.dart';
import '../../features/management/presentation/party_ranking_screen.dart';
import '../../features/management/presentation/party_detail_analytics_screen.dart';
import '../../features/management/presentation/party_comparison_screen.dart';
import '../../features/masterdata/presentation/masterdata_screen.dart';
import '../../features/monitoring/presentation/monitoring_rules_screen.dart';
import '../../features/monitoring/presentation/monitoring_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/security/presentation/screens/pattern_setup_screen.dart';
import '../../features/security/presentation/screens/security_settings_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/tickets/presentation/ticket_create_screen.dart';
import '../../features/tickets/presentation/ticket_detail_screen.dart';
import '../../features/tickets/presentation/ticket_list_screen.dart';
import '../../features/trucks_in_yard/presentation/trucks_in_yard_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    final isAuth = authState.isAuthenticated;
    final loc = state.matchedLocation;

    final isSplash = loc == AppRoutes.splash;
    final isLogin = loc == AppRoutes.login;

    // While on splash screen, let SplashScreen manage its bootstrap transition
    if (isSplash) {
      return null;
    }

    if (!isAuth && !isLogin) {
      return AppRoutes.login;
    }

    if (isAuth && isLogin) {
      return AppRoutes.dashboard;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text("صفحه مورد نظر یافت نشد"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              const Text(
                "صفحه مورد نظر یافت نشد (۴۰۴)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? "مسیر درخواستی در سامانه تعریف نشده است.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text("بازگشت به داشبورد"),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.tickets,
            builder: (context, state) => const TicketListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const TicketCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
                  return TicketDetailScreen(ticketId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.trucksInYard,
            builder: (context, state) => const TrucksInYardScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.management,
            builder: (context, state) => const ManagementScreen(),
            routes: [
              GoRoute(
                path: 'parties/ranking',
                name: 'partyRanking',
                builder: (context, state) => const PartyRankingScreen(),
              ),
              GoRoute(
                path: 'parties/compare',
                name: 'partyCompare',
                builder: (context, state) => const PartyComparisonScreen(),
              ),
              GoRoute(
                path: 'parties/:id',
                name: 'partyDetail',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
                  return PartyDetailAnalyticsScreen(partyId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.monitoring,
            builder: (context, state) => const MonitoringScreen(),
            routes: [
              GoRoute(
                path: 'rules',
                builder: (context, state) => const MonitoringRulesScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.masterdata,
            builder: (context, state) => const MasterDataScreen(),
          ),
          GoRoute(
            path: AppRoutes.audit,
            builder: (context, state) => const AuditScreen(),
          ),
          GoRoute(
            path: AppRoutes.users,
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'security',
                builder: (context, state) => const SecuritySettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'pattern-setup',
                    builder: (context, state) => const PatternSetupScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
