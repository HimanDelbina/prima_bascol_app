import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/user_management_repository.dart';
import '../domain/user_management_models.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  return UserManagementRepository(ref.watch(apiClientProvider));
});

final usersListProvider = FutureProvider.autoDispose<List<UserAccountItem>>((ref) async {
  final repo = ref.watch(userManagementRepositoryProvider);
  return repo.fetchUsers();
});
