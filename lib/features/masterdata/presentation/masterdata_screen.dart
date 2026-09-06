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
import '../../../core/widgets/iranian_plate_widget.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../domain/masterdata_models.dart';
import 'masterdata_providers.dart';

class MasterDataScreen extends ConsumerStatefulWidget {
  const MasterDataScreen({super.key});

  @override
  ConsumerState<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends ConsumerState<MasterDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _searchController.clear();
        ref.read(masterDataSearchProvider.notifier).state = '';
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final tolCtrl = TextEditingController(text: "0.0");
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text("ثبت کالای جدید"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "کد کالا *")),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "نام کالا *")),
                const SizedBox(height: 12),
                TextField(controller: tolCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "درصد تلورانس مجاز")),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text("وضعیت فعال"),
                  value: isActive,
                  onChanged: (val) => setDlgState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
                final repo = ref.read(masterDataRepositoryProvider);
                await repo.saveProduct({
                  'code': codeCtrl.text.trim(),
                  'name': nameCtrl.text.trim(),
                  'default_tolerance': double.tryParse(tolCtrl.text.trim()) ?? 0.0,
                  'is_active': isActive,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ref.refresh(productsListProvider);
                }
              },
              child: const Text("ثبت"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPartyDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ecoCtrl = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text("ثبت طرف حساب جدید"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "کد طرف حساب *")),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "نام شخص / شرکت *")),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "شماره تماس")),
                const SizedBox(height: 12),
                TextField(controller: ecoCtrl, decoration: const InputDecoration(labelText: "کد اقتصادی / ملی")),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text("وضعیت فعال"),
                  value: isActive,
                  onChanged: (val) => setDlgState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
                final repo = ref.read(masterDataRepositoryProvider);
                await repo.saveParty({
                  'code': codeCtrl.text.trim(),
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'economic_code': ecoCtrl.text.trim(),
                  'is_active': isActive,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ref.refresh(partiesListProvider);
                }
              },
              child: const Text("ثبت"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDriverDialog() {
    final nameCtrl = TextEditingController();
    final nationalCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text("ثبت راننده جدید"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "نام و نام خانوادگی *")),
                const SizedBox(height: 12),
                TextField(controller: nationalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "کد ملی *")),
                const SizedBox(height: 12),
                TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "شماره موبایل *")),
                const SizedBox(height: 12),
                TextField(controller: licenseCtrl, decoration: const InputDecoration(labelText: "شماره گواهینامه")),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text("وضعیت فعال"),
                  value: isActive,
                  onChanged: (val) => setDlgState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || nationalCtrl.text.isEmpty) return;
                final repo = ref.read(masterDataRepositoryProvider);
                await repo.saveDriver({
                  'full_name': nameCtrl.text.trim(),
                  'name': nameCtrl.text.trim(),
                  'national_code': nationalCtrl.text.trim(),
                  'mobile': mobileCtrl.text.trim(),
                  'license_number': licenseCtrl.text.trim(),
                  'is_active': isActive,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ref.refresh(driversListProvider);
                }
              },
              child: const Text("ثبت"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVehicleDialog() {
    final plateCtrl = TextEditingController();
    final smartCtrl = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text("ثبت خودرو جدید"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plateCtrl,
                  decoration: const InputDecoration(
                    labelText: "پلاک خودرو *",
                    hintText: "مثال: 12ع34572",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: smartCtrl, decoration: const InputDecoration(labelText: "شماره کارت هوشمند ناوگان")),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text("وضعیت فعال"),
                  value: isActive,
                  onChanged: (val) => setDlgState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("انصراف")),
            ElevatedButton(
              onPressed: () async {
                if (plateCtrl.text.isEmpty) return;
                final repo = ref.read(masterDataRepositoryProvider);
                await repo.saveVehicle({
                  'plate_number': plateCtrl.text.trim(),
                  'smart_card_number': smartCtrl.text.trim(),
                  'is_active': isActive,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ref.refresh(vehiclesListProvider);
                }
              },
              child: const Text("ثبت"),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddPressed() {
    switch (_tabController.index) {
      case 0:
        _showAddProductDialog();
        break;
      case 1:
        _showAddPartyDialog();
        break;
      case 2:
        _showAddDriverDialog();
        break;
      case 3:
        _showAddVehicleDialog();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مدیریت اطلاعات پایه"),
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
            onPressed: () {
              ref.refresh(productsListProvider);
              ref.refresh(partiesListProvider);
              ref.refresh(driversListProvider);
              ref.refresh(vehiclesListProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: "کالاها"),
            Tab(icon: Icon(Icons.business_outlined), text: "طرف‌های حساب"),
            Tab(icon: Icon(Icons.person_outline), text: "رانندگان"),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: "ناوگان و خودروها"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddPressed,
        icon: const Icon(Icons.add),
        label: const Text("ثبت رکورد جدید"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "جستجو در داده‌ها...",
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(masterDataSearchProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  ref.read(masterDataSearchProvider.notifier).state = val;
                },
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildPartiesTab(),
                _buildDriversTab(),
                _buildVehiclesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final asyncData = ref.watch(productsListProvider);
    return asyncData.when(
      loading: () => const AppLoadingIndicator(message: "در حال دریافت لیست کالاها..."),
      error: (e, _) => AppErrorState(message: e.toString(), onRetry: () => ref.refresh(productsListProvider)),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(icon: Icons.inventory_2_outlined, title: "کالایی ثبت نشده است", description: "می‌توانید با دکمه ثبت جدید اولین کالا را اضافه کنید.");
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final p = items[i];
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("کد: ${p.code} | تلورانس: ${p.defaultTolerance}%"),
                trailing: Chip(
                  label: Text(p.isActive ? "فعال" : "غیرفعال", style: TextStyle(color: p.isActive ? AppColors.success : AppColors.error, fontSize: 11)),
                  backgroundColor: (p.isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPartiesTab() {
    final asyncData = ref.watch(partiesListProvider);
    return asyncData.when(
      loading: () => const AppLoadingIndicator(message: "در حال دریافت طرف‌های حساب..."),
      error: (e, _) => AppErrorState(message: e.toString(), onRetry: () => ref.refresh(partiesListProvider)),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(icon: Icons.business_outlined, title: "طرف حسابی ثبت نشده است", description: "طرف‌های حساب شامل فرستنده، گیرنده و مشتریان در این بخش مدیریت می‌شوند.");
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final p = items[i];
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  child: const Icon(Icons.business_rounded, color: AppColors.secondary),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("کد: ${p.code} | تماس: ${p.phone ?? '-'} | اقتصادی: ${p.economicCode ?? '-'}"),
                trailing: Chip(
                  label: Text(p.isActive ? "فعال" : "غیرفعال", style: TextStyle(color: p.isActive ? AppColors.success : AppColors.error, fontSize: 11)),
                  backgroundColor: (p.isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDriversTab() {
    final asyncData = ref.watch(driversListProvider);
    return asyncData.when(
      loading: () => const AppLoadingIndicator(message: "در حال دریافت لیست رانندگان..."),
      error: (e, _) => AppErrorState(message: e.toString(), onRetry: () => ref.refresh(driversListProvider)),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(icon: Icons.person_outline, title: "راننده‌ای ثبت نشده است", description: "اطلاعات رانندگان و گواهینامه‌ها در این بخش ثبت می‌شود.");
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final d = items[i];
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  child: const Icon(Icons.person_rounded, color: Colors.teal),
                ),
                title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("موبایل: ${d.mobile} | کد ملی: ${d.nationalCode}"),
                trailing: Chip(
                  label: Text(d.isActive ? "فعال" : "غیرفعال", style: TextStyle(color: d.isActive ? AppColors.success : AppColors.error, fontSize: 11)),
                  backgroundColor: (d.isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVehiclesTab() {
    final asyncData = ref.watch(vehiclesListProvider);
    return asyncData.when(
      loading: () => const AppLoadingIndicator(message: "در حال دریافت ناوگان..."),
      error: (e, _) => AppErrorState(message: e.toString(), onRetry: () => ref.refresh(vehiclesListProvider)),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(icon: Icons.local_shipping_outlined, title: "خودرویی ثبت نشده است", description: "ناوگان، پلاک‌ها و کارت‌های هوشمند در این بخش مدیریت می‌شوند.");
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final v = items[i];
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: IranianPlateWidget(plateNumber: v.plateNumber, compact: true),
                title: Text(v.vehicleTypeName ?? "نوع نامشخص", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("کارت هوشمند: ${v.smartCardNumber ?? '-'}"),
                trailing: Chip(
                  label: Text(v.isActive ? "فعال" : "غیرفعال", style: TextStyle(color: v.isActive ? AppColors.success : AppColors.error, fontSize: 11)),
                  backgroundColor: (v.isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
