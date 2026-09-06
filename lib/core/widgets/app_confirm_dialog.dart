import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final bool isDestructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = "تایید",
    this.cancelText = "انصراف",
    this.confirmColor = const Color(0xFF1E3A8A),
    this.isDestructive = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = "تایید",
    String cancelText = "انصراف",
    bool isDestructive = false,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: isDestructive ? Colors.red : const Color(0xFF1E3A8A),
        isDestructive: isDestructive,
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      title: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
