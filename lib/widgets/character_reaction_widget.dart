import 'package:flutter/material.dart';

/// 育成中キャラクターの「気持ち」。エディタ・クイズ画面で状況に応じて切り替える。
enum CharacterMood { idle, thinking, excited, celebrating, encouraging }

/// 育成中のキャラクターが状況に応じてリアクションする小さなウィジェット。
///
/// キャラクター育成機能は準備中のため、現在は常に何も表示しない
/// （レイアウトを崩さないよう SizedBox.shrink）。
class CharacterReactionWidget extends StatelessWidget {
  final CharacterMood mood;
  final String? message;

  const CharacterReactionWidget({
    super.key,
    this.mood = CharacterMood.idle,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
