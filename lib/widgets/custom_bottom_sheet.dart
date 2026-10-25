import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry contentPadding;

  const CustomBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final handleColor = isDark ? Colors.white24 : Colors.black12;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4.5,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: contentPadding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
