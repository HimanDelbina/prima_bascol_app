import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/audit_repository.dart';
import '../domain/audit_models.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(apiClientProvider));
});

final auditSearchProvider = StateProvider<String>((ref) => '');

final auditLogsProvider = FutureProvider.autoDispose<List<AuditLogItem>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  final search = ref.watch(auditSearchProvider);
  return repo.fetchAuditLogs(search: search);
});
