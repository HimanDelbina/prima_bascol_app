import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../security/presentation/controllers/security_providers.dart';
import 'auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await ref
          .read(authControllerProvider.notifier)
          .checkAuthStatus()
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // If network or storage check times out, fallback smoothly
    }
    if (!mounted) return;

    final auth = ref.read(authControllerProvider);
    if (auth.isAuthenticated && auth.user != null) {
      await ref
          .read(appLockControllerProvider.notifier)
          .initializeForUser(auth.user!, isColdStart: true);
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.scale_rounded, size: 72, color: Colors.white),
            SizedBox(height: AppDimensions.lg),
            Text(
              AppConfig.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "در حال بارگذاری و برقراری ارتباط با سرور...",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: AppDimensions.xl),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
