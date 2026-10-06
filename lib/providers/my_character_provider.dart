import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/character_model.dart';

/// 「マイキャラ」の状態（選んだキャラ・経験値・ステータス）。
///
/// 正解するとXPがたまり、[kStageThresholds] に達するたびに
/// たまご→よちよち→そだち→かんせい→ぷろ→伝説 と進化する。
class MyCharacterState {
  final String characterId;
  final int totalXp;
  final CharacterStats stats;

  /// 直近の成長で進化した場合、その新しい段階（表示後に [clearEvolution]）
  final CharacterStage? justEvolvedTo;

  const MyCharacterState({
    this.characterId = 'coder_cat',
    this.totalXp = 0,
    this.stats = const CharacterStats(),
    this.justEvolvedTo,
  });

  CharacterStage get stage => calcStage(totalXp);

  CharacterDefinition get definition => kAvailableCharacters.firstWhere(
        (c) => c.id == characterId,
        orElse: () => kAvailableCharacters.first,
      );

  /// 次の段階までに必要なXP（最終段階なら null）
  int? get nextThreshold {
    final next = CharacterStage.values.indexOf(stage) + 1;
    if (next >= CharacterStage.values.length) return null;
    return kStageThresholds[CharacterStage.values[next]];
  }

  /// 現在の段階の中での進み具合 0.0〜1.0（最終段階は 1.0）
  double get progressToNext {
    final next = nextThreshold;
    if (next == null) return 1.0;
    final base = kStageThresholds[stage] ?? 0;
    final span = next - base;
    if (span <= 0) return 1.0;
    return ((totalXp - base) / span).clamp(0.0, 1.0);
  }

  MyCharacterState copyWith({
    String? characterId,
    int? totalXp,
    CharacterStats? stats,
    CharacterStage? justEvolvedTo,
    bool clearEvolution = false,
  }) {
    return MyCharacterState(
      characterId: characterId ?? this.characterId,
      totalXp: totalXp ?? this.totalXp,
      stats: stats ?? this.stats,
      justEvolvedTo: clearEvolution ? null : (justEvolvedTo ?? this.justEvolvedTo),
    );
  }
}

class MyCharacterNotifier extends StateNotifier<MyCharacterState> {
  MyCharacterNotifier() : super(const MyCharacterState()) {
    _load();
  }

  static const _key = 'my_character_v1';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      state = MyCharacterState(
        characterId: m['characterId'] as String? ?? 'coder_cat',
        totalXp: (m['totalXp'] as num?)?.toInt() ?? 0,
        stats: CharacterStats.fromMap(
            Map<String, dynamic>.from(m['stats'] as Map? ?? {})),
      );
    } catch (_) {
      // 読み込みに失敗しても初期状態で続行
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'characterId': state.characterId,
          'totalXp': state.totalXp,
          'stats': state.stats.toMap(),
        }),
      );
    } catch (_) {}
  }

  /// マイキャラを変更する（経験値は引き継ぐ）
  Future<void> select(String characterId) async {
    if (!kAvailableCharacters.any((c) => c.id == characterId)) return;
    state = state.copyWith(characterId: characterId, clearEvolution: true);
    await _save();
  }

  /// XPを加える。進化した場合は [MyCharacterState.justEvolvedTo] に新段階が入る。
  /// [focus] を指定すると、そのステータスも1上がる（未指定なら選択中キャラの得意分野）。
  Future<void> grow(int xp, {String? focus}) async {
    if (xp <= 0) return;
    final before = state.stage;
    final newXp = state.totalXp + xp;
    final key = focus ?? state.definition.growthFocus;
    final s = state.stats;
    final newStats = switch (key) {
      'strength' => s.copyWith(strength: s.strength + 1),
      'wisdom' => s.copyWith(wisdom: s.wisdom + 1),
      'speed' => s.copyWith(speed: s.speed + 1),
      'creativity' => s.copyWith(creativity: s.creativity + 1),
      _ => s,
    };
    final after = calcStage(newXp);
    state = state.copyWith(
      totalXp: newXp,
      stats: newStats,
      justEvolvedTo: after != before ? after : null,
      clearEvolution: after == before,
    );
    await _save();
  }

  void clearEvolution() {
    if (state.justEvolvedTo != null) {
      state = state.copyWith(clearEvolution: true);
    }
  }
}

final myCharacterProvider =
    StateNotifierProvider<MyCharacterNotifier, MyCharacterState>(
  (ref) => MyCharacterNotifier(),
);
