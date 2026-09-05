import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/character_model.dart';
import '../providers/character_provider.dart';

/// クイズ回答直後に表示する、キャラクターのふきだし反応。
/// 正解/不正解どちらでも、責めずに親しみやすいトーンで話しかける。
class CharacterReactionBubble extends ConsumerWidget {
  final bool isCorrect;
  final String message;
  final String? growthMessage; // キャラクター成長メッセージ（正解時のみ）

  const CharacterReactionBubble({
    super.key,
    required this.isCorrect,
    required this.message,
    this.growthMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charState = ref.watch(characterProvider);
    final character = charState.character;
    if (character == null) return const SizedBox.shrink();

    final def = kAvailableCharacters.firstWhere(
      (c) => c.id == character.characterId,
      orElse: () => kAvailableCharacters.first,
    );
    final emoji = def.stageEmojis[character.stage] ?? '🐱';
    final imagePath = def.stageImages[character.stage];
    final bubbleColor = isCorrect ? kPrimaryColor : const Color(0xFFFF9800);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imagePath != null
            ? Image.asset(
                imagePath,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) =>
                    Text(emoji, style: const TextStyle(fontSize: 32)),
              )
            : Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bubbleColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (growthMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    growthMessage!,
                    style: TextStyle(
                      fontSize: 11,
                      color: bubbleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms).slideX(begin: -0.05, curve: Curves.easeOut);
  }
}
