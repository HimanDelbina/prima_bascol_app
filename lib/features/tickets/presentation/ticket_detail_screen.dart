import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/permissions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/iranian_plate_widget.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/risk_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/weight_card.dart';
import '../../auth/presentation/auth_providers.dart';
import 'dialogs/first_weight_dialog.dart';
import 'dialogs/second_weight_dialog.dart';
import 'dialogs/ticket_cancel_dialog.dart';
import 'dialogs/ticket_correct_dialog.dart';
import '../../security/domain/sensitive_action.dart';
import '../../security/presentation/controllers/security_providers.dart';
import 'ticket_providers.dart';

class TicketDetailScreen extends ConsumerWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final user = ref.watch(authControllerProvider).user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("جزئیات قبض شماره $ticketId"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'بازگشت',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.tickets);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "تازه‌سازی",
            onPressed: () => ref.refresh(ticketDetailProvider(ticketId)),
          ),
        ],
      ),
      body: ticketAsync.when(
        data: (ticket) => _buildBody(context, ref, ticket, user, theme),
        loading: () => const AppLoadingIndicator(message: "در حال دریافت جزئیات قبض..."),
        error: (e, _) => AppErrorState(
          message: "خطا در دریافت اطلاعات: $e",
          onRetry: () => ref.refresh(ticketDetailProvider(ticketId)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ticket, user, ThemeData theme) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          AppCard(
            padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "قبض شماره ${ticket.serialNumber}",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: IranianPlateWidget(
                              plateDisplay: ticket.licensePlateDisplay,
                              scale: 0.9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(code: ticket.status.code, label: ticket.status.label),
                          RiskBadge(riskScore: ticket.riskScore, riskLevel: ticket.riskLevel),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "تاریخ ثبت اولیه: ${ticket.createdAtJalali ?? '-'}",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "قبض شماره ${ticket.serialNumber}",
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                StatusBadge(code: ticket.status.code, label: ticket.status.label),
                                RiskBadge(riskScore: ticket.riskScore, riskLevel: ticket.riskLevel),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "تاریخ ثبت اولیه: ${ticket.createdAtJalali ?? '-'}",
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      IranianPlateWidget(plateDisplay: ticket.licensePlateDisplay, scale: 1.1),
                    ],
                  ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Action Toolbar
          _buildActionToolbar(context, ref, ticket, user),
          const SizedBox(height: AppDimensions.lg),

          // Weight Cards Grid
          Text("سنجش و اوزان", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppDimensions.md),
          _buildWeightsGrid(context, ticket),
          const SizedBox(height: AppDimensions.xl),

          // Entity Details Grid
          Text("اطلاعات تکمیلی سند", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppDimensions.md),
          _buildDetailsGrid(context, ticket, theme),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(BuildContext context, WidgetRef ref, ticket, user) {
    final status = ticket.status.code.toLowerCase();
    final List<Widget> buttons = [];

    // First Weight Button
    if (user != null && user.hasPermission(AppPermissions.ticketFirstWeight)) {
      if (status == 'draft' || status == 'waiting_first' || status == 'waiting_second') {
        buttons.add(
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            icon: const Icon(Icons.scale_rounded, size: 18),
            label: Text(ticket.firstWeight > 0 ? "اصلاح وزن اول" : "ثبت وزن اول"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => FirstWeightDialog(
                  ticketId: ticket.id,
                  serialNumber: ticket.serialNumber,
                  currentWeight: ticket.firstWeight,
                  onSubmit: (w) async {
                    await ref.read(ticketRepositoryProvider).recordFirstWeight(ticket.id, w);
                    ref.invalidate(ticketDetailProvider(ticket.id));
                  },
                ),
              );
            },
          ),
        );
      }
    }

    // Second Weight Button
    if (user != null && user.hasPermission(AppPermissions.ticketSecondWeight)) {
      if (status == 'waiting_second' || status == 'first_registered') {
        buttons.add(
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.scale_rounded, size: 18),
            label: const Text("ثبت وزن دوم و تکمیل"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => SecondWeightDialog(
                  ticketId: ticket.id,
                  serialNumber: ticket.serialNumber,
                  firstWeight: ticket.firstWeight,
                  onSubmit: (w, loss) async {
                    await ref.read(ticketRepositoryProvider).recordSecondWeight(
                          ticket.id,
                          weight: w,
                          lossPercent: loss,
                        );
                    ref.invalidate(ticketDetailProvider(ticket.id));
                  },
                ),
              );
            },
          ),
        );
      }
    }

    // Management Correction Button
    if (user != null && user.hasPermission(AppPermissions.ticketEditCompleted)) {
      buttons.add(
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_note_rounded, size: 18),
          label: const Text("اصلاح مدیریتی"),
          onPressed: () async {
            final authorized = await ref
                .read(sensitiveActionGuardProvider)
                .authorize(context, action: SensitiveAction.correctCompletedTicket);
            if (!authorized || !context.mounted) return;

            showDialog(
              context: context,
              builder: (ctx) => TicketCorrectDialog(
                ticketId: ticket.id,
                serialNumber: ticket.serialNumber,
                onCorrect: (field, val, reason) async {
                  await ref.read(ticketRepositoryProvider).correctTicket(
                        ticket.id,
                        field: field,
                        newValue: val,
                        reason: reason,
                      );
                  ref.invalidate(ticketDetailProvider(ticket.id));
                },
              ),
            );
          },
        ),
      );
    }

    // Cancel Button
    if (user != null && user.hasPermission(AppPermissions.ticketCancel) && status != 'cancelled') {
      buttons.add(
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text("ابطال سند"),
          onPressed: () async {
            final authorized = await ref
                .read(sensitiveActionGuardProvider)
                .authorize(context, action: SensitiveAction.cancelTicket);
            if (!authorized || !context.mounted) return;

            showDialog(
              context: context,
              builder: (ctx) => TicketCancelDialog(
                ticketId: ticket.id,
                serialNumber: ticket.serialNumber,
                onCancel: (reason) async {
                  await ref.read(ticketRepositoryProvider).cancelTicket(ticket.id, reason: reason);
                  ref.invalidate(ticketDetailProvider(ticket.id));
                },
              ),
            );
          },
        ),
      );
    }

    return Wrap(spacing: 12, runSpacing: 8, children: buttons);
  }

  Widget _buildWeightsGrid(BuildContext context, ticket) {
    final isMobile = ResponsiveLayout.isMobile(context);
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: AppDimensions.md,
      mainAxisSpacing: AppDimensions.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.12 : 1.8,
      children: [
        WeightCard(
          title: "وزن اول (ناخالص/تارا)",
          weightFormatted: WeightFormatter.formatKg(ticket.firstWeight),
          subtitle: "اپراتور: ${ticket.firstWeightOperatorName ?? '-'}",
          color: const Color(0xFFD97706),
        ),
        WeightCard(
          title: "وزن دوم (خالی/پر)",
          weightFormatted: WeightFormatter.formatKg(ticket.secondWeight),
          subtitle: "اپراتور: ${ticket.secondWeightOperatorName ?? '-'}",
          color: AppColors.primary,
        ),
        WeightCard(
          title: "وزن خالص (محاسبه نهایی)",
          weightFormatted: WeightFormatter.formatKg(ticket.netWeight),
          subtitle: ticket.lossWeight > 0 ? "افت: ${WeightFormatter.formatKg(ticket.lossWeight)}" : "بدون افت",
          color: const Color(0xFF16A34A),
          isLarge: true,
        ),
        WeightCard(
          title: "وزن نهایی تحویلی",
          weightFormatted: WeightFormatter.formatKg(ticket.finalWeight),
          subtitle: ticket.isToleranceExceeded ? "⚠️ انحراف بیش از حد مجاز" : "مغایرت عادی",
          color: ticket.isToleranceExceeded ? Colors.red : const Color(0xFF0F766E),
        ),
      ],
    );
  }

  Widget _buildDetailsGrid(BuildContext context, ticket, ThemeData theme) {
    final partyName = ticket.partyDisplay != null ? ticket.partyDisplay['name'] : '-';
    final prodName = ticket.productDisplay != null ? ticket.productDisplay['name'] : '-';

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        children: [
          _buildInfoRow("طرف حساب تجاری", partyName, "کالای محموله", prodName),
          const Divider(height: 24),
          _buildInfoRow("نام راننده", ticket.driverDisplay ?? ticket.driverNameCustom ?? "-", "شماره موبایل", ticket.driverMobileDisplay ?? "-"),
          const Divider(height: 24),
          _buildInfoRow("شماره بارنامه", ticket.waybillNumber ?? "-", "محل تخلیه / بارگیری", ticket.unloadLocationName ?? "-"),
          const Divider(height: 24),
          _buildInfoRow("مبدأ حمل", ticket.originName ?? "-", "مقصد حمل", ticket.destinationName ?? "-"),
          if (ticket.cancellationReason != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Text("دلیل ابطال:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(child: Text(ticket.cancellationReason!, style: const TextStyle(color: Colors.red))),
              ],
            ),
          ],
          if (ticket.lastEditReason != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Text("دلیل اصلاح مدیریتی:", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(child: Text("${ticket.lastEditReason!} (توسط: ${ticket.lastEditedByName ?? '-'})")),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label1, String val1, String label2, String val2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(val1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(val2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
