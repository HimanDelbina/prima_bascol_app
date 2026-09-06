class ChoiceItem {
  final String code;
  final String label;

  ChoiceItem({required this.code, required this.label});

  factory ChoiceItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return ChoiceItem(
        code: json['code']?.toString() ?? '',
        label: json['label']?.toString() ?? json['code']?.toString() ?? '',
      );
    }
    return ChoiceItem(code: json?.toString() ?? '', label: json?.toString() ?? '');
  }
}

class WeighTicketListModel {
  final int id;
  final String serialNumber;
  final ChoiceItem status;
  final ChoiceItem? weightMode;
  final int? operationType;
  final String? operationTypeName;
  final int? party;
  final String? partyName;
  final int? product;
  final String? productName;
  final String licensePlateDisplay;
  final String? driverName;
  final double firstWeight;
  final String? firstWeightDateJalali;
  final double secondWeight;
  final String? secondWeightDateJalali;
  final double grossWeight;
  final double tareWeight;
  final double netWeight;
  final double sentWeight;
  final double weightDifference;
  final double lossWeight;
  final double finalWeight;
  final bool isToleranceExceeded;
  final String? createdAtJalali;

  WeighTicketListModel({
    required this.id,
    required this.serialNumber,
    required this.status,
    this.weightMode,
    this.operationType,
    this.operationTypeName,
    this.party,
    this.partyName,
    this.product,
    this.productName,
    required this.licensePlateDisplay,
    this.driverName,
    required this.firstWeight,
    this.firstWeightDateJalali,
    required this.secondWeight,
    this.secondWeightDateJalali,
    required this.grossWeight,
    required this.tareWeight,
    required this.netWeight,
    required this.sentWeight,
    required this.weightDifference,
    required this.lossWeight,
    required this.finalWeight,
    required this.isToleranceExceeded,
    this.createdAtJalali,
  });

  factory WeighTicketListModel.fromJson(Map<String, dynamic> json) {
    return WeighTicketListModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      serialNumber: json['serial_number']?.toString() ?? '',
      status: ChoiceItem.fromJson(json['status']),
      weightMode: json['weight_mode'] != null ? ChoiceItem.fromJson(json['weight_mode']) : null,
      operationType: json['operation_type'] as int?,
      operationTypeName: json['operation_type_name']?.toString(),
      party: json['party'] as int?,
      partyName: json['party_name']?.toString(),
      product: json['product'] as int?,
      productName: json['product_name']?.toString(),
      licensePlateDisplay: json['license_plate_display']?.toString() ?? '',
      driverName: json['driver_name']?.toString(),
      firstWeight: double.tryParse(json['first_weight']?.toString() ?? '0') ?? 0.0,
      firstWeightDateJalali: json['first_weight_date_jalali']?.toString(),
      secondWeight: double.tryParse(json['second_weight']?.toString() ?? '0') ?? 0.0,
      secondWeightDateJalali: json['second_weight_date_jalali']?.toString(),
      grossWeight: double.tryParse(json['gross_weight']?.toString() ?? '0') ?? 0.0,
      tareWeight: double.tryParse(json['tare_weight']?.toString() ?? '0') ?? 0.0,
      netWeight: double.tryParse(json['net_weight']?.toString() ?? '0') ?? 0.0,
      sentWeight: double.tryParse(json['sent_weight']?.toString() ?? '0') ?? 0.0,
      weightDifference: double.tryParse(json['weight_difference']?.toString() ?? '0') ?? 0.0,
      lossWeight: double.tryParse(json['loss_weight']?.toString() ?? '0') ?? 0.0,
      finalWeight: double.tryParse(json['final_weight']?.toString() ?? '0') ?? 0.0,
      isToleranceExceeded: json['is_tolerance_exceeded'] == true,
      createdAtJalali: json['created_at_jalali']?.toString(),
    );
  }
}

class WeighTicketDetailModel {
  final int id;
  final String serialNumber;
  final ChoiceItem status;
  final ChoiceItem? weightMode;
  final Map<String, dynamic>? operationTypeDisplay;
  final Map<String, dynamic>? partyDisplay;
  final Map<String, dynamic>? productDisplay;
  final Map<String, dynamic>? vehicleDisplay;
  final String? driverDisplay;
  final String? driverMobileDisplay;
  final String? vehicleTypeDisplay;
  final String? originName;
  final String? destinationName;
  final String? unloadLocationName;
  final String? lossTypeName;
  final String licensePlateDisplay;
  final String? waybillNumber;
  final int loadCount;

  // First Weight
  final double firstWeight;
  final String? firstWeightDateJalali;
  final String? firstWeightTime;
  final String? firstWeightOperatorName;

  // Second Weight
  final double secondWeight;
  final String? secondWeightDateJalali;
  final String? secondWeightTime;
  final String? secondWeightOperatorName;

  // Computed Weights
  final double grossWeight;
  final double tareWeight;
  final double netWeight;
  final double sentWeight;
  final double weightDifference;
  final double weightDifferencePercent;
  final bool isToleranceExceeded;

  // Loss
  final double lossPercent;
  final double lossWeight;
  final bool isLossOverridden;
  final String? lossOverrideReason;
  final double finalWeight;

  // Audit / Status
  final String? notes;
  final String? cancellationReason;
  final String? cancelledByName;
  final String? cancelledAtJalali;
  final String? lastEditedByName;
  final String? lastEditReason;
  final int riskScore;
  final String riskLevel;
  final String? createdAtJalali;

  WeighTicketDetailModel({
    required this.id,
    required this.serialNumber,
    required this.status,
    this.weightMode,
    this.operationTypeDisplay,
    this.partyDisplay,
    this.productDisplay,
    this.vehicleDisplay,
    this.driverDisplay,
    this.driverMobileDisplay,
    this.vehicleTypeDisplay,
    this.originName,
    this.destinationName,
    this.unloadLocationName,
    this.lossTypeName,
    required this.licensePlateDisplay,
    this.waybillNumber,
    required this.loadCount,
    required this.firstWeight,
    this.firstWeightDateJalali,
    this.firstWeightTime,
    this.firstWeightOperatorName,
    required this.secondWeight,
    this.secondWeightDateJalali,
    this.secondWeightTime,
    this.secondWeightOperatorName,
    required this.grossWeight,
    required this.tareWeight,
    required this.netWeight,
    required this.sentWeight,
    required this.weightDifference,
    required this.weightDifferencePercent,
    required this.isToleranceExceeded,
    required this.lossPercent,
    required this.lossWeight,
    required this.isLossOverridden,
    this.lossOverrideReason,
    required this.finalWeight,
    this.notes,
    this.cancellationReason,
    this.cancelledByName,
    this.cancelledAtJalali,
    this.lastEditedByName,
    this.lastEditReason,
    required this.riskScore,
    required this.riskLevel,
    this.createdAtJalali,
  });

  factory WeighTicketDetailModel.fromJson(Map<String, dynamic> json) {
    return WeighTicketDetailModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      serialNumber: json['serial_number']?.toString() ?? '',
      status: ChoiceItem.fromJson(json['status']),
      weightMode: json['weight_mode'] != null ? ChoiceItem.fromJson(json['weight_mode']) : null,
      operationTypeDisplay: json['operation_type_display'] as Map<String, dynamic>?,
      partyDisplay: json['party_display'] as Map<String, dynamic>?,
      productDisplay: json['product_display'] as Map<String, dynamic>?,
      vehicleDisplay: json['vehicle_display'] as Map<String, dynamic>?,
      driverDisplay: json['driver_display']?.toString(),
      driverMobileDisplay: json['driver_mobile_display']?.toString(),
      vehicleTypeDisplay: json['vehicle_type_display']?.toString(),
      originName: json['origin_name']?.toString(),
      destinationName: json['destination_name']?.toString(),
      unloadLocationName: json['unload_location_name']?.toString(),
      lossTypeName: json['loss_type_name']?.toString(),
      licensePlateDisplay: json['license_plate_display']?.toString() ?? '',
      waybillNumber: json['waybill_number']?.toString(),
      loadCount: json['load_count'] is int ? json['load_count'] : 1,
      firstWeight: double.tryParse(json['first_weight']?.toString() ?? '0') ?? 0.0,
      firstWeightDateJalali: json['first_weight_date_jalali']?.toString(),
      firstWeightTime: json['first_weight_time']?.toString(),
      firstWeightOperatorName: json['first_weight_operator_name']?.toString(),
      secondWeight: double.tryParse(json['second_weight']?.toString() ?? '0') ?? 0.0,
      secondWeightDateJalali: json['second_weight_date_jalali']?.toString(),
      secondWeightTime: json['second_weight_time']?.toString(),
      secondWeightOperatorName: json['second_weight_operator_name']?.toString(),
      grossWeight: double.tryParse(json['gross_weight']?.toString() ?? '0') ?? 0.0,
      tareWeight: double.tryParse(json['tare_weight']?.toString() ?? '0') ?? 0.0,
      netWeight: double.tryParse(json['net_weight']?.toString() ?? '0') ?? 0.0,
      sentWeight: double.tryParse(json['sent_weight']?.toString() ?? '0') ?? 0.0,
      weightDifference: double.tryParse(json['weight_difference']?.toString() ?? '0') ?? 0.0,
      weightDifferencePercent: double.tryParse(json['weight_difference_percent']?.toString() ?? '0') ?? 0.0,
      isToleranceExceeded: json['is_tolerance_exceeded'] == true,
      lossPercent: double.tryParse(json['loss_percent']?.toString() ?? '0') ?? 0.0,
      lossWeight: double.tryParse(json['loss_weight']?.toString() ?? '0') ?? 0.0,
      isLossOverridden: json['is_loss_overridden'] == true,
      lossOverrideReason: json['loss_override_reason']?.toString(),
      finalWeight: double.tryParse(json['final_weight']?.toString() ?? '0') ?? 0.0,
      notes: json['notes']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      cancelledByName: json['cancelled_by_name']?.toString(),
      cancelledAtJalali: json['cancelled_at_jalali']?.toString(),
      lastEditedByName: json['last_edited_by_name']?.toString(),
      lastEditReason: json['last_edit_reason']?.toString(),
      riskScore: json['risk_score'] is int ? json['risk_score'] : int.tryParse(json['risk_score']?.toString() ?? '0') ?? 0,
      riskLevel: json['risk_level']?.toString() ?? 'low',
      createdAtJalali: json['created_at_jalali']?.toString(),
    );
  }
}
