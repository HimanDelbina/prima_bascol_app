import 'dart:async';
import '../../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/plate_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/searchable_select_field.dart';
import '../../../core/widgets/weight_input_field.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../masterdata/domain/masterdata_models.dart';
import '../../masterdata/presentation/masterdata_providers.dart';
import '../domain/ticket_models.dart';
import 'ticket_providers.dart';

class TicketCreateScreen extends ConsumerStatefulWidget {
  const TicketCreateScreen({super.key});

  @override
  ConsumerState<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends ConsumerState<TicketCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selected Entities
  int? _partyId;
  String? _partyName;
  int? _productId;
  String? _productName;
  int? _driverId;
  String? _driverName;
  int? _vehicleId;
  String? _vehiclePlate;
  int? _originId;
  int? _destinationId;
  int? _unloadLocationId;
  int? _operationTypeId;
  String? _operationTypeName;
  String _selectedDirection = 'inbound';

  // Controllers & Focus Nodes
  final _plate1Controller = TextEditingController();
  final _plate1FocusNode = FocusNode();
  String _plateLetter = 'ع';
  final _plate2Controller = TextEditingController();
  final _plate2FocusNode = FocusNode();
  final _plateIranController = TextEditingController();
  final _plateIranFocusNode = FocusNode();

  final _driverCustomController = TextEditingController();
  final _driverMobileController = TextEditingController();
  final _waybillController = TextEditingController();
  final _sentWeightController = TextEditingController();
  final _firstWeightController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isDirty = false;
  String? _errorMessage;

  // Auto-detection state
  VehicleItem? _detectedVehicle;
  bool _isCheckingPlate = false;
  Timer? _plateDebounceTimer;

  @override
  void dispose() {
    _plateDebounceTimer?.cancel();
    _plate1Controller.dispose();
    _plate1FocusNode.dispose();
    _plate2Controller.dispose();
    _plate2FocusNode.dispose();
    _plateIranController.dispose();
    _plateIranFocusNode.dispose();
    _driverCustomController.dispose();
    _driverMobileController.dispose();
    _waybillController.dispose();
    _sentWeightController.dispose();
    _firstWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isPlateMatch(String plateA, String plateB) {
    String norm(String s) => s
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('ایران', '')
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .trim();
    return norm(plateA) == norm(plateB);
  }

  void _onPlateChanged() {
    _plateDebounceTimer?.cancel();
    if (_plate1Controller.text.length == 2 &&
        _plate2Controller.text.length == 3 &&
        _plateIranController.text.length == 2) {
      _plateDebounceTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) {
          _checkVehicleByPlate();
        }
      });
    } else {
      if (_detectedVehicle != null) {
        setState(() {
          _detectedVehicle = null;
          _vehicleId = null;
          _vehiclePlate = null;
        });
      }
    }
  }

  Future<void> _checkVehicleByPlate() async {
    final p1 = _plate1Controller.text.trim();
    final p2 = _plate2Controller.text.trim();
    final iran = _plateIranController.text.trim();
    if (p1.length != 2 || p2.length != 3 || iran.length != 2) return;

    final plateDisplay = "$p1 $_plateLetter $p2 - ایران $iran";

    setState(() => _isCheckingPlate = true);

    try {
      final masterRepo = ref.read(masterDataRepositoryProvider);

      // Search candidate vehicles from server by plate part (3 digits)
      final searchRes = await masterRepo.fetchVehicles(search: p2);
      VehicleItem? match;
      for (final v in searchRes) {
        if (_isPlateMatch(v.plateNumber, plateDisplay)) {
          match = v;
          break;
        }
      }

      if (match == null) {
        final broadRes = await masterRepo.fetchVehicles(search: plateDisplay);
        for (final v in broadRes) {
          if (_isPlateMatch(v.plateNumber, plateDisplay)) {
            match = v;
            break;
          }
        }
      }

      if (!mounted) return;

      if (match != null) {
        setState(() {
          _detectedVehicle = match;
          _vehicleId = match!.id;
          _vehiclePlate = match!.plateNumber;
          _isCheckingPlate = false;
        });

        // Try to fetch last ticket history for this vehicle to auto-populate party, product, driver
        try {
          final ticketRepo = ref.read(ticketRepositoryProvider);
          final history = await ticketRepo.fetchTickets(
            vehicleId: match.id,
            ordering: '-id',
          );
          if (history.results.isNotEmpty && mounted) {
            final lastTicket = history.results.first;
            WeighTicketDetailModel? detail;
            try {
              detail = await ticketRepo.fetchTicketDetail(lastTicket.id);
            } catch (_) {}

            if (mounted) {
              setState(() {
                if (_partyId == null) {
                  _partyId = detail?.partyDisplay?['id'] as int? ?? lastTicket.party;
                  _partyName = detail?.partyDisplay?['name']?.toString() ?? lastTicket.partyName;
                }
                if (_productId == null) {
                  _productId = detail?.productDisplay?['id'] as int? ?? lastTicket.product;
                  _productName = detail?.productDisplay?['name']?.toString() ?? lastTicket.productName;
                }
                final dName = detail?.driverDisplay ?? lastTicket.driverName;
                if (_driverCustomController.text.trim().isEmpty && dName != null && dName.isNotEmpty) {
                  _driverCustomController.text = dName;
                  _driverName = dName;
                }
                final dMobile = detail?.driverMobileDisplay;
                if (_driverMobileController.text.trim().isEmpty && dMobile != null && dMobile.isNotEmpty) {
                  _driverMobileController.text = dMobile;
                }
              });
            }
          }

          // If mobile is still empty, search driver master data to find registered mobile
          if (_driverMobileController.text.trim().isEmpty && _driverCustomController.text.trim().isNotEmpty) {
            try {
              final drivers = await masterRepo.fetchDrivers(search: _driverCustomController.text.trim());
              final matchedDriver = drivers.cast<DriverItem?>().firstWhere(
                (d) => d != null && d.name.trim() == _driverCustomController.text.trim(),
                orElse: () => null,
              );
              if (matchedDriver != null && mounted) {
                setState(() {
                  _driverId = matchedDriver.id;
                  _driverName = matchedDriver.name;
                  if (matchedDriver.mobile.isNotEmpty) {
                    _driverMobileController.text = matchedDriver.mobile;
                  }
                });
              }
            } catch (_) {}
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "خودرو در سیستم شناسایی شد (${match.plateNumber}) و اطلاعات فرم تکمیل گردید.",
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _detectedVehicle = null;
          _isCheckingPlate = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingPlate = false);
      }
    }
  }

  String _getPlateDisplay() {
    final p1 = _plate1Controller.text.trim();
    final p2 = _plate2Controller.text.trim();
    final iran = _plateIranController.text.trim();
    if (p1.isEmpty && p2.isEmpty && iran.isEmpty && _vehiclePlate != null) {
      return _vehiclePlate!;
    }
    if (p1.isEmpty && p2.isEmpty && iran.isEmpty) {
      return "";
    }
    return "$p1 $_plateLetter $p2 - ایران $iran";
  }

  Future<List<SearchableSelectItem<int>>> _searchMasterData(String endpoint, String query) async {
    final client = ref.read(apiClientProvider);
    try {
      final res = await client.request(
        endpoint,
        queryParameters: {'search': query},
      );
      final data = res.data;
      if (data is Map<String, dynamic> && data['results'] is List) {
        return (data['results'] as List).map((e) {
          final m = e as Map<String, dynamic>;
          final id = m['id'] is int ? m['id'] : int.parse(m['id'].toString());
          final title = m['name']?.toString() ?? m['full_name']?.toString() ?? m['plate_display']?.toString() ?? '';
          final sub = m['code']?.toString() ?? m['mobile']?.toString();
          return SearchableSelectItem<int>(id: id as int, title: title, subtitle: sub, extra: m);
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _showAddVehicleDialog() async {
    final currentPlate = _getPlateDisplay();
    final hasCurrentPlate = _plate1Controller.text.isNotEmpty && _plate2Controller.text.isNotEmpty;
    final plateCtrl = TextEditingController(text: hasCurrentPlate ? currentPlate : '');
    final smartCtrl = TextEditingController();
    bool isSaving = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
          title: const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text("تعریف و ثبت خودرو جدید", overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          actionsOverflowButtonSpacing: 8,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: plateCtrl,
                  decoration: const InputDecoration(
                    labelText: "پلاک خودرو *",
                    hintText: "مثال: 12 ع 345 - ایران 72",
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: smartCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "شماره کارت هوشمند ناوگان (اختیاری)",
                    prefixIcon: Icon(Icons.credit_card_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text("انصراف"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final pText = plateCtrl.text.trim();
                      if (pText.isEmpty) {
                        setDlgState(() => dialogError = "وارد کردن پلاک خودرو الزامی است.");
                        return;
                      }
                      setDlgState(() {
                        isSaving = true;
                        dialogError = null;
                      });
                      try {
                        final repo = ref.read(masterDataRepositoryProvider);
                        final newVehicle = await repo.saveVehicle({
                          'plate_number': pText,
                          'smart_card_number': smartCtrl.text.trim(),
                          'is_active': true,
                        });
                        if (mounted) {
                          setState(() {
                            _vehicleId = newVehicle.id;
                            _vehiclePlate = newVehicle.plateNumber;
                            final parsed = PlateFormatter.parsePlate(newVehicle.plateNumber);
                            if (parsed != null) {
                              _plate1Controller.text = parsed.part1;
                              _plateLetter = parsed.letter;
                              _plate2Controller.text = parsed.part2;
                              _plateIranController.text = parsed.iranCode;
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("خودرو با پلاک $pText با موفقیت در سیستم ثبت و انتخاب شد."),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() {
                          isSaving = false;
                          if (e is ServerFailure) {
                            dialogError = e.message;
                          } else {
                            dialogError = "خطا در ثبت خودرو در سرور اصلی: ${e.toString()}";
                          }
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("ثبت"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPartyDialog({String? initialName}) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final codeCtrl = TextEditingController(text: "P${DateTime.now().millisecondsSinceEpoch % 100000}");
    final phoneCtrl = TextEditingController();
    final ecoCtrl = TextEditingController();
    bool isSaving = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "تعریف و ثبت طرف‌حساب جدید",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actionsOverflowButtonSpacing: 8,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "نام شخص یا شرکت *",
                    hintText: "مثال: شرکت بازرگانی کشاورزی امید",
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: "کد طرف‌حساب *",
                    hintText: "مثال: P1024",
                    prefixIcon: Icon(Icons.tag_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "شماره تماس (اختیاری)",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ecoCtrl,
                  decoration: const InputDecoration(
                    labelText: "کد اقتصادی / کد ملی (اختیاری)",
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text("انصراف"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final code = codeCtrl.text.trim();
                      if (name.isEmpty) {
                        setDlgState(() => dialogError = "وارد کردن نام طرف‌حساب الزامی است.");
                        return;
                      }
                      if (code.isEmpty) {
                        setDlgState(() => dialogError = "وارد کردن کد طرف‌حساب الزامی است.");
                        return;
                      }
                      setDlgState(() {
                        isSaving = true;
                        dialogError = null;
                      });
                      try {
                        final repo = ref.read(masterDataRepositoryProvider);
                        final newParty = await repo.saveParty({
                          'name': name,
                          'code': code,
                          'phone': phoneCtrl.text.trim(),
                          'economic_code': ecoCtrl.text.trim(),
                          'is_active': true,
                        });
                        if (mounted) {
                          setState(() {
                            _partyId = newParty.id;
                            _partyName = newParty.name;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("طرف‌حساب «$name» با موفقیت در سیستم ثبت و انتخاب شد."),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() {
                          isSaving = false;
                          if (e is ServerFailure) {
                            dialogError = e.message;
                          } else {
                            dialogError = "خطا در ثبت طرف‌حساب در سرور اصلی: ${e.toString()}";
                          }
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("ثبت"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProductDialog({String? initialName}) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final codeCtrl = TextEditingController(text: "PRD${DateTime.now().millisecondsSinceEpoch % 100000}");
    final tolCtrl = TextEditingController();
    bool isSaving = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
          title: const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text("تعریف و ثبت کالای جدید", overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          actionsOverflowButtonSpacing: 8,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "نام کالا / محموله *",
                    hintText: "مثال: گندم، ذرت، کنجاله سویا، ...",
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: "کد کالا *",
                    hintText: "مثال: PRD101",
                    prefixIcon: Icon(Icons.tag_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tolCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "درصد تلورانس مجاز (اختیاری)",
                    hintText: "مثال: 0.5",
                    prefixIcon: Icon(Icons.percent_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text("انصراف"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final code = codeCtrl.text.trim();
                      if (name.isEmpty) {
                        setDlgState(() => dialogError = "وارد کردن نام کالا الزامی است.");
                        return;
                      }
                      if (code.isEmpty) {
                        setDlgState(() => dialogError = "وارد کردن کد کالا الزامی است.");
                        return;
                      }
                      setDlgState(() {
                        isSaving = true;
                        dialogError = null;
                      });
                      try {
                        final repo = ref.read(masterDataRepositoryProvider);
                        final newProduct = await repo.saveProduct({
                          'name': name,
                          'code': code,
                          'default_tolerance': double.tryParse(tolCtrl.text.trim()) ?? 0.0,
                          'is_active': true,
                        });
                        if (mounted) {
                          setState(() {
                            _productId = newProduct.id;
                            _productName = newProduct.name;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("کالای «$name» با موفقیت در سیستم ثبت و انتخاب شد."),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() {
                          isSaving = false;
                          if (e is ServerFailure) {
                            dialogError = e.message;
                          } else {
                            dialogError = "خطا در ثبت کالا در سرور اصلی: ${e.toString()}";
                          }
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("ثبت"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDriverDialog({String? initialName}) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final nationalCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    bool isSaving = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
          title: const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text("تعریف و ثبت راننده جدید", overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          actionsOverflowButtonSpacing: 8,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "نام و نام خانوادگی راننده *", prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nationalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "کد ملی *", prefixIcon: Icon(Icons.credit_card_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "شماره موبایل *", prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: licenseCtrl,
                  decoration: const InputDecoration(labelText: "شماره گواهینامه (اختیاری)", prefixIcon: Icon(Icons.assignment_ind_outlined)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text("انصراف"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final national = nationalCtrl.text.trim();
                      final mobile = mobileCtrl.text.trim();
                      if (name.isEmpty) {
                        setDlgState(() => dialogError = "وارد کردن نام راننده الزامی است.");
                        return;
                      }
                      if (national.isEmpty) {
                        setDlgState(() => dialogError = "وارد کردن کد ملی راننده الزامی است.");
                        return;
                      }
                      if (mobile.isEmpty) {
                        setDlgState(() => dialogError = "وارد کردن شماره موبایل راننده الزامی است.");
                        return;
                      }
                      setDlgState(() {
                        isSaving = true;
                        dialogError = null;
                      });
                      try {
                        final repo = ref.read(masterDataRepositoryProvider);
                        final newDriver = await repo.saveDriver({
                          'full_name': name,
                          'name': name,
                          'national_code': national,
                          'mobile': mobile,
                          'license_number': licenseCtrl.text.trim(),
                          'is_active': true,
                        });
                        if (mounted) {
                          setState(() {
                            _driverId = newDriver.id;
                            _driverName = newDriver.name;
                            _driverCustomController.text = newDriver.name;
                            _driverMobileController.text = newDriver.mobile;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("راننده «$name» با موفقیت در سیستم ثبت و انتخاب شد."),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() {
                          isSaving = false;
                          if (e is ServerFailure) {
                            dialogError = e.message;
                          } else {
                            dialogError = "خطا در ثبت راننده در سرور اصلی: ${e.toString()}";
                          }
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("ثبت"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTicket() async {
    final plateStr = _getPlateDisplay();
    if (plateStr.trim().isEmpty) {
      setState(() => _errorMessage = "ورود اطلاعات پلاک خودرو الزامی است.");
      return;
    }

    final firstWeightClean = _firstWeightController.text.replaceAll(',', '').trim();
    final firstWeight = double.tryParse(firstWeightClean) ?? 0.0;
    final sentWeightClean = _sentWeightController.text.replaceAll(',', '').trim();
    final sentWeight = double.tryParse(sentWeightClean) ?? 0.0;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      int? vehicleIdToUse = _vehicleId;
      int? driverIdToUse = _driverId;

      final masterRepo = ref.read(masterDataRepositoryProvider);

      // Auto-register driver if entered manually and not in master data
      if (driverIdToUse == null && _driverCustomController.text.trim().isNotEmpty) {
        final driverName = _driverCustomController.text.trim();
        final driverMobile = _driverMobileController.text.trim();
        try {
          final searchDrivers = await masterRepo.fetchDrivers(search: driverName);
          final matchDriver = searchDrivers.cast<DriverItem?>().firstWhere(
            (d) => d != null && (d.name.trim() == driverName || (driverMobile.isNotEmpty && d.mobile.trim() == driverMobile)),
            orElse: () => null,
          );
          if (matchDriver != null) {
            driverIdToUse = matchDriver.id;
          } else {
            final newDriver = await masterRepo.saveDriver({
              'full_name': driverName,
              'mobile': driverMobile,
              'is_active': true,
            });
            driverIdToUse = newDriver.id;
          }
          _driverId = driverIdToUse;
        } catch (e) {
          debugPrint("Auto-register driver info: $e");
        }
      }

      // If vehicle was entered manually (not selected from system), ensure it gets registered in the main system via API
      if (vehicleIdToUse == null && plateStr.trim().isNotEmpty) {
        try {
          final p1 = _plate1Controller.text.trim();
          final pl = _plateLetter;
          final p2 = _plate2Controller.text.trim();
          final ir = _plateIranController.text.trim();

          // Check if already registered in system by searching plate
          final searchRes = await masterRepo.fetchVehicles(search: p2.isNotEmpty ? p2 : plateStr.trim());
          final exactMatch = searchRes.cast<VehicleItem?>().firstWhere(
            (v) => v != null && (_isPlateMatch(v.plateNumber, plateStr.trim()) || (v.platePart1 == p1 && v.plateLetter == pl && v.platePart2 == p2 && v.plateIran == ir)),
            orElse: () => null,
          );
          if (exactMatch != null) {
            vehicleIdToUse = exactMatch.id;
          } else {
            // Auto-register new vehicle in the system API with OpenAPI expected schema
            final newVehicle = await masterRepo.saveVehicle({
              'plate_part1': p1,
              'plate_letter': pl,
              'plate_part2': p2,
              'plate_iran': ir,
              if (driverIdToUse != null) 'default_driver': driverIdToUse,
              'is_active': true,
            });
            vehicleIdToUse = newVehicle.id;
          }
          _vehicleId = vehicleIdToUse;
        } catch (e) {
          debugPrint("Auto-register vehicle info: $e");
        }
      }

      // Resolve or auto-create operation_type with matching direction
      int? opTypeId = _operationTypeId;
      if (opTypeId == null) {
        try {
          final client = ref.read(apiClientProvider);
          final res = await client.request(
            ApiEndpoints.operationTypes,
            queryParameters: {'direction': _selectedDirection},
          );
          final list = (res.data is Map<String, dynamic> && res.data['results'] is List)
              ? res.data['results'] as List
              : [];
          if (list.isNotEmpty) {
            opTypeId = list.first['id'] as int;
          } else {
            // Auto-create operation type with this direction in server
            final name = _selectedDirection == 'inbound'
                ? 'ورود کالا (خرید و مواد اولیه)'
                : (_selectedDirection == 'outbound' ? 'خروج کالا (فروش و محصول)' : 'عملیات داخلی');
            final code = _selectedDirection == 'inbound'
                ? 'INBOUND'
                : (_selectedDirection == 'outbound' ? 'OUTBOUND' : 'INTERNAL');
            final createRes = await client.request(
              ApiEndpoints.operationTypes,
              method: 'POST',
              data: {
                'name': name,
                'code': code,
                'direction': _selectedDirection,
                'is_active': true,
              },
            );
            if (createRes.data is Map<String, dynamic>) {
              opTypeId = createRes.data['id'] as int?;
            }
          }
        } catch (e) {
          debugPrint("Error resolving operation_type: $e");
        }
      }

      final payload = <String, dynamic>{
        'license_plate_display': plateStr,
        'first_weight': firstWeight,
        'sent_weight': sentWeight,
        'waybill_number': _waybillController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      if (opTypeId != null) payload['operation_type'] = opTypeId;
      if (_partyId != null) payload['party'] = _partyId;
      if (_productId != null) payload['product'] = _productId;
      if (driverIdToUse != null) payload['driver'] = driverIdToUse;
      if (vehicleIdToUse != null) payload['vehicle'] = vehicleIdToUse;
      if (_originId != null) payload['origin'] = _originId;
      if (_destinationId != null) payload['destination'] = _destinationId;
      if (_unloadLocationId != null) payload['unload_location'] = _unloadLocationId;

      if (_driverCustomController.text.trim().isNotEmpty) {
        payload['driver_name_custom'] = _driverCustomController.text.trim();
      }
      if (_driverMobileController.text.trim().isNotEmpty) {
        payload['driver_mobile_custom'] = _driverMobileController.text.trim();
      }

      final ticket = await ref.read(ticketRepositoryProvider).createTicket(payload);
      _isDirty = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vehicleIdToUse != null
                  ? "قبض شماره ${ticket.serialNumber} به همراه خودرو در سرور اصلی ثبت گردید."
                  : "قبض شماره ${ticket.serialNumber} با موفقیت در سرور ثبت گردید.",
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.ticketDetailPath(ticket.id));
      }
    } on ValidationFailure catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await AppConfirmDialog.show(
          context,
          title: "خروج از فرم",
          message: "تغییرات شما ذخیره نشده است. آیا مایل به خروج هستید؟",
          confirmText: "خروج بدون ذخیره",
          isDestructive: true,
        );
        if (confirm && context.mounted) {
          _isDirty = false;
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("صدور و ثبت قبض باسکول جدید"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'بازگشت',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.dashboard);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              onChanged: () => _isDirty = true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                  ],

                  // 1. Vehicle & Plate
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "مشخصات خودرو و پلاک",
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isMobile)
                              IconButton(
                                tooltip: "تعریف خودرو جدید",
                                visualDensity: VisualDensity.compact,
                                onPressed: _showAddVehicleDialog,
                                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                              )
                            else
                              TextButton.icon(
                                onPressed: _showAddVehicleDialog,
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                label: const Text(
                                  "تعریف خودرو جدید",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.md),
                        _buildPlateInput(),
                        const SizedBox(height: 6),
                        if (_isCheckingPlate) ...[
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "در حال بررسی و شناسایی پلاک در سیستم...",
                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ] else if (_detectedVehicle != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, size: 18, color: Color(0xFF059669)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "خودرو در سیستم شناسایی شد (شناسه: ${_detectedVehicle!.id})${_detectedVehicle!.smartCardNumber != null && _detectedVehicle!.smartCardNumber!.isNotEmpty ? ' | کارت هوشمند: ${_detectedVehicle!.smartCardNumber}' : ''} - اطلاعات پیش‌فرض تکمیل شد.",
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ] else ...[
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "در صورت ورود دستی، پلاک خودرو به طور خودکار در سیستم اصلی ثبت می‌شود.",
                                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        const SizedBox(height: AppDimensions.sm),
                        SearchableSelectField<int>(
                          key: ValueKey("vehicle-$_vehicleId"),
                          label: "انتخاب از خودروهای ثبت‌شده در سیستم",
                          initialValue: _vehicleId,
                          initialDisplay: _vehiclePlate,
                          onSearch: (q) => _searchMasterData(ApiEndpoints.vehicles, q),
                          onAddNew: _showAddVehicleDialog,
                          addNewText: "ثبت خودرو جدید",
                          onSelected: (item) {
                            setState(() {
                              _vehicleId = item?.id;
                              _vehiclePlate = item?.title;
                              if (item != null) {
                                final p = PlateFormatter.parsePlate(item.title);
                                if (p != null) {
                                  _plate1Controller.text = p.part1;
                                  _plateLetter = p.letter;
                                  _plate2Controller.text = p.part2;
                                  _plateIranController.text = p.iranCode;
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // 2. Party & Product
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "طرف حساب و کالای محموله",
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isMobile)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: "تعریف طرف‌حساب جدید",
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _showAddPartyDialog(),
                                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 20, color: AppColors.primary),
                                  ),
                                  IconButton(
                                    tooltip: "تعریف کالای جدید",
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _showAddProductDialog(),
                                    icon: const Icon(Icons.add_box_outlined, size: 20, color: AppColors.primary),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showAddPartyDialog(),
                                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                                    label: const Text("تعریف طرف‌حساب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: () => _showAddProductDialog(),
                                    icon: const Icon(Icons.add_box_outlined, size: 16),
                                    label: const Text("تعریف کالا", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        Text(
                          "نوع عملیات محموله (جهت تفکیک در آمار ورودی / خروجی):",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'inbound',
                                label: Text('ورودی (خرید)', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.green),
                              ),
                              ButtonSegment(
                                value: 'outbound',
                                label: Text('خروجی (فروش)', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.blue),
                              ),
                              ButtonSegment(
                                value: 'internal',
                                label: Text('داخلی', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.swap_horiz_rounded, size: 16),
                              ),
                            ],
                            selected: {_selectedDirection},
                            onSelectionChanged: (set) {
                              setState(() {
                                _selectedDirection = set.first;
                                _operationTypeId = null;
                                _operationTypeName = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        if (isMobile) ...[
                          SearchableSelectField<int>(
                            key: ValueKey("party-$_partyId"),
                            label: "طرف حساب تجاری",
                            isRequired: true,
                            initialValue: _partyId,
                            initialDisplay: _partyName,
                            onSearch: (q) => _searchMasterData(ApiEndpoints.parties, q),
                            onAddNew: () => _showAddPartyDialog(),
                            onAddNewWithQuery: (q) => _showAddPartyDialog(initialName: q),
                            addNewText: "ثبت طرف‌حساب جدید",
                            onSelected: (item) {
                              setState(() {
                                _partyId = item?.id;
                                _partyName = item?.title;
                              });
                            },
                          ),
                          const SizedBox(height: AppDimensions.md),
                          SearchableSelectField<int>(
                            key: ValueKey("product-$_productId"),
                            label: "کالای محموله",
                            isRequired: true,
                            initialValue: _productId,
                            initialDisplay: _productName,
                            onSearch: (q) => _searchMasterData(ApiEndpoints.products, q),
                            onAddNew: () => _showAddProductDialog(),
                            onAddNewWithQuery: (q) => _showAddProductDialog(initialName: q),
                            addNewText: "ثبت کالای جدید",
                            onSelected: (item) {
                              setState(() {
                                _productId = item?.id;
                                _productName = item?.title;
                              });
                            },
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: SearchableSelectField<int>(
                                  key: ValueKey("party-$_partyId"),
                                  label: "طرف حساب تجاری",
                                  isRequired: true,
                                  initialValue: _partyId,
                                  initialDisplay: _partyName,
                                  onSearch: (q) => _searchMasterData(ApiEndpoints.parties, q),
                                  onAddNew: () => _showAddPartyDialog(),
                                  onAddNewWithQuery: (q) => _showAddPartyDialog(initialName: q),
                                  addNewText: "ثبت طرف‌حساب جدید",
                                  onSelected: (item) {
                                    setState(() {
                                      _partyId = item?.id;
                                      _partyName = item?.title;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableSelectField<int>(
                                  key: ValueKey("product-$_productId"),
                                  label: "کالای محموله",
                                  isRequired: true,
                                  initialValue: _productId,
                                  initialDisplay: _productName,
                                  onSearch: (q) => _searchMasterData(ApiEndpoints.products, q),
                                  onAddNew: () => _showAddProductDialog(),
                                  onAddNewWithQuery: (q) => _showAddProductDialog(initialName: q),
                                  addNewText: "ثبت کالای جدید",
                                  onSelected: (item) {
                                    setState(() {
                                      _productId = item?.id;
                                      _productName = item?.title;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // 3. Driver & Waybill
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "راننده و اطلاعات بارنامه",
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isMobile)
                              IconButton(
                                tooltip: "تعریف راننده جدید",
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _showAddDriverDialog(),
                                icon: const Icon(Icons.person_add_alt_outlined, size: 20, color: AppColors.primary),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => _showAddDriverDialog(),
                                icon: const Icon(Icons.person_add_alt_outlined, size: 16),
                                label: const Text("تعریف راننده", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.md),
                        SearchableSelectField<int>(
                          key: ValueKey("driver-$_driverId"),
                          label: "انتخاب راننده از سیستم",
                          initialValue: _driverId,
                          initialDisplay: _driverName,
                          onSearch: (q) => _searchMasterData(ApiEndpoints.drivers, q),
                          onAddNew: () => _showAddDriverDialog(),
                          onAddNewWithQuery: (q) => _showAddDriverDialog(initialName: q),
                          addNewText: "ثبت راننده جدید",
                          onSelected: (item) {
                            setState(() {
                              _driverId = item?.id;
                              _driverName = item?.title;
                              _driverCustomController.text = item?.title ?? '';
                              if (item?.extra is Map<String, dynamic>) {
                                final mobile = item!.extra['mobile']?.toString();
                                if (mobile != null && mobile.isNotEmpty) {
                                  _driverMobileController.text = mobile;
                                }
                              } else if (item?.subtitle != null && item!.subtitle!.isNotEmpty) {
                                _driverMobileController.text = item.subtitle!;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppDimensions.md),
                        if (isMobile) ...[
                          TextFormField(
                            controller: _driverCustomController,
                            decoration: const InputDecoration(labelText: "نام راننده"),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          TextFormField(
                            controller: _driverMobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: "شماره موبایل راننده"),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          TextFormField(
                            controller: _waybillController,
                            decoration: const InputDecoration(labelText: "شماره بارنامه"),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _driverCustomController,
                                  decoration: const InputDecoration(labelText: "نام راننده"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _driverMobileController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(labelText: "شماره موبایل راننده"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _waybillController,
                                  decoration: const InputDecoration(labelText: "شماره بارنامه"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // 4. Weight Information
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("سنجش وزن و توزین اولیه", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppDimensions.md),
                        if (isMobile) ...[
                          WeightInputField(
                            label: "وزن اول (باسکول)",
                            controller: _firstWeightController,
                            isRequired: true,
                          ),
                          const SizedBox(height: AppDimensions.md),
                          WeightInputField(
                            label: "وزن اعلامی / ارسالی در بارنامه",
                            controller: _sentWeightController,
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: WeightInputField(
                                  label: "وزن اول (باسکول)",
                                  controller: _firstWeightController,
                                  isRequired: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: WeightInputField(
                                  label: "وزن اعلامی / ارسالی در بارنامه",
                                  controller: _sentWeightController,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppDimensions.md),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "توضیحات و ملاحظات سند",
                            hintText: "ملاحظات بارگیری یا تخلیه...",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                        : const Text("ثبت قطعی قبض در سرور و صدور سریال", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("شماره پلاک ایران (۲ رقم - حرف - ۳ رقم - کد ایران)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Part 1 (2 digits)
                SizedBox(
                  width: 55,
                  child: TextFormField(
                    controller: _plate1Controller,
                    focusNode: _plate1FocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    inputFormatters: [_PersianDigitFormatter()],
                    decoration: const InputDecoration(
                      hintText: "12",
                      counterText: "",
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    onChanged: (val) {
                      if (val.length >= 2) {
                        _plate2FocusNode.requestFocus();
                      }
                      _onPlateChanged();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                // Letter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
                  ),
                  child: DropdownButton<String>(
                    value: _plateLetter,
                    underline: const SizedBox(),
                    isDense: true,
                    items: PlateFormatter.plateLetters
                        .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _plateLetter = val);
                        _plate2FocusNode.requestFocus();
                        _onPlateChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                // Part 2 (3 digits)
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _plate2Controller,
                    focusNode: _plate2FocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    textAlign: TextAlign.center,
                    inputFormatters: [_PersianDigitFormatter()],
                    decoration: const InputDecoration(
                      hintText: "345",
                      counterText: "",
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    onChanged: (val) {
                      if (val.length >= 3) {
                        _plateIranFocusNode.requestFocus();
                      }
                      _onPlateChanged();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                const Text("ایران", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                // Iran Code (2 digits)
                SizedBox(
                  width: 55,
                  child: TextFormField(
                    controller: _plateIranController,
                    focusNode: _plateIranFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    inputFormatters: [_PersianDigitFormatter()],
                    decoration: const InputDecoration(
                      hintText: "72",
                      counterText: "",
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    onChanged: (val) {
                      if (val.length >= 2) {
                        _plateIranFocusNode.unfocus();
                      }
                      _onPlateChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PersianDigitFormatter extends TextInputFormatter {
  static const _persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static const _arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(_persian[i], '$i').replaceAll(_arabic[i], '$i');
    }
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
