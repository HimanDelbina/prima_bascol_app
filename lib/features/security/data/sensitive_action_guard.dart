import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/reauth_session.dart';
import '../domain/security_event.dart';
import '../domain/sensitive_action.dart';
import '../presentation/controllers/security_providers.dart';
import '../presentation/widgets/reauth_dialog.dart';
import 'security_event_logger.dart';

class SensitiveActionGuard {
  final dynamic _ref;
  final SecurityEventLogger _eventLogger;
  ReauthSession? _currentSession;
  Set<String>? _sessionPermissions;

  SensitiveActionGuard({
    required dynamic ref,
    required SecurityEventLogger eventLogger,
  })  : _ref = ref,
        _eventLogger = eventLogger;

  ReauthSession? get currentSession => _currentSession;
  DateTime? get lastReauthenticatedAt => _currentSession?.authenticatedAt;

  bool isSessionValid(
    int timeoutMinutes, {
    int? currentUserId,
    ReauthSecurityLevel? minimumSecurityLevel,
    List<String>? currentUserPermissions,
  }) {
    if (_currentSession == null) return false;

    // Invalidate if user switched
    if (currentUserId != null && _currentSession!.userId != currentUserId) {
      invalidateSession();
      return false;
    }

    // Invalidate if permissions changed
    if (currentUserPermissions != null && _sessionPermissions != null) {
      final currentPermSet = Set<String>.from(currentUserPermissions);
      if (_sessionPermissions!.length != currentPermSet.length ||
          !_sessionPermissions!.containsAll(currentPermSet)) {
        invalidateSession();
        return false;
      }
    }

    return _currentSession!.isValid(
      timeoutMinutes: timeoutMinutes,
      currentUserId: currentUserId ?? _currentSession!.userId,
      minimumSecurityLevel: minimumSecurityLevel,
    );
  }

  void invalidateSession() {
    _currentSession = null;
    _sessionPermissions = null;
  }

  @visibleForTesting
  void setSessionForTesting(ReauthSession session, {Set<String>? permissions}) {
    _currentSession = session;
    _sessionPermissions = permissions;
  }

  Future<bool> authorize(
    BuildContext context, {
    required SensitiveAction action,
    String? customDescription,
  }) async {
    final authState = _ref.read(authControllerProvider);
    final user = authState.user;

    // 1. Backend Permission Check (Reauth MUST NEVER bypass missing permission)
    if (action.requiredPermission != null) {
      final hasPerm =
          user != null && user.hasPermission(action.requiredPermission!);
      if (!hasPerm) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'شما دسترسی لازم برای انجام «${action.titleFa}» را ندارید.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return false;
      }
    }

    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کاربر لاگین‌شده یافت نشد.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }

    // 2. Check Reauth Session Timeout and Security Level
    final lockState = _ref.read(appLockControllerProvider);
    final timeoutMin =
        lockState.preferences?.sensitiveActionReauthTimeoutMinutes ?? 5;

    if (isSessionValid(
      timeoutMin,
      currentUserId: user.id,
      minimumSecurityLevel: action.minimumSecurityLevel,
      currentUserPermissions: user.permissions,
    )) {
      await _eventLogger.log(
        SecurityEventType.sensitiveActionAuthorized,
        userId: user.id,
        action: action.name,
      );
      return true;
    }

    // 3. Prompt Re-authentication Dialog
    if (!context.mounted) return false;

    final result = await ReauthDialog.show(
      context,
      username: user.username,
      userId: user.id,
      action: action,
      title: 'تأیید هویت',
      description: customDescription ?? action.descriptionFa,
      minimumSecurityLevel: action.minimumSecurityLevel,
    );

    if (result != null && result.success) {
      _currentSession = ReauthSession(
        authenticatedAt: DateTime.now(),
        method: result.method,
        securityLevel: result.securityLevel,
        userId: user.id,
      );
      _sessionPermissions = Set<String>.from(user.permissions);
      await _eventLogger.log(
        SecurityEventType.sensitiveActionAuthorized,
        userId: user.id,
        action: action.name,
      );
      return true;
    }

    return false;
  }
}
