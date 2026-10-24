import 'package:flutter/material.dart';

import '../models/character_model.dart';

/// キャラクター画像。画像ファイルが無いキャラ・段階は絵文字で代用する。
class CharacterImage extends StatelessWidget {
  final CharacterDefinition definition;
  final CharacterStage stage;
  final double size;

  const CharacterImage({
    super.key,
    required this.definition,
    required this.stage,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = definition.stageEmojis[stage] ?? '🥚';
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        definition.imageAsset(stage),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Text(emoji, style: TextStyle(fontSize: size * 0.62)),
        ),
      ),
    );
  }
}
