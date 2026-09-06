class ManagementSummaryModel {
  final String period;
  final double totalTonnage;
  final int totalServices;
  final double tonnageChangePct;
  final double servicesChangePct;
  final double totalDiscrepancyTonnage;
  final double totalLossTonnage;
  final double averageTurnaroundMinutes;
  final String? executiveNarrative;
  final String? startDateJalali;
  final String? endDateJalali;

  ManagementSummaryModel({
    required this.period,
    required this.totalTonnage,
    required this.totalServices,
    required this.tonnageChangePct,
    required this.servicesChangePct,
    required this.totalDiscrepancyTonnage,
    required this.totalLossTonnage,
    required this.averageTurnaroundMinutes,
    this.executiveNarrative,
    this.startDateJalali,
    this.endDateJalali,
  });

  factory ManagementSummaryModel.fromJson(Map<String, dynamic> json) {
    final kpis = (json['kpis'] is Map<String, dynamic>) ? (json['kpis'] as Map<String, dynamic>) : json;
    final comp = (json['comparison'] is Map<String, dynamic>) ? (json['comparison'] as Map<String, dynamic>) : json;

    double parseVal(dynamic v1, dynamic v2, [dynamic v3, dynamic v4]) {
      final val = v1 ?? v2 ?? v3 ?? v4;
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final tonVal = parseVal(kpis['net_ton'], json['total_tonnage'], kpis['total_tonnage'], kpis['final_ton']);
    final kgVal = parseVal(kpis['net_kg'], json['total_net_weight'], kpis['total_kg']);
    final totalTon = tonVal > 0 ? tonVal : (kgVal > 0 ? kgVal / 1000.0 : 0.0);

    final rawServices = kpis['trips'] ?? kpis['completed_trips'] ?? json['total_services'] ?? json['total_tickets'] ?? 0;
    final totalServices = rawServices is int ? rawServices : int.tryParse(rawServices.toString()) ?? 0;

    final tonChange = parseVal(comp['tonnage_change_pct'], json['tonnage_change_pct']);
    final srvChange = parseVal(comp['services_change_pct'], json['services_change_pct']);

    final totalDisc = parseVal(kpis['diff_ton'], json['total_discrepancy_tonnage'], kpis['total_diff_ton']);
    final totalLoss = parseVal(kpis['loss_ton'], json['total_loss_tonnage'], kpis['total_loss_ton']);
    final turnaround = parseVal(kpis['avg_turnaround_minutes'], json['average_turnaround_minutes'], 45.0);

    return ManagementSummaryModel(
      period: json['period_label']?.toString() ?? json['period']?.toString() ?? 'month',
      totalTonnage: totalTon,
      totalServices: totalServices,
      tonnageChangePct: tonChange,
      servicesChangePct: srvChange,
      totalDiscrepancyTonnage: totalDisc,
      totalLossTonnage: totalLoss,
      averageTurnaroundMinutes: turnaround > 0 ? turnaround : 45.0,
      executiveNarrative: json['narrative']?.toString() ?? json['executive_narrative']?.toString(),
      startDateJalali: json['start_date_jalali']?.toString(),
      endDateJalali: json['end_date_jalali']?.toString(),
    );
  }
}

class ManagementBreakdownItem {
  final String name;
  final double tonnage;
  final int count;
  final double sharePercentage;

  ManagementBreakdownItem({
    required this.name,
    required this.tonnage,
    required this.count,
    required this.sharePercentage,
  });

  factory ManagementBreakdownItem.fromJson(Map<String, dynamic> json) {
    double parseVal(dynamic v1, dynamic v2, [dynamic v3, dynamic v4]) {
      final val = v1 ?? v2 ?? v3 ?? v4;
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final rawTrips = json['trips'] ?? json['count'] ?? json['total_tickets'] ?? json['total_loads'] ?? 0;
    final count = rawTrips is int ? rawTrips : int.tryParse(rawTrips.toString()) ?? 0;

    final ton = parseVal(json['net_ton'], json['final_ton'], json['tonnage'], json['total_net_weight']);
    final share = parseVal(json['share_pct'], json['share_percentage'], json['percentage']);

    return ManagementBreakdownItem(
      name: (json['name'] ?? json['product_name'] ?? json['party_name'] ?? json['title'] ?? 'نامشخص').toString(),
      tonnage: ton,
      count: count,
      sharePercentage: share,
    );
  }
}
