import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class RiskBadge extends StatelessWidget {
  final int riskScore;
  final String riskLevel;

  const RiskBadge({
    super.key,
    required this.riskScore,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (riskLevel.toLowerCase()) {
      case 'critical':
        color = AppColors.riskCritical;
        label = 'بحرانی';
        break;
      case 'high':
        color = AppColors.riskHigh;
        label = 'بالا';
        break;
      case 'medium':
        color = AppColors.riskMedium;
        label = 'متوسط';
        break;
      case 'low':
      default:
        color = AppColors.riskLow;
        label = 'کم';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              '$label ($riskScore)',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
