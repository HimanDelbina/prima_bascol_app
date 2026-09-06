import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../domain/audit_models.dart';
import 'audit_providers.dart';

class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(auditLogsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ResponsiveLayout.isMobile(context)
              ? "ممیزی سیستم (Audit)"
              : "گزارش تغییرات و ممیزی سیستم (Audit Log)",
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'بازگشت به داشبورد',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "بروزرسانی",
            onPressed: () => ref.refresh(auditLogsProvider),
          ),
        ],
      ),
      body: auditAsync.when(
        loading: () => const AppLoadingIndicator(message: "در حال دریافت گزارش وقایع..."),
        error: (err, _) => AppErrorState(message: err.toString(), onRetry: () => ref.refresh(auditLogsProvider)),
        data: (logs) {
          if (logs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: "هیچ لاگ ممیزی یافت نشد",
              description: "رویدادها و تغییرات حساس سیستم در این قسمت به صورت غیرقابل تغییر ثبت می‌گردند.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _buildLogCard(logs[i], theme),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(AuditLogItem log, ThemeData theme) {
    Color actionColor;
    switch (log.action.toUpperCase()) {
      case 'CREATE':
        actionColor = AppColors.success;
        break;
      case 'UPDATE':
      case 'CORRECT':
        actionColor = AppColors.info;
        break;
      case 'CANCEL':
      case 'DELETE':
        actionColor = AppColors.error;
        break;
      default:
        actionColor = AppColors.primary;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(log.action, style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Text("${log.modelName}: ${log.objectRepr}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Text(log.createdAtJalali ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text("کاربر: ${log.userName ?? 'سیستم'}", style: const TextStyle(fontSize: 13)),
              if (log.ipAddress != null) ...[
                const SizedBox(width: 14),
                Text("IP: ${log.ipAddress}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
          if (log.changes != null && log.changes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                "تغییرات: ${log.changes}",
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
