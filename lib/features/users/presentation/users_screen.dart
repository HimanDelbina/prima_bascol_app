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
import '../domain/user_management_models.dart';
import 'users_providers.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final personnelCtrl = TextEditingController();
    String role = 'weighbridge_operator';
    bool isSubmitting = false;
    String? errorText;

    const roles = [
      {'code': 'weighbridge_operator', 'label': 'اپراتور باسکول (Operator)'},
      {'code': 'weighbridge_manager', 'label': 'مدیر / سرپرست باسکول'},
      {'code': 'system_admin', 'label': 'مدیر سیستم (System Admin)'},
      {'code': 'report_manager', 'label': 'مدیر گزارشات (Report Manager)'},
      {'code': 'financial_manager', 'label': 'مدیر مالی'},
      {'code': 'commercial_manager', 'label': 'مدیر بازرگانی'},
      {'code': 'factory_manager', 'label': 'مدیر کارخانه'},
      {'code': 'viewer', 'label': 'مشاهده‌گر (Viewer)'},
      {'code': 'super_admin', 'label': 'مدیر ارشد (Super Admin)'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text("تعریف کاربر جدید"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorText!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: "نام کاربری *", hintText: "مثال: operator1"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "رمز عبور *", hintText: "حداقل ۴ کاراکتر"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: "نام")),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: "نام خانوادگی")),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: "شماره موبایل"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: personnelCtrl,
                        decoration: const InputDecoration(labelText: "کد پرسنلی"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: "نقش دسترسی در سامانه"),
                  items: roles.map((r) {
                    return DropdownMenuItem<String>(
                      value: r['code'],
                      child: Text(r['label']!, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => role = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text("انصراف"),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (userCtrl.text.trim().isEmpty) {
                        setDlgState(() => errorText = "نام کاربری الزامی است.");
                        return;
                      }
                      if (passCtrl.text.trim().isEmpty) {
                        setDlgState(() => errorText = "رمز عبور الزامی است.");
                        return;
                      }
                      if (passCtrl.text.trim().length < 4) {
                        setDlgState(() => errorText = "رمز عبور باید حداقل ۴ کاراکتر باشد.");
                        return;
                      }

                      setDlgState(() {
                        isSubmitting = true;
                        errorText = null;
                      });

                      try {
                        final repo = ref.read(userManagementRepositoryProvider);
                        final payload = <String, dynamic>{
                          'username': userCtrl.text.trim(),
                          'password': passCtrl.text.trim(),
                          'role': role,
                        };
                        if (firstCtrl.text.trim().isNotEmpty) payload['first_name'] = firstCtrl.text.trim();
                        if (lastCtrl.text.trim().isNotEmpty) payload['last_name'] = lastCtrl.text.trim();
                        if (mobileCtrl.text.trim().isNotEmpty) payload['mobile'] = mobileCtrl.text.trim();
                        if (personnelCtrl.text.trim().isNotEmpty) payload['personnel_code'] = personnelCtrl.text.trim();

                        await repo.createUser(payload);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("کاربر «${userCtrl.text.trim()}» با موفقیت ایجاد گردید."),
                              backgroundColor: Colors.green,
                            ),
                          );
                          ref.refresh(usersListProvider);
                        }
                      } catch (e) {
                        setDlgState(() {
                          isSubmitting = false;
                          errorText = e.toString().replaceAll('Exception: ', '').replaceAll('ServerFailure: ', '').replaceAll('ValidationFailure: ', '');
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("ایجاد کاربر"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ResponsiveLayout.isMobile(context)
              ? "مدیریت کاربران"
              : "مدیریت کاربران و سطوح دسترسی",
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
            onPressed: () => ref.refresh(usersListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text("کاربر جدید"),
      ),
      body: usersAsync.when(
        loading: () => const AppLoadingIndicator(message: "در حال دریافت لیست کاربران..."),
        error: (err, _) => AppErrorState(message: err.toString(), onRetry: () => ref.refresh(usersListProvider)),
        data: (users) {
          if (users.isEmpty) {
            return const AppEmptyState(icon: Icons.people_outline, title: "کاربری یافت نشد", description: "می‌توانید با دکمه کاربر جدید ثبت نمایید.");
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final u = users[i];
              return AppCard(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(u.fullName.isNotEmpty ? u.fullName[0] : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("نام کاربری: ${u.username} | نقش: ${u.role}"),
                  trailing: Switch(
                    value: u.isActive,
                    activeColor: AppColors.success,
                    onChanged: (val) async {
                      final repo = ref.read(userManagementRepositoryProvider);
                      await repo.toggleActive(u.id, val);
                      ref.refresh(usersListProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
