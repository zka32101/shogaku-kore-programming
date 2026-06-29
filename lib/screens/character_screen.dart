import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/character_model.dart';
import '../providers/character_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

class CharacterScreen extends ConsumerStatefulWidget {
  const CharacterScreen({super.key});

  @override
  ConsumerState<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends ConsumerState<CharacterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charState = ref.watch(characterProvider);
    final character = charState.character;

    if (charState.isLoading || character == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final charDef = kAvailableCharacters.firstWhere(
      (c) => c.id == character.characterId,
      orElse: () => kAvailableCharacters.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌱 キャラクター育成'),
        backgroundColor: const Color(0xFF8E44AD),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'マイキャラ'),
            Tab(text: 'キャラ選択'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCharacterTab(context, character, charDef),
          _buildCharacterSelectTab(context, character),
        ],
      ),
    );
  }

  Widget _buildMyCharacterTab(
    BuildContext context,
    UserCharacter character,
    CharacterDefinition charDef,
  ) {
    final stageEmoji = charDef.stageEmojis[character.stage] ?? '🥚';
    final stageName = kStageNames[character.stage] ?? '';
    final nextStage = CharacterStage.values
        .firstWhere((s) => s.index == character.stage.index + 1,
            orElse: () => CharacterStage.master);
    final nextThreshold = kStageThresholds[nextStage] ?? 300;
    final xpProgress = character.totalXp / nextThreshold;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // キャラクター表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8E44AD).withValues(alpha: 0.8),
                  const Color(0xFF9B59B6).withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  stageEmoji,
                  style: const TextStyle(fontSize: 80),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.08, 1.08),
                      duration: 1500.ms,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.08, 1.08),
                      end: const Offset(1.0, 1.0),
                      duration: 1500.ms,
                    ),
                const SizedBox(height: 12),
                Text(
                  character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '【$stageName】${charDef.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                // XP進捗バー
                Text(
                  'XP: ${character.totalXp} / $nextThreshold',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                    minHeight: 8,
                  ),
                ),
                if (character.stage != CharacterStage.master) ...[
                  const SizedBox(height: 4),
                  Text(
                    'あと ${nextThreshold - character.totalXp} XP で【${kStageNames[nextStage]}】に進化！',
                    style: const TextStyle(color: Colors.yellowAccent, fontSize: 11),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text(
                    '🏆 最強ステージ達成！',
                    style: TextStyle(color: Colors.yellowAccent, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ステータス
          _buildStatsSection(character),
          const SizedBox(height: 20),

          // スキル
          if (character.unlockedSkills.isNotEmpty) ...[
            _buildSkillsSection(character),
            const SizedBox(height: 20),
          ],

          // 成長方法の説明
          _buildGrowthGuide(),
        ],
      ),
    );
  }

  Widget _buildStatsSection(UserCharacter character) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 ステータス',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _buildStatBar('💪 力', character.stats.strength, 50, Colors.orange),
          const SizedBox(height: 8),
          _buildStatBar('🧠 知恵', character.stats.wisdom, 50, Colors.blue),
          const SizedBox(height: 8),
          _buildStatBar('⚡ スピード', character.stats.speed, 50, Colors.green),
          const SizedBox(height: 8),
          _buildStatBar('🎨 創造力', character.stats.creativity, 50, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, int max, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / max).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(UserCharacter character) {
    const skillInfo = {
      'deep_thinking': ('🧠 深い思考', '難問を解く力を持つ', Colors.blue),
      'turbo_mode': ('⚡ ターボモード', '素早く答えを出す', Colors.green),
      'block_master': ('🎨 ブロック名人', 'ビジュアルプログラムが得意', Colors.purple),
      'power_coder': ('💪 パワーコーダー', '基礎力が高い', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ 解放スキル',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...character.unlockedSkills.map((skill) {
            final info = skillInfo[skill];
            if (info == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: info.$3.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(info.$1, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.$2,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrowthGuide() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 成長のヒント',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('💪 力：順序・配列問題を解こう', style: TextStyle(fontSize: 12)),
          const Text('🧠 知恵：if文・ループ・関数問題で成長', style: TextStyle(fontSize: 12)),
          const Text('⚡ スピード：タイムアタックで鍛えよう', style: TextStyle(fontSize: 12)),
          const Text('🎨 創造力：ブロック操作を完成させよう', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCharacterSelectTab(BuildContext context, UserCharacter character) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'キャラクターを選択',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '選択したキャラクターで育成を続けます',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...kAvailableCharacters.map((charDef) {
          final isSelected = charDef.id == character.characterId;
          return GestureDetector(
            onTap: () {
              HapticService.lightImpact();
              SoundService().playTap();
              ref.read(characterProvider.notifier).selectCharacter(charDef.id);
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8E44AD).withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8E44AD)
                      : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    charDef.stageEmojis[character.stage] ??
                        charDef.stageEmojis[CharacterStage.baby]!,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              charDef.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8E44AD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '選択中',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          charDef.description,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
