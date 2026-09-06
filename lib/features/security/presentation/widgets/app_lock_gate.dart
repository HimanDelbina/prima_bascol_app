import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/security_providers.dart';
import '../screens/app_lock_screen.dart';
import 'privacy_overlay.dart';

class AppLockGate extends ConsumerWidget {
  final Widget? child;

  const AppLockGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockControllerProvider);

    return Stack(
      children: [
        // Underlying application (maintains state, forms, text inputs, router)
        if (child != null) child!,

        // App Lock Screen Overlay (shown when locked, preserves underlying widget tree)
        if (lockState.isLocked)
          const Positioned.fill(
            child: AppLockScreen(),
          ),

        // Privacy Overlay (shown in App Switcher preview)
        if (lockState.isPrivacyOverlayVisible)
          const PrivacyOverlay(),
      ],
    );
  }
}
