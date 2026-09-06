import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/iranian_plate_widget.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../tickets/presentation/dialogs/second_weight_dialog.dart';
import '../../tickets/presentation/ticket_providers.dart';
import '../domain/yard_truck_model.dart';
import 'trucks_in_yard_providers.dart';

class TrucksInYardScreen extends ConsumerStatefulWidget {
  const TrucksInYardScreen({super.key});

  @override
  ConsumerState<TrucksInYardScreen> createState() => _TrucksInYardScreenState();
}

class _TrucksInYardScreenState extends ConsumerState<TrucksInYardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSecondWeightDialog(YardTruckModel truck) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => SecondWeightDialog(
        ticketId: truck.id,
        serialNumber: truck.serialNumber,
        firstWeight: truck.firstWeight,
        onSubmit: (weight, lossPercent) async {
          final repo = ref.read(ticketRepositoryProvider);
          await repo.recordSecondWeight(
            truck.id,
            weight: weight,
            lossPercent: lossPercent,
          );
        },
      ),
    ).then((success) {
      if (success == true) {
        ref.refresh(waitingTrucksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('وزن دوم قبض شماره ${truck.serialNumber} با موفقیت ثبت شد.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trucksAsync = ref.watch(waitingTrucksProvider);
    final filteredTrucks = ref.watch(filteredWaitingTrucksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ResponsiveLayout.isMobile(context)
              ? 'خودروهای داخل محوطه'
              : 'خودروهای داخل محوطه (در انتظار وزن دوم)',
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
            tooltip: 'بروزرسانی',
            onPressed: () => ref.refresh(waitingTrucksProvider),
          ),
        ],
      ),
      body: trucksAsync.when(
        loading: () => const AppLoadingIndicator(message: 'در حال دریافت لیست خودروهای محوطه...'),
        error: (err, stack) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(waitingTrucksProvider),
        ),
        data: (allTrucks) {
          final longWaitCount = allTrucks.where((t) => t.isLongWait).length;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(waitingTrucksProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Summary Bar
                  if (ResponsiveLayout.isMobile(context))
                    Column(
                      children: [
                        _buildKpiCard(
                          icon: Icons.local_shipping_rounded,
                          iconColor: AppColors.primary,
                          title: 'کل خودروهای محوطه',
                          value: '${allTrucks.length} دستگاه',
                          valueColor: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        _buildKpiCard(
                          icon: longWaitCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                          iconColor: longWaitCount > 0 ? AppColors.warning : AppColors.success,
                          title: 'توقف بیش از ۳ ساعت',
                          value: '$longWaitCount دستگاه',
                          valueColor: longWaitCount > 0 ? AppColors.warning : AppColors.success,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            icon: Icons.local_shipping_rounded,
                            iconColor: AppColors.primary,
                            title: 'کل خودروهای محوطه',
                            value: '${allTrucks.length} دستگاه',
                            valueColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKpiCard(
                            icon: longWaitCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            iconColor: longWaitCount > 0 ? AppColors.warning : AppColors.success,
                            title: 'توقف بیش از ۳ ساعت',
                            value: '$longWaitCount دستگاه',
                            valueColor: longWaitCount > 0 ? AppColors.warning : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Search Bar
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'جستجو بر اساس شماره قبض، پلاک، راننده، طرف حساب یا کالا...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              ref.read(yardTrucksSearchProvider.notifier).state = val;
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(yardTrucksSearchProvider.notifier).state = '';
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Truck Items List
                  if (allTrucks.isEmpty)
                    const AppEmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'محوطه خالی است',
                      description: 'در حال حاضر هیچ خودرویی در انتظار ثبت وزن دوم در سامانه وجود ندارد.',
                    )
                  else if (filteredTrucks.isEmpty)
                    const AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'موردی یافت نشد',
                      description: 'خودرویی منطبق با عبارت جستجو شده پیدا نشد.',
                    )
                  else
                    ResponsiveLayout(
                      mobile: _buildTrucksList(filteredTrucks, isMobile: true),
                      tablet: _buildTrucksGrid(filteredTrucks, crossAxisCount: 2),
                      desktop: _buildTrucksGrid(filteredTrucks, crossAxisCount: 3),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrucksList(List<YardTruckModel> trucks, {required bool isMobile}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trucks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildTruckCard(trucks[index], isGrid: false),
    );
  }

  Widget _buildTrucksGrid(List<YardTruckModel> trucks, {required int crossAxisCount}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 290,
      ),
      itemCount: trucks.length,
      itemBuilder: (context, index) => _buildTruckCard(trucks[index], isGrid: true),
    );
  }

  Widget _buildTruckCard(YardTruckModel truck, {bool isGrid = false}) {
    final theme = Theme.of(context);
    final isLong = truck.isLongWait;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isGrid ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: IranianPlateWidget(
                      plateNumber: truck.licensePlateDisplay,
                      compact: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  'قبض ${truck.serialNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  truck.driverName ?? 'راننده نامشخص',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (truck.driverMobile != null && truck.driverMobile!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  truck.driverMobile!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.business_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  truck.partyName ?? 'طرف حساب نامشخص',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  truck.productName ?? 'کالا نامشخص',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isLong ? AppColors.warning.withOpacity(0.08) : theme.cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(
                color: isLong ? AppColors.warning.withOpacity(0.3) : theme.dividerColor,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.scale_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'وزن اول: ${CurrencyFormatter.formatWeight(truck.firstWeight)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLong ? Icons.timer_off_outlined : Icons.timer_outlined,
                      size: 16,
                      color: isLong ? AppColors.warning : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      truck.waitingDurationDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLong ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isGrid)
            const Spacer()
          else
            const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openSecondWeightDialog(truck),
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('ثبت وزن دوم'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.ticketDetailPath(truck.id)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('جزئیات'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
