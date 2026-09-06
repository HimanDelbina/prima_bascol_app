import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'app_card.dart';

class WeightCard extends StatelessWidget {
  final String title;
  final String weightFormatted;
  final String? subtitle;
  final Color color;
  final bool isLarge;

  const WeightCard({
    super.key,
    required this.title,
    required this.weightFormatted,
    this.subtitle,
    this.color = const Color(0xFF1E3A8A),
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: isLarge ? 10 : 8,
      ),
      border: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.scale_rounded, size: isLarge ? 20 : 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              weightFormatted,
              style: (isLarge ? theme.textTheme.headlineSmall : theme.textTheme.titleMedium)?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
