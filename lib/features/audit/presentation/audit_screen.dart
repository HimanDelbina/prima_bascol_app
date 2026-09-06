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
    switch (log.action.toLowerCase()) {
      case 'create':
        actionColor = AppColors.success;
        break;
      case 'update':
      case 'correct':
      case 'override_weight':
      case 'override_loss':
        actionColor = AppColors.info;
        break;
      case 'cancel':
      case 'delete':
        actionColor = AppColors.error;
        break;
      case 'print':
        actionColor = Colors.purple;
        break;
      default:
        actionColor = AppColors.primary;
        break;
    }

    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Action badge + Title + Timestamp
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  log.actionDisplay,
                  style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.objectRepr.isNotEmpty
                      ? "${log.modelName}: ${log.objectRepr}"
                      : log.modelName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                log.createdAtJalali ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: User Name & Role & IP
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    "کاربر ثبت‌کننده: ${log.userName}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (log.userRole != null && log.userRole!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.userRole!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              if (log.ipAddress != null && log.ipAddress!.isNotEmpty)
                Text(
                  "IP: ${log.ipAddress}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),

          // Reason if any
          if (log.reason != null && log.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.comment_outlined, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "علت: ${log.reason}",
                    style: const TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ],

          // Changes JSON if any
          if (log.changes != null && log.changes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                "جزئیات مقادیر: ${log.changes}",
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
