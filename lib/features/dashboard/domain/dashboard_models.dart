class DashboardSummaryModel {
  final int todayTicketCount;
  final int todayCompletedCount;
  final double todayNetWeight;
  final double todayTonnage;
  final double todayInboundWeight;
  final double todayOutboundWeight;
  final int waitingSecondWeight;
  final int todayDiscrepancies;
  final int openAlertsCount;
  final int todayCriticalAlerts;

  DashboardSummaryModel({
    required this.todayTicketCount,
    required this.todayCompletedCount,
    required this.todayNetWeight,
    required this.todayTonnage,
    required this.todayInboundWeight,
    required this.todayOutboundWeight,
    required this.waitingSecondWeight,
    required this.todayDiscrepancies,
    required this.openAlertsCount,
    required this.todayCriticalAlerts,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final net = double.tryParse(json['today_net_weight']?.toString() ?? '0') ?? 0.0;
    final inW = double.tryParse(json['today_inbound_weight']?.toString() ?? '0') ?? 0.0;
    final outW = double.tryParse(json['today_outbound_weight']?.toString() ?? '0') ?? 0.0;

    // Fallback: if server returned 0 for both inbound and outbound because tickets had no operation_type,
    // default to net weight as inbound so dashboard KPI cards accurately reflect operation volume
    final effectiveInbound = (inW == 0.0 && outW == 0.0 && net > 0.0) ? net : inW;

    return DashboardSummaryModel(
      todayTicketCount: json['today_ticket_count'] is int ? json['today_ticket_count'] : int.tryParse(json['today_ticket_count']?.toString() ?? '0') ?? 0,
      todayCompletedCount: json['today_completed_count'] is int ? json['today_completed_count'] : int.tryParse(json['today_completed_count']?.toString() ?? '0') ?? 0,
      todayNetWeight: net,
      todayTonnage: double.tryParse(json['today_tonnage']?.toString() ?? '0') ?? 0.0,
      todayInboundWeight: effectiveInbound,
      todayOutboundWeight: outW,
      waitingSecondWeight: json['waiting_second_weight'] is int ? json['waiting_second_weight'] : int.tryParse(json['waiting_second_weight']?.toString() ?? '0') ?? 0,
      todayDiscrepancies: json['today_discrepancies'] is int ? json['today_discrepancies'] : int.tryParse(json['today_discrepancies']?.toString() ?? '0') ?? 0,
      openAlertsCount: json['open_alerts_count'] is int ? json['open_alerts_count'] : int.tryParse(json['open_alerts_count']?.toString() ?? '0') ?? 0,
      todayCriticalAlerts: json['today_critical_alerts'] is int ? json['today_critical_alerts'] : int.tryParse(json['today_critical_alerts']?.toString() ?? '0') ?? 0,
    );
  }
}

class DashboardTrendModel {
  final List<String> dates30;
  final List<double> tonnage30;
  final List<int> trips30;
  final List<String> productLabels;
  final List<double> productValues;
  final double inboundTonnage;
  final double outboundTonnage;
  final List<String> partyLabels;
  final List<double> partyValues;

  DashboardTrendModel({
    required this.dates30,
    required this.tonnage30,
    required this.trips30,
    required this.productLabels,
    required this.productValues,
    required this.inboundTonnage,
    required this.outboundTonnage,
    required this.partyLabels,
    required this.partyValues,
  });

  factory DashboardTrendModel.fromJson(Map<String, dynamic> json) {
    return DashboardTrendModel(
      dates30: (json['dates_30'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tonnage30: (json['tonnage_30'] as List?)?.map((e) => double.tryParse(e.toString()) ?? 0.0).toList() ?? [],
      trips30: (json['trips_30'] as List?)?.map((e) => int.tryParse(e.toString()) ?? 0).toList() ?? [],
      productLabels: (json['product_labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      productValues: (json['product_values'] as List?)?.map((e) => double.tryParse(e.toString()) ?? 0.0).toList() ?? [],
      inboundTonnage: double.tryParse(json['inbound_tonnage']?.toString() ?? '0') ?? 0.0,
      outboundTonnage: double.tryParse(json['outbound_tonnage']?.toString() ?? '0') ?? 0.0,
      partyLabels: (json['party_labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      partyValues: (json['party_values'] as List?)?.map((e) => double.tryParse(e.toString()) ?? 0.0).toList() ?? [],
    );
  }
}
