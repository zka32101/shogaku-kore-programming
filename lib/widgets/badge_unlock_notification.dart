import 'package:flutter/material.dart';
import '../providers/badge_provider.dart';

/// バッジアンロック通知ウィジェット
/// 新しくアンロックされたバッジを表示する
class BadgeUnlockNotification extends StatefulWidget {
  final BadgeProgressInfo badgeInfo;
  final VoidCallback? onDismiss;
  final Duration displayDuration;

  const BadgeUnlockNotification({
    super.key,
    required this.badgeInfo,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
  });

  @override
  State<BadgeUnlockNotification> createState() =>
      _BadgeUnlockNotificationState();
}

class _BadgeUnlockNotificationState extends State<BadgeUnlockNotification>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController.forward();
    _slideController.forward();

    // 自動消滅タイマー
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _animateOut();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _animateOut() {
    _scaleController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badgeInfo.badge;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
        ),
        child: GestureDetector(
          onTap: _animateOut,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 大きなバッジアイコン
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Text(
                        badge.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // テキスト
                Text(
                  'バッジアンロック！',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  badge.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  badge.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // タップして閉じる表示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'タップして閉じる',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// バッジアンロック通知を表示するヘルパー関数
void showBadgeUnlockNotification(
  BuildContext context,
  BadgeProgressInfo badgeInfo, {
  Duration displayDuration = const Duration(seconds: 4),
}) {
  OverlayEntry? overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: BadgeUnlockNotification(
          badgeInfo: badgeInfo,
          displayDuration: displayDuration,
          onDismiss: () {
            overlayEntry?.remove();
          },
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}

/// 複数バッジのアンロック通知を順序よく表示
void showMultipleBadgeUnlockNotifications(
  BuildContext context,
  List<BadgeProgressInfo> badges, {
  Duration displayDuration = const Duration(seconds: 3),
  Duration delayBetween = const Duration(milliseconds: 800),
}) {
  for (int i = 0; i < badges.length; i++) {
    Future.delayed(Duration(milliseconds: delayBetween.inMilliseconds * i),
        () {
      if (context.mounted) {
        showBadgeUnlockNotification(
          context,
          badges[i],
          displayDuration: displayDuration,
        );
      }
    });
  }
}
