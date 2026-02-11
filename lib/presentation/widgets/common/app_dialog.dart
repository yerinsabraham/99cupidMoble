import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Reusable confirmation dialog that works in both light and dark modes
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final bool isDestructive;
  final Widget? contentWidget;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.isDestructive = false,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.deepPlum,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: contentWidget ?? Text(
        content,
        style: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.87) : AppColors.grey700,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : AppColors.grey600,
          ),
          child: Text(cancelText ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive 
                ? (isDark ? Colors.red[300] : Colors.red[700])
                : (isDark ? AppColors.cupidPink.withOpacity(0.9) : AppColors.cupidPink),
          ),
          child: Text(confirmText ?? 'Confirm'),
        ),
      ],
    );
  }
}

/// Reusable info dialog that works in both light and dark modes
class AppInfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? buttonText;
  final IconData? icon;
  final Color? iconColor;
  final Widget? contentWidget;

  const AppInfoDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText,
    this.icon,
    this.iconColor,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: icon != null
          ? Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? (isDark ? AppColors.cupidPink.withOpacity(0.9) : AppColors.cupidPink),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.deepPlum,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.deepPlum,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
      content: contentWidget ?? Text(
        content,
        style: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.87) : AppColors.grey700,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.cupidPink.withOpacity(0.9) : AppColors.cupidPink,
          ),
          child: Text(buttonText ?? 'OK'),
        ),
      ],
    );
  }
}

/// Show a confirmation dialog
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
  Widget? contentWidget,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AppConfirmDialog(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      contentWidget: contentWidget,
    ),
  );
  return result ?? false;
}

/// Show an info dialog
Future<void> showAppInfoDialog(
  BuildContext context, {
  required String title,
  required String content,
  String? buttonText,
  IconData? icon,
  Color? iconColor,
  Widget? contentWidget,
}) async {
  await showDialog(
    context: context,
    builder: (context) => AppInfoDialog(
      title: title,
      content: content,
      buttonText: buttonText,
      icon: icon,
      iconColor: iconColor,
      contentWidget: contentWidget,
    ),
  );
}
