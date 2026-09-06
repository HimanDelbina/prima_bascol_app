class ReportSummaryModel {
  final int totalTickets;
  final double totalGrossWeight;
  final double totalTareWeight;
  final double totalNetWeight;
  final double totalSentWeight;
  final double totalWeightDifference;
  final double totalLossWeight;
  final double totalFinalWeight;

  ReportSummaryModel({
    required this.totalTickets,
    required this.totalGrossWeight,
    required this.totalTareWeight,
    required this.totalNetWeight,
    required this.totalSentWeight,
    required this.totalWeightDifference,
    required this.totalLossWeight,
    required this.totalFinalWeight,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    double parseVal(dynamic v1, dynamic v2, [dynamic v3]) {
      final val = v1 ?? v2 ?? v3;
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final totalT = json['total_tickets'] ?? json['total_loads'] ?? json['tickets_count'] ?? 0;

    return ReportSummaryModel(
      totalTickets: totalT is int ? totalT : int.tryParse(totalT.toString()) ?? 0,
      totalGrossWeight: parseVal(json['sum_gross'], json['total_gross_weight'], json['gross_weight']),
      totalTareWeight: parseVal(json['sum_tare'], json['total_tare_weight'], json['tare_weight']),
      totalNetWeight: parseVal(json['sum_net'], json['total_net_weight'], json['net_weight']),
      totalSentWeight: parseVal(json['sum_sent'], json['total_sent_weight'], json['sent_weight']),
      totalWeightDifference: parseVal(json['sum_weight_difference'], json['total_weight_difference'], json['weight_difference']),
      totalLossWeight: parseVal(json['sum_loss'], json['total_loss_weight'], json['loss_weight']),
      totalFinalWeight: parseVal(json['sum_final'], json['total_final_weight'], json['final_weight']),
    );
  }
}

class GroupedReportItem {
  final String groupKey;
  final String groupTitle;
  final int count;
  final double totalNetWeight;
  final double totalGrossWeight;
  final double totalFinalWeight;
  final double totalLossWeight;
  final double averageNetWeight;

  GroupedReportItem({
    required this.groupKey,
    required this.groupTitle,
    required this.count,
    required this.totalNetWeight,
    this.totalGrossWeight = 0.0,
    required this.totalFinalWeight,
    required this.totalLossWeight,
    required this.averageNetWeight,
  });

  factory GroupedReportItem.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> json = {};
    if (rawJson['item'] is Map<String, dynamic>) {
      json.addAll(rawJson['item'] as Map<String, dynamic>);
    }
    json.addAll(rawJson);

    double parseValFromKeys(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) {
          final val = json[k];
          double? parsed;
          if (val is num) {
            parsed = val.toDouble();
          } else {
            parsed = double.tryParse(val.toString());
          }
          if (parsed != null && parsed > 0.0) {
            return parsed;
          }
        }
      }
      return 0.0;
    }

    final rawCount = json['count'] ??
        json['total_tickets'] ??
        json['tickets_count'] ??
        json['total_loads'] ??
        json['loads_count'] ??
        json['services_count'] ??
        0;
    final count = rawCount is int ? rawCount : int.tryParse(rawCount.toString()) ?? 0;

    // Search net weight or tonnage
    double net = parseValFromKeys([
      'sum_net',
      'total_net_weight',
      'net_weight',
      'total_net',
      'net',
      'tonnage',
      'total_tonnage',
      'sum_tonnage',
      'total_weight',
      'sum_weight',
      'weight',
      'total',
    ]);

    // Search gross weight / first weight
    double gross = parseValFromKeys([
      'sum_gross',
      'total_gross_weight',
      'gross_weight',
      'total_gross',
      'gross',
      'first_weight',
      'sum_first_weight',
      'total_first_weight',
      'second_weight',
      'sum_second_weight',
    ]);

    // Fallback: if net is 0, check if any numerical property holds a non-zero value
    if (net == 0.0) {
      for (final entry in json.entries) {
        final key = entry.key.toLowerCase();
        if (key == 'id' ||
            key == 'count' ||
            key.contains('id') ||
            key.contains('name') ||
            key.contains('title') ||
            key.contains('key') ||
            key.contains('code')) {
          continue;
        }
        final val = entry.value;
        if (val is num && val > 0) {
          net = val.toDouble();
          break;
        } else if (val is String) {
          final parsed = double.tryParse(val);
          if (parsed != null && parsed > 0) {
            net = parsed;
            break;
          }
        }
      }
    }

    final finalW = parseValFromKeys([
      'sum_final',
      'total_final_weight',
      'final_weight',
      'total_final',
    ]);

    final lossW = parseValFromKeys([
      'sum_loss',
      'total_loss_weight',
      'loss_weight',
      'loss',
      'total_loss',
    ]);

    final avgNet = parseValFromKeys([
      'avg_net',
      'average_net_weight',
      'avg_weight',
      'average_weight',
    ]);

    final title = json['group_title']?.toString() ??
        json['name']?.toString() ??
        json['product_name']?.toString() ??
        json['product__name']?.toString() ??
        json['party_name']?.toString() ??
        json['party__name']?.toString() ??
        json['driver_name']?.toString() ??
        json['driver__name']?.toString() ??
        json['vehicle_plate']?.toString() ??
        json['vehicle__plate']?.toString() ??
        json['title']?.toString() ??
        json['label']?.toString() ??
        'نامشخص';

    return GroupedReportItem(
      groupKey: json['group_key']?.toString() ??
          json['product__id']?.toString() ??
          json['party__id']?.toString() ??
          json['driver__id']?.toString() ??
          json['vehicle__id']?.toString() ??
          json['id']?.toString() ??
          json['key']?.toString() ??
          '',
      groupTitle: title,
      count: count,
      totalNetWeight: net,
      totalGrossWeight: gross > 0 ? gross : net,
      totalFinalWeight: finalW > 0 ? finalW : (net > 0 ? net : gross),
      totalLossWeight: lossW,
      averageNetWeight: avgNet > 0 ? avgNet : (count > 0 ? ((net > 0 ? net : gross) / count) : 0.0),
    );
  }
}
