import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' show AvatarImage, AvatarModel, allAvatars;

/// プロフィールのアバター表示。
///
/// 保存されている絵文字（例: 🐱）に対応する動物イラストを丸く表示する。
/// 対応するアバターがない場合（旧版の絵文字・友だちのデータなど）は文字のまま表示する。
class ProfileAvatar extends StatelessWidget {
  final String emoji;
  final double size;

  const ProfileAvatar(this.emoji, {super.key, this.size = 40});

  static AvatarModel? byEmoji(String emoji) {
    for (final a in allAvatars) {
      if (a.emoji == emoji) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final a = byEmoji(emoji);
    if (a == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.7))),
      );
    }
    return AvatarImage(avatar: a, size: size);
  }
}
