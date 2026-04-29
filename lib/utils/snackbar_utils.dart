import 'package:dextera/core/app_theme.dart';
import 'package:dextera/utils/error_handler.dart';
import 'package:flutter/material.dart';

enum SnackBarType { success, warning, error, info, suggestion }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final Color color;
    final IconData iconData;

    switch (type) {
      case SnackBarType.success:
        color = ThemeHelper.successColor;
        iconData = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        color = ThemeHelper.errorColor;
        iconData = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        color = ThemeHelper.warningColor;
        iconData = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        color = ThemeHelper.infoColor;
        iconData = Icons.info_rounded;
        break;
      case SnackBarType.suggestion:
        color = ThemeHelper.tertiaryColor;
        iconData = Icons.tips_and_updates_rounded;
        break;
    }

    final isDark = ThemeHelper.isDarkMode;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? _getDefaultTitle(type),
                      style: TextStyle(
                        color: ThemeHelper.buttonTextClr,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: "Manrope",
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        color: ThemeHelper.buttonTextClr,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: "Manrope",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showError(
    BuildContext context, {
    required dynamic error,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = ErrorHandler.parse(error);
    show(
      context,
      message: message,
      type: SnackBarType.error,
      title: title,
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.success,
      title: title,
      duration: duration,
    );
  }

  static String _getDefaultTitle(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return "Success";
      case SnackBarType.error:
        return "Error";
      case SnackBarType.warning:
        return "Warning";
      case SnackBarType.info:
        return "Information";
      case SnackBarType.suggestion:
        return "Suggestion";
    }
  }
}
