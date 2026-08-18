import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/character_model.dart';
import '../providers/character_provider.dart';

/// 育成中キャラクターの「気持ち」。エディタ・クイズ画面で状況に応じて切り替える。
enum CharacterMood { idle, thinking, excited, celebrating, encouraging }

/// 育成中のキャラクターが状況に応じてリアクションする小さなウィジェット。
///
/// [mood] や [message] が変わるたびに新しいアニメーションで再登場する。
/// キャラクター未読み込み時は何も表示しない（レイアウトを崩さないよう SizedBox.shrink）。
class CharacterReactionWidget extends ConsumerWidget {
  final CharacterMood mood;
  final String? message;

  const CharacterReactionWidget({
    super.key,
    this.mood = CharacterMood.idle,
    this.message,
  });

  String get _badgeEmoji => switch (mood) {
        CharacterMood.thinking => '🤔',
        CharacterMood.excited => '👀',
        CharacterMood.celebrating => '🎉',
        CharacterMood.encouraging => '💪',
        CharacterMood.idle => '',
      };

  Color get _accentColor => switch (mood) {
        CharacterMood.celebrating => const Color(0xFF1ABC9C),
        CharacterMood.encouraging => const Color(0xFFE67E22),
        CharacterMood.excited => const Color(0xFF3498DB),
        _ => const Color(0xFF8E44AD),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charState = ref.watch(characterProvider);
    final character = charState.character;
    if (character == null) return const SizedBox.shrink();

    final charDef = kAvailableCharacters.firstWhere(
      (c) => c.id == character.characterId,
      orElse: () => kAvailableCharacters.first,
    );
    final baseEmoji = charDef.stageEmojis[character.stage] ?? '🥚';
    // mood/message が変わるたびに違うキーになり、アニメーションが再生される
    final reactionKey = '${mood.name}_${message ?? ''}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: _accentColor.withValues(alpha: 0.4)),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Text(baseEmoji, style: const TextStyle(fontSize: 18)),
              if (_badgeEmoji.isNotEmpty)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Text(_badgeEmoji, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
        )
            .animate(key: ValueKey('char_$reactionKey'))
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.0, 1.0),
              curve: Curves.elasticOut,
              duration: 450.ms,
            ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                message!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _accentColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
              .animate(key: ValueKey('bubble_$reactionKey'))
              .fadeIn(duration: 220.ms)
              .slideX(begin: -0.08, curve: Curves.easeOut, duration: 220.ms),
        ],
      ],
    );
  }
}

/// キャラクターのひとことメッセージの候補（正解・不正解時にランダム選択）。
const kCelebrationMessages = [
  'やったね！すごい！',
  'ぴったり正解！',
  'その調子だよ！',
  'かんぺき！',
  'よくできました！',
];

const kEncouragementMessages = [
  'だいじょうぶ、もう一回！',
  'おしい！次はいけるよ',
  'いっしょにがんばろう！',
  'あきらめないで！',
  'コツをつかもう！',
];

const kThinkingMessages = [
  'いいかんじ！',
  'その調子で組み立てよう',
  'どんな動きになるかな？',
];
