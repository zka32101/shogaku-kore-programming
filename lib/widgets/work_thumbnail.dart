import 'package:flutter/material.dart';

import '../models/block_model.dart';
import '../models/user_work.dart';

/// 作品のサムネイル。
/// 保存画像が実画像でない場合(空/1x1プレースホルダー)は、ブロック列から
/// 簡易プレビュー(タイトル頭文字・ブロック数・カテゴリ色の帯)を描く。
class WorkThumbnail extends StatelessWidget {
  final UserWork work;
  final BorderRadius borderRadius;

  const WorkThumbnail({
    super.key,
    required this.work,
    this.borderRadius = BorderRadius.zero,
  });

  /// 1x1 のダミー画像などは実画像として扱わない。
  static bool hasRealImage(String data) => data.length > 400;

  static Color categoryColor(BlockCategory c) {
    switch (c) {
      case BlockCategory.motion:
        return const Color(0xFF3498DB);
      case BlockCategory.control:
        return const Color(0xFFF39C12);
      case BlockCategory.variable:
        return const Color(0xFF9B59B6);
      case BlockCategory.function:
        return const Color(0xFFE74C3C);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasRealImage(work.resultImage)) {
      try {
        return ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox.expand(
            child: Image.memory(
              Uri.parse(work.resultImage).data!.contentAsBytes(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _preview(),
            ),
          ),
        );
      } catch (_) {
        // 下の簡易プレビューにフォールバック
      }
    }
    return ClipRRect(borderRadius: borderRadius, child: _preview());
  }

  Widget _preview() {
    final blocks = work.blocks;
    final title = work.challengeTitle.trim();
    final initial = title.isEmpty ? '?' : String.fromCharCode(title.runes.first);
    final isFree = work.challengeId.startsWith('free_');
    return Container(
      key: const Key('work_thumbnail_preview'),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isFree ? Icons.brush : Icons.extension,
                    size: 28, color: const Color(0xFF5E35B1)),
                const SizedBox(height: 4),
                Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4527A0),
                  ),
                ),
              ],
            ),
          ),
          if (blocks.isNotEmpty)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      for (final b in blocks.take(16))
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: categoryColor(b.category),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ブロック${blocks.length}こ',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF4527A0)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
