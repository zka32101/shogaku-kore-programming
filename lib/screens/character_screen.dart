import '../features/shop/decor/decor_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/character_model.dart';
import '../providers/my_character_provider.dart';
import '../widgets/character_image.dart';

/// マイキャラ画面：選んだキャラの成長・ステータスと、キャラ選び。
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final my = ref.watch(myCharacterProvider);
    final def = my.definition;
    final stage = my.stage;
    final next = my.nextThreshold;

    return Scaffold(
      backgroundColor: DecorScope.pageBg(context, context.isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA)),
      appBar: AppBar(
        title: const Text('マイキャラ'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 現在のキャラ ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CharacterImage(definition: def, stage: stage, size: 200),
                const SizedBox(height: 8),
                Text(
                  def.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${kStageNames[stage]}　XP ${my.totalXp}',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: my.progressToNext,
                    minHeight: 10,
                    backgroundColor: kPrimaryColor.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? '最強の姿になったよ！'
                      : 'つぎの進化まで あと ${next - my.totalXp} XP',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  def.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── ステータス ───
          _Section(
            title: 'ステータス',
            child: Column(
              children: [
                _StatBar(label: '💪 ちから', value: my.stats.strength),
                _StatBar(label: '🧠 ちえ', value: my.stats.wisdom),
                _StatBar(label: '⚡ すばやさ', value: my.stats.speed),
                _StatBar(label: '🎨 そうぞう', value: my.stats.creativity),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 進化の道 ───
          _Section(
            title: '進化のみちすじ',
            child: SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final s in CharacterStage.values)
                    _StageChip(def: def, stage: s, reached: s.index <= stage.index),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── キャラ選び ───
          _Section(
            title: 'キャラをえらぶ',
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.66,
              children: [
                for (final c in kAvailableCharacters)
                  _PickTile(
                    def: c,
                    stage: stage,
                    selected: c.id == def.id,
                    onTap: () => ref.read(myCharacterProvider.notifier).select(c.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: DecorScope.chipBg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'キャラをかえても、XPはそのまま引きつがれるよ。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  const _StatBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    // 表示上の上限は 50 として割合を出す（上限を超えても満タンのまま）
    final ratio = (value / 50).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(color: context.textPrimary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: kPrimaryColor.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final CharacterDefinition def;
  final CharacterStage stage;
  final bool reached;
  const _StageChip({
    required this.def,
    required this.stage,
    required this.reached,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Opacity(
            opacity: reached ? 1 : 0.28,
            child: CharacterImage(definition: def, stage: stage, size: 60),
          ),
          const SizedBox(height: 4),
          Text(
            reached ? (kStageNames[stage] ?? '') : '？？？',
            style: TextStyle(fontSize: 11, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  final CharacterDefinition def;
  final CharacterStage stage;
  final bool selected;
  final VoidCallback onTap;
  const _PickTile({
    required this.def,
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kPrimaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            CharacterImage(definition: def, stage: stage, size: 58),
            const SizedBox(height: 2),
            Text(
              def.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: context.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
