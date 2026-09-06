class BaseMasterEntity {
  final int id;
  final String name;
  final bool isActive;

  BaseMasterEntity({required this.id, required this.name, this.isActive = true});
}

class ProductItem {
  final int id;
  final String code;
  final String name;
  final double defaultTolerance;
  final bool isActive;

  ProductItem({
    required this.id,
    required this.code,
    required this.name,
    required this.defaultTolerance,
    this.isActive = true,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        defaultTolerance: double.tryParse(json['default_tolerance']?.toString() ?? '0') ?? 0.0,
        isActive: json['is_active'] != false,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'default_tolerance': defaultTolerance,
        'is_active': isActive,
      };
}

class PartyItem {
  final int id;
  final String code;
  final String name;
  final String? partyType;
  final String? economicCode;
  final String? phone;
  final bool isActive;

  PartyItem({
    required this.id,
    required this.code,
    required this.name,
    this.partyType,
    this.economicCode,
    this.phone,
    this.isActive = true,
  });

  factory PartyItem.fromJson(Map<String, dynamic> json) => PartyItem(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        partyType: json['party_type']?.toString(),
        economicCode: json['economic_code']?.toString(),
        phone: json['phone']?.toString(),
        isActive: json['is_active'] != false,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'party_type': partyType,
        'economic_code': economicCode,
        'phone': phone,
        'is_active': isActive,
      };
}

class DriverItem {
  final int id;
  final String nationalCode;
  final String name;
  final String mobile;
  final String? licenseNumber;
  final bool isActive;

  DriverItem({
    required this.id,
    required this.nationalCode,
    required this.name,
    required this.mobile,
    this.licenseNumber,
    this.isActive = true,
  });

  factory DriverItem.fromJson(Map<String, dynamic> json) => DriverItem(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        nationalCode: json['national_code']?.toString() ?? '',
        name: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
        mobile: json['mobile']?.toString() ?? '',
        licenseNumber: json['license_number']?.toString(),
        isActive: json['is_active'] != false,
      );

  Map<String, dynamic> toJson() => {
        'full_name': name,
        'name': name,
        'national_code': nationalCode,
        'mobile': mobile,
        'license_number': licenseNumber,
        'is_active': isActive,
      };
}

class VehicleItem {
  final int id;
  final String plateNumber;
  final String? platePart1;
  final String? plateLetter;
  final String? platePart2;
  final String? plateIran;
  final int? vehicleType;
  final String? vehicleTypeName;
  final String? smartCardNumber;
  final bool isActive;

  VehicleItem({
    required this.id,
    required this.plateNumber,
    this.platePart1,
    this.plateLetter,
    this.platePart2,
    this.plateIran,
    this.vehicleType,
    this.vehicleTypeName,
    this.smartCardNumber,
    this.isActive = true,
  });

  factory VehicleItem.fromJson(Map<String, dynamic> json) {
    final p1 = json['plate_part1']?.toString() ?? '';
    final pl = json['plate_letter']?.toString() ?? '';
    final p2 = json['plate_part2']?.toString() ?? '';
    final ir = json['plate_iran']?.toString() ?? '';
    final constructed = (p1.isNotEmpty && pl.isNotEmpty && p2.isNotEmpty && ir.isNotEmpty)
        ? "$p1 $pl $p2 - ایران $ir"
        : '';
    final display = json['plate_display']?.toString() ??
        json['plate_number']?.toString() ??
        json['plate']?.toString() ??
        constructed;

    return VehicleItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      plateNumber: display.isNotEmpty ? display : 'بدون پلاک',
      platePart1: p1.isNotEmpty ? p1 : null,
      plateLetter: pl.isNotEmpty ? pl : null,
      platePart2: p2.isNotEmpty ? p2 : null,
      plateIran: ir.isNotEmpty ? ir : null,
      vehicleType: json['vehicle_type'] as int?,
      vehicleTypeName: json['vehicle_type_name']?.toString(),
      smartCardNumber: json['smart_card_number']?.toString(),
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (platePart1 != null && platePart1!.isNotEmpty) 'plate_part1': platePart1,
        if (plateLetter != null && plateLetter!.isNotEmpty) 'plate_letter': plateLetter,
        if (platePart2 != null && platePart2!.isNotEmpty) 'plate_part2': platePart2,
        if (plateIran != null && plateIran!.isNotEmpty) 'plate_iran': plateIran,
        'plate_display': plateNumber,
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        'smart_card_number': smartCardNumber,
        'is_active': isActive,
      };
}

class SimpleMasterItem {
  final int id;
  final String title;
  final String? code;
  final bool isActive;

  SimpleMasterItem({
    required this.id,
    required this.title,
    this.code,
    this.isActive = true,
  });

  factory SimpleMasterItem.fromJson(Map<String, dynamic> json) => SimpleMasterItem(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        title: (json['title'] ?? json['name'])?.toString() ?? '',
        code: json['code']?.toString(),
        isActive: json['is_active'] != false,
      );

  Map<String, dynamic> toJson() => {
        'name': title,
        'title': title,
        if (code != null) 'code': code,
        'is_active': isActive,
      };
}
