import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class StatusBadge extends StatelessWidget {
  final String code;
  final String label;

  const StatusBadge({
    super.key,
    required this.code,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (code.toLowerCase()) {
      case 'draft':
        bg = AppColors.statusDraft.withOpacity(0.12);
        fg = AppColors.statusDraft;
        icon = Icons.edit_note_rounded;
        break;
      case 'waiting_first':
        bg = AppColors.statusWaitingFirst.withOpacity(0.12);
        fg = AppColors.statusWaitingFirst;
        icon = Icons.hourglass_top_rounded;
        break;
      case 'first_registered':
      case 'waiting_second':
        bg = AppColors.statusWaitingSecond.withOpacity(0.12);
        fg = AppColors.statusWaitingSecond;
        icon = Icons.sync_rounded;
        break;
      case 'completed':
        bg = AppColors.statusCompleted.withOpacity(0.12);
        fg = AppColors.statusCompleted;
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        bg = AppColors.statusCancelled.withOpacity(0.12);
        fg = AppColors.statusCancelled;
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey.shade700;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: fg.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
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
