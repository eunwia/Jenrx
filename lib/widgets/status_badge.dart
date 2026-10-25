import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeVariant {
  success,
  warning,
  danger,
  info,
  neutral,
  custom,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeVariant variant;
  final Color? customColor;
  final Color? customTextColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = BadgeVariant.neutral,
    this.customColor,
    this.customTextColor,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (variant) {
      case BadgeVariant.success:
        bg = isDark ? AppColors.successDark : AppColors.successLight;
        fg = AppColors.success;
        break;
      case BadgeVariant.warning:
        bg = isDark ? AppColors.warningDark : AppColors.warningLight;
        fg = AppColors.warning;
        break;
      case BadgeVariant.danger:
        bg = isDark ? AppColors.dangerDark : AppColors.dangerLight;
        fg = AppColors.danger;
        break;
      case BadgeVariant.info:
        bg = isDark ? const Color(0xFF1B2A4A) : AppColors.primaryLight;
        fg = AppColors.primary;
        break;
      case BadgeVariant.neutral:
        bg = isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFECEFF3);
        fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        break;
      case BadgeVariant.custom:
        final c = customColor ?? AppColors.primary;
        bg = c.withValues(alpha: isDark ? 0.25 : 0.12);
        fg = customTextColor ?? c;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
