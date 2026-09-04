import 'package:flutter/material.dart';
import '../models/level.dart';

/// レベルアップ通知ウィジェット（アニメーション付き）
class LevelUpNotification extends StatefulWidget {
  final LevelUpEvent levelUpEvent;
  final VoidCallback? onDismiss;

  const LevelUpNotification({
    super.key,
    required this.levelUpEvent,
    this.onDismiss,
  });

  @override
  State<LevelUpNotification> createState() => _LevelUpNotificationState();
}

class _LevelUpNotificationState extends State<LevelUpNotification>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _scaleController.forward();
    _slideController.forward();

    // 3秒後に自動で閉じる
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _scaleController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.levelUpEvent;
    final level = event.levelData;
    final color = _getLevelColor(level.tier);

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  level.emoji,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'LEVEL UP!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Level ${event.oldLevel} → Level ${event.newLevel}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                level.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),

              // 報酬情報
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Rewards',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // コイン報酬
                        Column(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: Colors.amber[700],
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${event.coinsReward}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                            Text(
                              'Coins',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),

                        // XP報酬
                        Column(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.blue[700],
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${event.xpBonus}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            Text(
                              'XP',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
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

  Color _getLevelColor(LevelTier tier) {
    return switch (tier) {
      LevelTier.beginner => Colors.green,
      LevelTier.intermediate => Colors.blue,
      LevelTier.advanced => Colors.orange,
      LevelTier.expert => Colors.red,
    };
  }
}

/// レベルアップバナー（スナックバー等で使用）
class LevelUpBanner extends StatelessWidget {
  final LevelUpEvent levelUpEvent;
  final VoidCallback? onDismiss;

  const LevelUpBanner({
    super.key,
    required this.levelUpEvent,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final level = levelUpEvent.levelData;
    final color = _getLevelColor(level.tier);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                level.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level Up!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'You reached Level ${levelUpEvent.newLevel}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '+${levelUpEvent.coinsReward} Coins',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '+${levelUpEvent.xpBonus} XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(LevelTier tier) {
    return switch (tier) {
      LevelTier.beginner => Colors.green,
      LevelTier.intermediate => Colors.blue,
      LevelTier.advanced => Colors.orange,
      LevelTier.expert => Colors.red,
    };
  }
}
