import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppEmptyState extends StatelessWidget {
  final String? title;
  final String? description;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? action;
  final IconData icon;

  const AppEmptyState({
    super.key,
    this.title,
    this.description,
    this.message,
    this.actionText,
    this.onAction,
    this.action,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTitle = title ?? message ?? 'موردی یافت نشد';
    final displayDesc = description;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.textMutedLight),
            ),
            const SizedBox(height: 16),
            Text(
              displayTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (displayDesc != null && displayDesc.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  displayDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ] else if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
