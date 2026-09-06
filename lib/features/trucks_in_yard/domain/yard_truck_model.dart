import '../../tickets/domain/ticket_models.dart';

class YardTruckModel {
  final int id;
  final String serialNumber;
  final String licensePlateDisplay;
  final String? driverName;
  final String? driverMobile;
  final String? partyName;
  final String? productName;
  final double firstWeight;
  final String? firstWeightDateJalali;
  final String? firstWeightTime;
  final DateTime? firstWeightDateTime;
  final ChoiceItem status;

  YardTruckModel({
    required this.id,
    required this.serialNumber,
    required this.licensePlateDisplay,
    this.driverName,
    this.driverMobile,
    this.partyName,
    this.productName,
    required this.firstWeight,
    this.firstWeightDateJalali,
    this.firstWeightTime,
    this.firstWeightDateTime,
    required this.status,
  });

  factory YardTruckModel.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    final timeStr = json['first_weight_timestamp'] ?? json['created_at'];
    if (timeStr != null) {
      dt = DateTime.tryParse(timeStr.toString());
    }

    return YardTruckModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      serialNumber: json['serial_number']?.toString() ?? '',
      licensePlateDisplay: json['license_plate_display']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? json['driver_display']?.toString(),
      driverMobile: json['driver_mobile']?.toString() ?? json['driver_mobile_display']?.toString(),
      partyName: json['party_name']?.toString(),
      productName: json['product_name']?.toString(),
      firstWeight: double.tryParse(json['first_weight']?.toString() ?? '0') ?? 0.0,
      firstWeightDateJalali: json['first_weight_date_jalali']?.toString(),
      firstWeightTime: json['first_weight_time']?.toString(),
      firstWeightDateTime: dt,
      status: ChoiceItem.fromJson(json['status']),
    );
  }

  Duration get waitingDuration {
    if (firstWeightDateTime == null) return Duration.zero;
    final now = DateTime.now();
    final diff = now.difference(firstWeightDateTime!);
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isLongWait => waitingDuration.inHours >= 3;

  String get waitingDurationDisplay {
    if (firstWeightDateTime == null) {
      if (firstWeightTime != null) {
        return 'از ساعت ';
      }
      return '-';
    }
    final dur = waitingDuration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);

    if (hours > 0) {
      return ' ساعت و  دقیقه';
    }
    return ' دقیقه';
  }
}
