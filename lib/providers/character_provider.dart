import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';

const _kCharacterKey = 'user_character';

/// コードカテゴリとスタット対応
const _categoryToStat = {
  'sequence': 'strength',   // 順序問題 → 力
  'branch':   'wisdom',     // 分岐問題 → 知恵
  'loop':     'wisdom',     // ループ問題 → 知恵
  'variable': 'wisdom',     // 変数問題 → 知恵
  'array':    'strength',   // 配列問題 → 力
  'function': 'creativity', // 関数問題 → 創造
  'algorithm':'wisdom',     // アルゴリズム → 知恵
  'visual':   'creativity', // ブロック操作 → 創造
  'timeattack':'speed',     // タイムアタック → スピード
  'debug':    'wisdom',     // デバッグ → 知恵
};

class CharacterState {
  final UserCharacter? character;
  final bool isLoading;
  final String? lastGrowthMessage; // 直前の成長メッセージ
  final bool didStageUp;

  const CharacterState({
    this.character,
    this.isLoading = true,
    this.lastGrowthMessage,
    this.didStageUp = false,
  });
}

class CharacterNotifier extends StateNotifier<CharacterState> {
  CharacterNotifier() : super(const CharacterState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kCharacterKey);
      if (jsonStr == null) {
        // 初回：デフォルトキャラクターを作成
        final defaultChar = UserCharacter(
          characterId: kAvailableCharacters.first.id,
          name: 'マイキャラ',
        );
        state = CharacterState(character: defaultChar, isLoading: false);
        return;
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      state = CharacterState(
        character: UserCharacter.fromMap(map),
        isLoading: false,
      );
    } catch (e) {
      state = CharacterState(
        character: UserCharacter(characterId: kAvailableCharacters.first.id),
        isLoading: false,
      );
    }
  }

  Future<void> _save(UserCharacter character) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCharacterKey, jsonEncode(character.toMap()));
  }

  /// コード正解時にキャラクターを成長させる
  Future<void> growFromCorrectAnswer({
    required String challengeType, // 'sequence', 'branch', 'loop', etc.
    required String difficulty,     // '初級', '中級', '上級'
  }) async {
    final current = state.character;
    if (current == null) return;

    // XP計算（難易度別）
    final xpGain = switch (difficulty) {
      '初級' => 1,
      '中級' => 2,
      '上級' => 3,
      _ => 1,
    };

    final statKey = _categoryToStat[challengeType] ?? 'strength';
    final newStats = _addStat(current.stats, statKey, xpGain);
    final newXp = current.totalXp + xpGain;
    final oldStage = current.stage;
    final newStage = calcStage(newXp);
    final didStageUp = newStage.index > oldStage.index;

    // スキル解放チェック
    final newSkills = [...current.unlockedSkills];
    final newSkill = _checkSkillUnlock(newStats, newSkills);
    if (newSkill != null) newSkills.add(newSkill);

    final updated = current.copyWith(
      stage: newStage,
      stats: newStats,
      totalXp: newXp,
      unlockedSkills: newSkills,
    );

    await _save(updated);

    final growthMsg = didStageUp
        ? '🎉 ${kStageNames[newStage]}に進化した！'
        : '✨ ${_statLabel(statKey)}が+$xpGain 成長！';

    state = CharacterState(
      character: updated,
      isLoading: false,
      lastGrowthMessage: growthMsg,
      didStageUp: didStageUp,
    );
  }

  CharacterStats _addStat(CharacterStats stats, String key, int amount) {
    return switch (key) {
      'strength'   => stats.copyWith(strength: stats.strength + amount),
      'wisdom'     => stats.copyWith(wisdom: stats.wisdom + amount),
      'speed'      => stats.copyWith(speed: stats.speed + amount),
      'creativity' => stats.copyWith(creativity: stats.creativity + amount),
      _ => stats,
    };
  }

  String _statLabel(String key) => switch (key) {
    'strength'   => '力',
    'wisdom'     => '知恵',
    'speed'      => 'スピード',
    'creativity' => '創造力',
    _ => 'ステータス',
  };

  String? _checkSkillUnlock(CharacterStats stats, List<String> existing) {
    if (stats.wisdom >= 20 && !existing.contains('deep_thinking')) {
      return 'deep_thinking';
    }
    if (stats.speed >= 15 && !existing.contains('turbo_mode')) {
      return 'turbo_mode';
    }
    if (stats.creativity >= 10 && !existing.contains('block_master')) {
      return 'block_master';
    }
    if (stats.strength >= 25 && !existing.contains('power_coder')) {
      return 'power_coder';
    }
    return null;
  }

  Future<void> selectCharacter(String characterId) async {
    final current = state.character;
    if (current == null) return;
    final updated = current.copyWith(characterId: characterId);
    await _save(updated);
    state = CharacterState(character: updated, isLoading: false);
  }

  Future<void> renameCharacter(String name) async {
    final current = state.character;
    if (current == null) return;
    final updated = current.copyWith(name: name);
    await _save(updated);
    state = CharacterState(character: updated, isLoading: false);
  }

  void clearGrowthMessage() {
    state = CharacterState(
      character: state.character,
      isLoading: false,
      didStageUp: false,
    );
  }
}

final characterProvider =
    StateNotifierProvider<CharacterNotifier, CharacterState>((ref) {
  return CharacterNotifier();
});
