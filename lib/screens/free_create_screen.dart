import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/block_model.dart';
import '../providers/editor_provider.dart';
import '../providers/gallery_provider.dart';
import '../services/haptic_service.dart';
import '../widgets/robot_canvas.dart';
import '../widgets/glossary_text.dart';
import 'package:shogaku_kore_programming/widgets/ukalab_emoji.dart';

/// 自由にブロックを組み合わせてオリジナルの「ゲーム（ロボットの動き）」を
/// 作れる画面。ステージ課題とは違い、正解／不正解の判定はなく、
/// 作った作品はギャラリーに保存していつでも見返したり再生できる。
class FreeCreateScreen extends ConsumerStatefulWidget {
  const FreeCreateScreen({super.key});

  @override
  ConsumerState<FreeCreateScreen> createState() => _FreeCreateScreenState();
}

class _FreeCreateScreenState extends ConsumerState<FreeCreateScreen> {
  @override
  void initState() {
    super.initState();
    // 前回の自由制作の続きが残っていないように、開始時にリセットする
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(freeCreateProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freeCreateProvider);

    return Scaffold(
      backgroundColor: context.cardBg,
      appBar: AppBar(
        title: const Text('🎮 自由に作る'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '元に戻す',
            onPressed: ref.read(freeCreateProvider.notifier).canUndo
                ? () => ref.read(freeCreateProvider.notifier).undo()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'やり直す',
            onPressed: ref.read(freeCreateProvider.notifier).canRedo
                ? () => ref.read(freeCreateProvider.notifier).redo()
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: kPrimaryColor.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const GlossaryText(
              text: 'すきなブロックを組み合わせて、じぶんだけのロボットの動きを作ってみよう！',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          AspectRatio(
            aspectRatio: 1.4,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: RobotCanvasWidget(
                path: state.robotPath,
                finalAngle: state.robotAngle,
                hasSubmitted: false,
                isCorrect: false,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 140, child: _buildPalette()),
                Expanded(child: _buildScriptArea(state)),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticService.lightImpact();
                        ref.read(freeCreateProvider.notifier).executeScript();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('うごかす'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: state.scriptBlocks.isEmpty
                          ? null
                          : () => _showSaveDialog(context),
                      icon: const Icon(Icons.save_alt),
                      label: const Text('ほぞんする'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    return Container(
      color: context.subCardBg,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final category in BlockCategory.values)
            ..._paletteSection(category),
        ],
      ),
    );
  }

  List<Widget> _paletteSection(BlockCategory category) {
    final blocks = kAvailableBlocks.where((b) => b.category == category).toList();
    if (blocks.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        child: Text(
          _categoryLabel(category),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
        ),
      ),
      for (final block in blocks) _paletteTile(block),
    ];
  }

  Widget _paletteTile(Block block) {
    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        ref.read(freeCreateProvider.notifier).addBlock(block);
      },
      onLongPress: () => _showBlockInfo(block),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            UkalabEmoji(block.icon, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                block.name,
                style: TextStyle(fontSize: 11, color: context.textPrimary),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockInfo(Block block) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${block.icon} ${block.name}'),
        content: GlossaryText(
          text: block.description,
          style: TextStyle(fontSize: 13, color: context.textPrimary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('わかった！'),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptArea(EditorState state) {
    if (state.scriptBlocks.isEmpty) {
      return Center(
        child: Text(
          '← ブロックをタップして\nここに追加しよう',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: context.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: state.scriptBlocks.length,
      itemBuilder: (context, index) {
        final block = state.scriptBlocks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  block.displayText,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(freeCreateProvider.notifier).removeBlock(index),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('作品を保存する'),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: '例）くるくるダンスロボ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              _saveWork(name.isEmpty ? 'わたしの作品' : name);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('ほぞんする'),
          ),
        ],
      ),
    );
  }

  void _saveWork(String title) {
    final blocks = ref.read(freeCreateProvider).scriptBlocks;
    ref.read(galleryProvider.notifier).addWork(
          challengeId: 'free_${DateTime.now().millisecondsSinceEpoch}',
          challengeTitle: title,
          blockCode: jsonEncode(blocks.map((b) => b.toJson()).toList()),
          resultImage: '',
          difficulty: '自由制作',
        );
    HapticService.lightImpact();
  }

  String _categoryLabel(BlockCategory category) {
    switch (category) {
      case BlockCategory.motion:
        return '📍 動き';
      case BlockCategory.control:
        return '🔁 制御';
      case BlockCategory.variable:
        return '📦 変数';
      case BlockCategory.function:
        return '🎁 関数';
    }
  }
}
