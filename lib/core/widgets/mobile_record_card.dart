import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'app_card.dart';

class MobileRecordCard extends StatelessWidget {
  final String title;
  final Widget? badge;
  final List<Widget> rows;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  const MobileRecordCard({
    super.key,
    required this.title,
    this.badge,
    required this.rows,
    this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: AppCard(
        padding: const EdgeInsets.all(AppDimensions.md),
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (badge != null) badge!,
              ],
            ),
            const Divider(height: 16),
            ...rows,
            if (actions != null && actions!.isNotEmpty) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
