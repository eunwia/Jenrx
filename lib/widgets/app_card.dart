import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Border? border;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final defaultBorderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final r = borderRadius ?? BorderRadius.circular(18);

    final container = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: r,
        border: border ?? Border.all(color: defaultBorderColor, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: r,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );

    return container;
  }
}

class InsetGroupedSection extends StatelessWidget {
  final String? title;
  final String? footnote;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const InsetGroupedSection({
    super.key,
    this.title,
    this.footnote,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final defaultBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: headerColor,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: defaultBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: children.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: dividerColor.withValues(alpha: 0.6),
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) => children[index],
              ),
            ),
          ),
          if (footnote != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Text(
                footnote!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
