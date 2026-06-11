import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';

/// Premium styled toast notifications to replace raw SnackBars.
///
/// Usage:
///   AppToast.success(context, 'Rates updated successfully');
///   AppToast.error(context, 'Failed to save');
///   AppToast.info(context, 'Syncing data...');
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) {
    _show(context, message, _ToastType.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, _ToastType.error);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, _ToastType.info);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, _ToastType.warning);
  }

  static void _show(BuildContext context, String message, _ToastType type) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final config = _getConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _ToastContent(
          message: message,
          icon: config.icon,
          iconColor: config.color,
          borderColor: config.color,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: Duration(
          milliseconds: type == _ToastType.error ? 4000 : 3000,
        ),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static _ToastConfig _getConfig(_ToastType type) {
    switch (type) {
      case _ToastType.success:
        return _ToastConfig(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
      case _ToastType.error:
        return _ToastConfig(icon: Icons.error_rounded, color: AppColors.error);
      case _ToastType.info:
        return _ToastConfig(icon: Icons.info_rounded, color: AppColors.info);
      case _ToastType.warning:
        return _ToastConfig(
          icon: Icons.warning_rounded,
          color: AppColors.warning,
        );
    }
  }
}

enum _ToastType { success, error, info, warning }

class _ToastConfig {
  final IconData icon;
  final Color color;
  const _ToastConfig({required this.icon, required this.color});
}

class _ToastContent extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  const _ToastContent({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A28) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: isDark ? 0.15 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.text1(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.text3(context),
            ),
          ),
        ],
      ),
    );
  }
}
