import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 汎用スタンダード Card ウィジェット
/// 統一されたスタイルで Card を表示
class StandardCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets padding;
  final double borderRadius;
  final void Function()? onTap;
  final bool showShadow;

  const StandardCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 14,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor ?? context.cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null
          ? Border.all(color: borderColor!.withValues(alpha: 0.3), width: 1)
          : null,
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );

    final card = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// アイコン付き Card
class IconCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final void Function()? onTap;
  final double iconSize;

  const IconCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(iconSize / 4),
                ),
                child: Icon(icon, color: iconColor, size: iconSize * 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleMedium!,
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!,
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// バッジ表示用 Card
class BadgeCard extends StatelessWidget {
  final String badgeText;
  final IconData badgeIcon;
  final Color badgeColor;
  final Widget content;
  final void Function()? onTap;

  const BadgeCard({
    super.key,
    required this.badgeText,
    required this.badgeIcon,
    required this.badgeColor,
    required this.content,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      borderColor: badgeColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
