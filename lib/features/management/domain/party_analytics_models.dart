import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PartyScoreExplanation {
  final List<String> positivePoints;
  final List<String> attentionPoints;

  PartyScoreExplanation({
    required this.positivePoints,
    required this.attentionPoints,
  });

  factory PartyScoreExplanation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PartyScoreExplanation(positivePoints: [], attentionPoints: []);
    }
    return PartyScoreExplanation(
      positivePoints: (json['positive_points'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      attentionPoints: (json['attention_points'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class PartyRankingItem {
  final int rank;
  final double percentile;
  final int partyId;
  final String partyName;
  final String? partyCode;
  final String partyType;
  final String partyTypeFa;
  final double? overallScore;
  final String scoreLevel;
  final String scoreLevelFa;
  final String confidence;
  final String confidenceFa;
  final int completedTickets;
  final double totalTonnage;
  final double avgDiscrepancyKg;
  final double avgLossPercent;
  final double alertRate;
  final double avgTurnaroundMin;
  final double weightAccuracyScore;
  final double lossPerformanceScore;
  final double consistencyScore;
  final double monitoringQualityScore;
  final double operationalEfficiencyScore;
  final double dataReliabilityScore;
  final PartyScoreExplanation explanation;

  PartyRankingItem({
    required this.rank,
    required this.percentile,
    required this.partyId,
    required this.partyName,
    this.partyCode,
    required this.partyType,
    required this.partyTypeFa,
    this.overallScore,
    required this.scoreLevel,
    required this.scoreLevelFa,
    required this.confidence,
    required this.confidenceFa,
    required this.completedTickets,
    required this.totalTonnage,
    required this.avgDiscrepancyKg,
    required this.avgLossPercent,
    required this.alertRate,
    required this.avgTurnaroundMin,
    required this.weightAccuracyScore,
    required this.lossPerformanceScore,
    required this.consistencyScore,
    required this.monitoringQualityScore,
    required this.operationalEfficiencyScore,
    required this.dataReliabilityScore,
    required this.explanation,
  });

  factory PartyRankingItem.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return PartyRankingItem(
      rank: json['rank'] ?? 0,
      percentile: parseD(json['percentile']),
      partyId: json['party_id'] ?? 0,
      partyName: json['party_name'] ?? '',
      partyCode: json['party_code'],
      partyType: json['party_type'] ?? '',
      partyTypeFa: json['party_type_fa'] ?? '',
      overallScore: json['overall_score'] != null ? parseD(json['overall_score']) : null,
      scoreLevel: json['score_level'] ?? 'NEEDS_ATTENTION',
      scoreLevelFa: json['score_level_fa'] ?? 'نیازمند بررسی',
      confidence: json['confidence'] ?? 'INSUFFICIENT',
      confidenceFa: json['confidence_fa'] ?? 'داده ناکافی',
      completedTickets: json['completed_tickets'] ?? 0,
      totalTonnage: parseD(json['total_tonnage']),
      avgDiscrepancyKg: parseD(json['avg_discrepancy_kg']),
      avgLossPercent: parseD(json['avg_loss_percent']),
      alertRate: parseD(json['alert_rate']),
      avgTurnaroundMin: parseD(json['avg_turnaround_min']),
      weightAccuracyScore: parseD(json['weight_accuracy_score']),
      lossPerformanceScore: parseD(json['loss_performance_score']),
      consistencyScore: parseD(json['consistency_score']),
      monitoringQualityScore: parseD(json['monitoring_quality_score']),
      operationalEfficiencyScore: parseD(json['operational_efficiency_score']),
      dataReliabilityScore: parseD(json['data_reliability_score']),
      explanation: PartyScoreExplanation.fromJson(json['explanation']),
    );
  }

  Color get scoreColor {
    if (overallScore == null) return Colors.grey;
    if (overallScore! >= 90) return AppColors.success;
    if (overallScore! >= 75) return AppColors.primaryLight;
    if (overallScore! >= 60) return AppColors.secondary;
    if (overallScore! >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Color get confidenceColor {
    switch (confidence) {
      case 'VERY_HIGH':
      case 'HIGH':
        return AppColors.success;
      case 'MEDIUM':
        return AppColors.info;
      case 'LOW':
        return AppColors.warning;
      case 'INSUFFICIENT':
      default:
        return Colors.grey;
    }
  }
}

class PartyAnalyticsProfile {
  final int partyId;
  final String partyName;
  final String partyType;
  final String partyTypeDisplay;
  final int totalTickets;
  final int completedTickets;
  final int cancelledTickets;
  final double totalNetWeightKg;
  final double totalNetWeightTon;
  final double totalFinalWeightKg;
  final double totalFinalWeightTon;
  final double averageNetWeightKg;
  final double averageFinalWeightKg;
  final double minNetWeightKg;
  final double maxNetWeightKg;
  final String? firstTicketDate;
  final String firstTicketDateFa;
  final String? lastTicketDate;
  final String lastTicketDateFa;
  final int activeDays;

  PartyAnalyticsProfile({
    required this.partyId,
    required this.partyName,
    required this.partyType,
    required this.partyTypeDisplay,
    required this.totalTickets,
    required this.completedTickets,
    required this.cancelledTickets,
    required this.totalNetWeightKg,
    required this.totalNetWeightTon,
    required this.totalFinalWeightKg,
    required this.totalFinalWeightTon,
    required this.averageNetWeightKg,
    required this.averageFinalWeightKg,
    required this.minNetWeightKg,
    required this.maxNetWeightKg,
    this.firstTicketDate,
    required this.firstTicketDateFa,
    this.lastTicketDate,
    required this.lastTicketDateFa,
    required this.activeDays,
  });

  factory PartyAnalyticsProfile.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => (v == null) ? 0.0 : (v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0));
    return PartyAnalyticsProfile(
      partyId: json['party_id'] ?? 0,
      partyName: json['party_name'] ?? '',
      partyType: json['party_type'] ?? '',
      partyTypeDisplay: json['party_type_display'] ?? '',
      totalTickets: json['total_tickets'] ?? 0,
      completedTickets: json['completed_tickets'] ?? 0,
      cancelledTickets: json['cancelled_tickets'] ?? 0,
      totalNetWeightKg: parseD(json['total_net_weight_kg']),
      totalNetWeightTon: parseD(json['total_net_weight_ton']),
      totalFinalWeightKg: parseD(json['total_final_weight_kg']),
      totalFinalWeightTon: parseD(json['total_final_weight_ton']),
      averageNetWeightKg: parseD(json['average_net_weight_kg']),
      averageFinalWeightKg: parseD(json['average_final_weight_kg']),
      minNetWeightKg: parseD(json['min_net_weight_kg']),
      maxNetWeightKg: parseD(json['max_net_weight_kg']),
      firstTicketDate: json['first_ticket_date'],
      firstTicketDateFa: json['first_ticket_date_fa'] ?? '-',
      lastTicketDate: json['last_ticket_date'],
      lastTicketDateFa: json['last_ticket_date_fa'] ?? '-',
      activeDays: json['active_days'] ?? 0,
    );
  }
}

class PartyDiscrepancyMetrics {
  final double totalDiscrepancyKg;
  final double avgSignedDiscrepancyKg;
  final double avgAbsoluteDiscrepancyKg;
  final double medianAbsoluteDiscrepancyKg;
  final double maxAbsoluteDiscrepancyKg;
  final double avgDiscrepancyPercent;
  final double discrepancyStddev;
  final int ticketsWithDiscrepancy;
  final double discrepancyRate;
  final int ticketsWithSentWeight;
  final double missingSentWeightRate;

  PartyDiscrepancyMetrics({
    required this.totalDiscrepancyKg,
    required this.avgSignedDiscrepancyKg,
    required this.avgAbsoluteDiscrepancyKg,
    required this.medianAbsoluteDiscrepancyKg,
    required this.maxAbsoluteDiscrepancyKg,
    required this.avgDiscrepancyPercent,
    required this.discrepancyStddev,
    required this.ticketsWithDiscrepancy,
    required this.discrepancyRate,
    required this.ticketsWithSentWeight,
    required this.missingSentWeightRate,
  });

  factory PartyDiscrepancyMetrics.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => (v == null) ? 0.0 : (v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0));
    return PartyDiscrepancyMetrics(
      totalDiscrepancyKg: parseD(json['total_discrepancy_kg']),
      avgSignedDiscrepancyKg: parseD(json['average_signed_discrepancy_kg']),
      avgAbsoluteDiscrepancyKg: parseD(json['average_absolute_discrepancy_kg']),
      medianAbsoluteDiscrepancyKg: parseD(json['median_absolute_discrepancy_kg']),
      maxAbsoluteDiscrepancyKg: parseD(json['maximum_absolute_discrepancy_kg']),
      avgDiscrepancyPercent: parseD(json['average_discrepancy_percent']),
      discrepancyStddev: parseD(json['discrepancy_stddev']),
      ticketsWithDiscrepancy: json['tickets_with_discrepancy'] ?? 0,
      discrepancyRate: parseD(json['discrepancy_rate']),
      ticketsWithSentWeight: json['tickets_with_sent_weight'] ?? 0,
      missingSentWeightRate: parseD(json['missing_sent_weight_rate']),
    );
  }
}

class PartyLossMetrics {
  final double totalLossWeight;
  final double avgLossWeight;
  final double avgLossPercent;
  final double medianLossPercent;
  final double maxLossPercent;
  final double lossStddev;
  final int ticketsWithLoss;
  final double lossRate;

  PartyLossMetrics({
    required this.totalLossWeight,
    required this.avgLossWeight,
    required this.avgLossPercent,
    required this.medianLossPercent,
    required this.maxLossPercent,
    required this.lossStddev,
    required this.ticketsWithLoss,
    required this.lossRate,
  });

  factory PartyLossMetrics.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => (v == null) ? 0.0 : (v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0));
    return PartyLossMetrics(
      totalLossWeight: parseD(json['total_loss_weight']),
      avgLossWeight: parseD(json['average_loss_weight']),
      avgLossPercent: parseD(json['average_loss_percent']),
      medianLossPercent: parseD(json['median_loss_percent']),
      maxLossPercent: parseD(json['maximum_loss_percent']),
      lossStddev: parseD(json['loss_stddev']),
      ticketsWithLoss: json['tickets_with_loss'] ?? 0,
      lossRate: parseD(json['loss_rate']),
    );
  }
}

class PartyMonitoringMetrics {
  final int totalAlerts;
  final int openAlerts;
  final int reviewedAlerts;
  final int resolvedAlerts;
  final int ignoredAlerts;
  final int lowAlerts;
  final int mediumAlerts;
  final int highAlerts;
  final int criticalAlerts;
  final double alertsPer100Tickets;
  final Map<String, int> breakdownByType;

  PartyMonitoringMetrics({
    required this.totalAlerts,
    required this.openAlerts,
    required this.reviewedAlerts,
    required this.resolvedAlerts,
    required this.ignoredAlerts,
    required this.lowAlerts,
    required this.mediumAlerts,
    required this.highAlerts,
    required this.criticalAlerts,
    required this.alertsPer100Tickets,
    required this.breakdownByType,
  });

  factory PartyMonitoringMetrics.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => (v == null) ? 0.0 : (v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0));
    final types = <String, int>{};
    if (json['breakdown_by_type'] is Map) {
      (json['breakdown_by_type'] as Map).forEach((k, v) {
        types[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    return PartyMonitoringMetrics(
      totalAlerts: json['total_alerts'] ?? 0,
      openAlerts: json['open_alerts'] ?? 0,
      reviewedAlerts: json['reviewed_alerts'] ?? 0,
      resolvedAlerts: json['resolved_alerts'] ?? 0,
      ignoredAlerts: json['ignored_alerts'] ?? 0,
      lowAlerts: json['low_alerts'] ?? 0,
      mediumAlerts: json['medium_alerts'] ?? 0,
      highAlerts: json['high_alerts'] ?? 0,
      criticalAlerts: json['critical_alerts'] ?? 0,
      alertsPer100Tickets: parseD(json['alerts_per_100_tickets']),
      breakdownByType: types,
    );
  }
}

class PartyTurnaroundMetrics {
  final double avgTurnaroundMinutes;
  final double medianTurnaroundMinutes;
  final double maxTurnaroundMinutes;
  final double turnaroundStddev;
  final int longWaitingTicketCount;
  final double longWaitingRate;

  PartyTurnaroundMetrics({
    required this.avgTurnaroundMinutes,
    required this.medianTurnaroundMinutes,
    required this.maxTurnaroundMinutes,
    required this.turnaroundStddev,
    required this.longWaitingTicketCount,
    required this.longWaitingRate,
  });

  factory PartyTurnaroundMetrics.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => (v == null) ? 0.0 : (v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0));
    return PartyTurnaroundMetrics(
      avgTurnaroundMinutes: parseD(json['average_turnaround_minutes']),
      medianTurnaroundMinutes: parseD(json['median_turnaround_minutes']),
      maxTurnaroundMinutes: parseD(json['max_turnaround_minutes']),
      turnaroundStddev: parseD(json['turnaround_stddev']),
      longWaitingTicketCount: json['long_waiting_ticket_count'] ?? 0,
      longWaitingRate: parseD(json['long_waiting_rate']),
    );
  }
}

class PartyCorrectionMetrics {
  final int weightCorrectionCount;
  final int lossOverrideCount;
  final int cancelCount;
  final int ticketsWithCorrection;
  final double correctionRate;

  PartyCorrectionMetrics({
    required this.weightCorrectionCount,
    required this.lossOverrideCount,
    required this.cancelCount,
    required this.ticketsWithCorrection,
    required this.correctionRate,
  });

  factory PartyCorrectionMetrics.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => (v == null) ? 0.0 : (v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0));
    return PartyCorrectionMetrics(
      weightCorrectionCount: json['weight_correction_count'] ?? 0,
      lossOverrideCount: json['loss_override_count'] ?? 0,
      cancelCount: json['cancel_count'] ?? 0,
      ticketsWithCorrection: json['tickets_with_correction'] ?? 0,
      correctionRate: parseD(json['correction_rate']),
    );
  }
}

class PartyConsistencyMetrics {
  final bool isSufficientSample;
  final double? weightStddev;
  final double? weightVariationCoef;
  final double? lossStddev;
  final double? lossVariationCoef;

  PartyConsistencyMetrics({
    required this.isSufficientSample,
    this.weightStddev,
    this.weightVariationCoef,
    this.lossStddev,
    this.lossVariationCoef,
  });

  factory PartyConsistencyMetrics.fromJson(Map<String, dynamic> json) {
    double? parseD(dynamic v) => (v == null) ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    return PartyConsistencyMetrics(
      isSufficientSample: json['is_sufficient_sample'] ?? false,
      weightStddev: parseD(json['weight_stddev']),
      weightVariationCoef: parseD(json['weight_variation_coef']),
      lossStddev: parseD(json['loss_stddev']),
      lossVariationCoef: parseD(json['loss_variation_coef']),
    );
  }
}

class PartyScoreBreakdown {
  final double? overallScore;
  final double rawScore;
  final String level;
  final String levelFa;
  final String confidence;
  final String confidenceFa;
  final bool isScoreReliable;
  final Map<String, double> dimensionScores;
  final Map<String, double> dimensionWeights;
  final String calculationVersion;
  final PartyScoreExplanation explanation;

  PartyScoreBreakdown({
    this.overallScore,
    required this.rawScore,
    required this.level,
    required this.levelFa,
    required this.confidence,
    required this.confidenceFa,
    required this.isScoreReliable,
    required this.dimensionScores,
    required this.dimensionWeights,
    required this.calculationVersion,
    required this.explanation,
  });

  factory PartyScoreBreakdown.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => (v == null) ? 0.0 : (v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0));
    
    final dims = <String, double>{};
    if (json['dimension_scores'] is Map) {
      (json['dimension_scores'] as Map).forEach((k, v) {
        dims[k.toString()] = parseD(v);
      });
    }

    final weights = <String, double>{};
    if (json['dimension_weights'] is Map) {
      (json['dimension_weights'] as Map).forEach((k, v) {
        weights[k.toString()] = parseD(v);
      });
    }

    return PartyScoreBreakdown(
      overallScore: json['overall_score'] != null ? parseD(json['overall_score']) : null,
      rawScore: parseD(json['raw_score']),
      level: json['level'] ?? 'NEEDS_ATTENTION',
      levelFa: json['level_fa'] ?? 'نیازمند بررسی',
      confidence: json['confidence'] ?? 'INSUFFICIENT',
      confidenceFa: json['confidence_fa'] ?? 'داده ناکافی',
      isScoreReliable: json['is_score_reliable'] ?? false,
      dimensionScores: dims,
      dimensionWeights: weights,
      calculationVersion: json['calculation_version'] ?? 'party_score_v1',
      explanation: PartyScoreExplanation.fromJson(json['explanation']),
    );
  }

  Color get scoreColor {
    if (overallScore == null) return Colors.grey;
    if (overallScore! >= 90) return AppColors.success;
    if (overallScore! >= 75) return AppColors.primaryLight;
    if (overallScore! >= 60) return AppColors.secondary;
    if (overallScore! >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

class PartyDetailAnalytics {
  final Map<String, dynamic> party;
  final PartyAnalyticsProfile profile;
  final PartyDiscrepancyMetrics discrepancyMetrics;
  final PartyLossMetrics lossMetrics;
  final PartyMonitoringMetrics monitoringMetrics;
  final PartyTurnaroundMetrics turnaroundMetrics;
  final PartyCorrectionMetrics correctionMetrics;
  final PartyConsistencyMetrics consistencyMetrics;
  final PartyScoreBreakdown score;

  PartyDetailAnalytics({
    required this.party,
    required this.profile,
    required this.discrepancyMetrics,
    required this.lossMetrics,
    required this.monitoringMetrics,
    required this.turnaroundMetrics,
    required this.correctionMetrics,
    required this.consistencyMetrics,
    required this.score,
  });

  factory PartyDetailAnalytics.fromJson(Map<String, dynamic> json) {
    return PartyDetailAnalytics(
      party: json['party'] is Map<String, dynamic> ? json['party'] : {},
      profile: PartyAnalyticsProfile.fromJson(json['profile'] ?? {}),
      discrepancyMetrics: PartyDiscrepancyMetrics.fromJson(json['discrepancy_metrics'] ?? {}),
      lossMetrics: PartyLossMetrics.fromJson(json['loss_metrics'] ?? {}),
      monitoringMetrics: PartyMonitoringMetrics.fromJson(json['monitoring_metrics'] ?? {}),
      turnaroundMetrics: PartyTurnaroundMetrics.fromJson(json['turnaround_metrics'] ?? {}),
      correctionMetrics: PartyCorrectionMetrics.fromJson(json['correction_metrics'] ?? {}),
      consistencyMetrics: PartyConsistencyMetrics.fromJson(json['consistency_metrics'] ?? {}),
      score: PartyScoreBreakdown.fromJson(json['score'] ?? {}),
    );
  }
}

class MetricComparisonModel {
  final double? current;
  final double? previous;
  final double? deltaAbs;
  final double? deltaPercent;
  final String direction;

  MetricComparisonModel({
    this.current,
    this.previous,
    this.deltaAbs,
    this.deltaPercent,
    required this.direction,
  });

  factory MetricComparisonModel.fromJson(Map<String, dynamic> json) {
    double? parseD(dynamic v) => (v == null) ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    return MetricComparisonModel(
      current: parseD(json['current']),
      previous: parseD(json['previous']),
      deltaAbs: parseD(json['delta_abs']),
      deltaPercent: parseD(json['delta_percent']),
      direction: json['direction'] ?? 'INSUFFICIENT_DATA',
    );
  }

  Color get directionColor {
    switch (direction) {
      case 'IMPROVING':
        return AppColors.success;
      case 'WORSENING':
        return AppColors.error;
      case 'STABLE':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  IconData get directionIcon {
    switch (direction) {
      case 'IMPROVING':
        return Icons.trending_up;
      case 'WORSENING':
        return Icons.trending_down;
      case 'STABLE':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }
}

class PartyTrendModel {
  final Map<String, dynamic> period;
  final Map<String, MetricComparisonModel> kpiComparison;
  final PartyDetailAnalytics currentAnalysis;
  final PartyDetailAnalytics previousAnalysis;

  PartyTrendModel({
    required this.period,
    required this.kpiComparison,
    required this.currentAnalysis,
    required this.previousAnalysis,
  });

  factory PartyTrendModel.fromJson(Map<String, dynamic> json) {
    final kpis = <String, MetricComparisonModel>{};
    if (json['kpi_comparison'] is Map) {
      (json['kpi_comparison'] as Map).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          kpis[k.toString()] = MetricComparisonModel.fromJson(v);
        }
      });
    }

    return PartyTrendModel(
      period: json['period'] is Map<String, dynamic> ? json['period'] : {},
      kpiComparison: kpis,
      currentAnalysis: PartyDetailAnalytics.fromJson(json['current_analysis'] ?? {}),
      previousAnalysis: PartyDetailAnalytics.fromJson(json['previous_analysis'] ?? {}),
    );
  }
}

class PartyComparisonItem {
  final int partyId;
  final String partyName;
  final String partyType;
  final String partyTypeFa;
  final PartyScoreBreakdown score;
  final Map<String, dynamic> volume;
  final Map<String, dynamic> discrepancy;
  final Map<String, dynamic> loss;
  final Map<String, dynamic> monitoring;
  final Map<String, dynamic> turnaround;

  PartyComparisonItem({
    required this.partyId,
    required this.partyName,
    required this.partyType,
    required this.partyTypeFa,
    required this.score,
    required this.volume,
    required this.discrepancy,
    required this.loss,
    required this.monitoring,
    required this.turnaround,
  });

  factory PartyComparisonItem.fromJson(Map<String, dynamic> json) {
    return PartyComparisonItem(
      partyId: json['party_id'] ?? 0,
      partyName: json['party_name'] ?? '',
      partyType: json['party_type'] ?? '',
      partyTypeFa: json['party_type_fa'] ?? '',
      score: PartyScoreBreakdown.fromJson(json['score'] ?? {}),
      volume: json['volume'] is Map<String, dynamic> ? json['volume'] : {},
      discrepancy: json['discrepancy'] is Map<String, dynamic> ? json['discrepancy'] : {},
      loss: json['loss'] is Map<String, dynamic> ? json['loss'] : {},
      monitoring: json['monitoring'] is Map<String, dynamic> ? json['monitoring'] : {},
      turnaround: json['turnaround'] is Map<String, dynamic> ? json['turnaround'] : {},
    );
  }
}

class PartyComparisonModel {
  final int partiesCount;
  final String productContext;
  final List<PartyComparisonItem> comparison;

  PartyComparisonModel({
    required this.partiesCount,
    required this.productContext,
    required this.comparison,
  });

  factory PartyComparisonModel.fromJson(Map<String, dynamic> json) {
    final list = (json['comparison'] as List<dynamic>?)
            ?.map((e) => PartyComparisonItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PartyComparisonModel(
      partiesCount: json['parties_count'] ?? list.length,
      productContext: json['product_context'] ?? 'همه کالاها',
      comparison: list,
    );
  }
}
