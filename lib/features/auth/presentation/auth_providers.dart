import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../security/presentation/controllers/security_providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

// Storage Providers
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final localCacheProvider = Provider<LocalCacheService>((ref) {
  throw UnimplementedError("Initialize in main.dart");
});

// Api Client Provider
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final client = ApiClient(
    secureStorage: secureStorage,
    onSessionExpired: () {
      ref.read(authControllerProvider.notifier).handleSessionExpired();
    },
  );
  return client;
});

// Auth Repository Provider
final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
    localCache: ref.watch(localCacheProvider),
  );
});

// Auth State
class AuthState {
  final bool isLoading;
  final UserMe? user;
  final String? errorMessage;
  final Map<String, List<String>> fieldErrors;
  final bool isSessionExpired;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.fieldErrors = const {},
    this.isSessionExpired = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    UserMe? user,
    String? errorMessage,
    Map<String, List<String>>? fieldErrors,
    bool? isSessionExpired,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: clearError ? const {} : (fieldErrors ?? this.fieldErrors),
      isSessionExpired: isSessionExpired ?? this.isSessionExpired,
    );
  }
}

// Auth Controller Notifier
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  final VoidCallback? onLogout;

  AuthController(this._repo, {this.onLogout}) : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final hasSession = await _repo.hasValidSession();
      if (!hasSession) {
        state = state.copyWith(isLoading: false, clearUser: true);
        return;
      }
      final user = await _repo.fetchCurrentUser();
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(username, password);
      state = state.copyWith(isLoading: false, user: user, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repo.logout();
    onLogout?.call();
    state = const AuthState();
  }

  void handleSessionExpired() {
    state = state.copyWith(clearUser: true, isSessionExpired: true);
  }

  void clearSessionExpiredAlert() {
    state = state.copyWith(isSessionExpired: false);
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(
    repo,
    onLogout: () {
      // Clear app lock state on user logout
      try {
        ref.read(appLockControllerProvider.notifier).handleLogout();
      } catch (_) {}
    },
  );
});
