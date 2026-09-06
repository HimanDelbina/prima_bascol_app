import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/permissions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/presentation/auth_providers.dart';

class NavMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final String? permission;
  final List<String>? anyPermissions;

  const NavMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.permission,
    this.anyPermissions,
  });
}

class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  final List<NavMenuItem> _menuItems = const [
    NavMenuItem(
      title: "داشبورد",
      icon: Icons.dashboard_rounded,
      route: AppRoutes.dashboard,
      permission: AppPermissions.dashboardView,
    ),
    NavMenuItem(
      title: "قبوض باسکول",
      icon: Icons.receipt_long_rounded,
      route: AppRoutes.tickets,
      permission: AppPermissions.ticketView,
    ),
    NavMenuItem(
      title: "خودروهای داخل محوطه",
      icon: Icons.local_shipping_rounded,
      route: AppRoutes.trucksInYard,
      permission: AppPermissions.ticketView,
    ),
    NavMenuItem(
      title: "گزارشات جامع",
      icon: Icons.bar_chart_rounded,
      route: AppRoutes.reports,
      permission: AppPermissions.reportsView,
    ),
    NavMenuItem(
      title: "گزارشات مدیریتی (BI)",
      icon: Icons.insights_rounded,
      route: AppRoutes.management,
      permission: AppPermissions.managementView,
    ),
    NavMenuItem(
      title: "پایش هوشمند و هشدارها",
      icon: Icons.warning_amber_rounded,
      route: AppRoutes.monitoring,
      permission: AppPermissions.monitoringView,
    ),
    NavMenuItem(
      title: "اطلاعات پایه",
      icon: Icons.category_rounded,
      route: AppRoutes.masterdata,
      permission: AppPermissions.masterdataView,
    ),
    NavMenuItem(
      title: "گزارش تغییرات (Audit)",
      icon: Icons.history_rounded,
      route: AppRoutes.audit,
      permission: AppPermissions.auditView,
    ),
    NavMenuItem(
      title: "مدیریت کاربران",
      icon: Icons.people_outline_rounded,
      route: AppRoutes.users,
      permission: AppPermissions.usersView,
    ),
    NavMenuItem(
      title: "تنظیمات سامانه",
      icon: Icons.settings_suggest_rounded,
      route: AppRoutes.settings,
      permission: AppPermissions.settingsView,
    ),
  ];

  Future<void> _logout() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: "خروج از حساب کاربری",
      message: "آیا برای خروج از سامانه اطمینان دارید؟",
      confirmText: "خروج",
      isDestructive: true,
    );

    if (confirm && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final currentLoc = GoRouterState.of(context).uri.toString();

    // Filter permitted items
    final visibleItems = _menuItems.where((item) {
      if (user == null) return false;
      if (item.permission != null && !user.hasPermission(item.permission!)) return false;
      if (item.anyPermissions != null && !user.hasAnyPermission(item.anyPermissions!)) return false;
      return true;
    }).toList();

    final isDashboard = currentLoc == AppRoutes.dashboard || currentLoc == '/';

    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return Scaffold(
        appBar: isDashboard
            ? AppBar(
                title: const Text("سامانه باسکول پریما", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                actions: [
                  IconButton(
                    icon: Icon(
                      theme.brightness == Brightness.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 20,
                    ),
                    tooltip: theme.brightness == Brightness.dark ? "حالت روشن" : "حالت تاریک",
                    onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                    tooltip: "خروج",
                    onPressed: _logout,
                  ),
                ],
              )
            : null,
        drawer: Drawer(
          child: Column(
            children: [
              _buildDrawerHeader(user, theme),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: visibleItems.map((item) {
                    final isSelected = currentLoc.startsWith(item.route);
                    return ListTile(
                      leading: Icon(item.icon, color: isSelected ? AppColors.primary : theme.iconTheme.color),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withOpacity(0.08),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.route);
                      },
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(
                  theme.brightness == Brightness.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: AppColors.primary,
                ),
                title: const Text("حالت شب (تم تاریک)", style: TextStyle(fontSize: 13)),
                value: theme.brightness == Brightness.dark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
        ),
        body: widget.child,
      );
    }

    return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 960;
            final sidebarWidth = isCompact ? AppDimensions.sidebarWidthCollapsed : AppDimensions.sidebarWidthDesktop;

            return Row(
              children: [
                // Right Sidebar for RTL Persian
                Container(
                  width: sidebarWidth,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(left: BorderSide(color: theme.dividerColor, width: 1)),
                  ),
                  child: Column(
                    children: [
                      _buildSidebarHeader(theme, isCompact: isCompact),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: isCompact ? 6 : 10),
                          itemCount: visibleItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (ctx, i) {
                            final item = visibleItems[i];
                            final isSelected = currentLoc.startsWith(item.route);

                            final itemContent = Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              ),
                              child: isCompact
                                  ? Center(
                                      child: Icon(
                                        item.icon,
                                        size: 20,
                                        color: isSelected ? Colors.white : theme.iconTheme.color,
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 20,
                                          color: isSelected ? Colors.white : theme.iconTheme.color,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            );

                            return InkWell(
                              onTap: () => context.go(item.route),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              child: isCompact
                                  ? Tooltip(
                                      message: item.title,
                                      preferBelow: false,
                                      child: itemContent,
                                    )
                                  : itemContent,
                            );
                          },
                        ),
                      ),
                      _buildSidebarFooter(user, theme, isCompact: isCompact),
                    ],
                  ),
                ),
                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(user, theme),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
  }

  Widget _buildSidebarHeader(ThemeData theme, {bool isCompact = false}) {
    if (isCompact) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: const Icon(Icons.scale_rounded, color: AppColors.primary, size: 24),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: const Icon(Icons.scale_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "سامانه باسکول",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
                Text(
                  "شرکت پریما",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(user, ThemeData theme) {
    return Container(
      height: AppDimensions.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "سیستم یکپارچه مدیریت و پایش هوشمند باسکول",
              style: theme.textTheme.titleSmall?.copyWith(color: AppColors.textSecondaryLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (user != null) ...[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "${user.fullName} (${user.role.label})",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
            ),
            tooltip: theme.brightness == Brightness.dark ? "حالت روشن" : "حالت تاریک",
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 22),
            tooltip: "خروج از سامانه",
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter(user, ThemeData theme, {bool isCompact = false}) {
    if (user == null) return const SizedBox.shrink();

    if (isCompact) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Tooltip(
          message: "${user.fullName}\n(${user.role.label})",
          preferBelow: false,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0] : "U",
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0] : "U",
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.role.label,
                  style: TextStyle(fontSize: 10, color: theme.hintColor),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(user, ThemeData theme) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.scale_rounded, size: 36, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            user?.fullName ?? "کاربر سامانه",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            user?.role.label ?? "",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
