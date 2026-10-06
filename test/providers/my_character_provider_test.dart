import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shogaku_kore_programming/models/character_model.dart';
import 'package:shogaku_kore_programming/providers/my_character_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('8体のキャラが定義されている', () {
    expect(kAvailableCharacters.length, 8);
    expect(kAvailableCharacters.map((c) => c.id).toSet().length, 8);
  });

  test('画像パスは assetKey（無ければ id）+ 段階名', () {
    final robot = kAvailableCharacters.firstWhere((c) => c.id == 'robot_buddy');
    expect(robot.imageAsset(CharacterStage.baby), 'assets/characters/robot_baby.png');
    final dragon = kAvailableCharacters.firstWhere((c) => c.id == 'block_dragon');
    expect(dragon.imageAsset(CharacterStage.master),
        'assets/characters/block_dragon_master.png');
  });

  test('XPがたまると進化し、進化した段階が通知される', () async {
    final n = MyCharacterNotifier();
    await Future<void>.delayed(Duration.zero);
    expect(n.state.stage, CharacterStage.egg);
    await n.grow(9);
    expect(n.state.stage, CharacterStage.egg);
    expect(n.state.justEvolvedTo, isNull);
    await n.grow(1); // 10 XP → baby
    expect(n.state.stage, CharacterStage.baby);
    expect(n.state.justEvolvedTo, CharacterStage.baby);
    n.clearEvolution();
    expect(n.state.justEvolvedTo, isNull);
  });

  test('ステータスは得意分野（または指定）に加算される', () async {
    final n = MyCharacterNotifier();
    await n.grow(2, focus: 'wisdom');
    await n.grow(2, focus: 'speed');
    expect(n.state.stats.wisdom, 1);
    expect(n.state.stats.speed, 1);
    await n.select('block_dragon');
    await n.grow(2); // 得意分野 strength
    expect(n.state.stats.strength, 1);
    expect(n.state.totalXp, 6);
  });

  test('キャラを変えてもXPは引き継がれ、保存・復元できる', () async {
    final n = MyCharacterNotifier();
    await n.grow(35);
    await n.select('loop_panda');
    await Future<void>.delayed(Duration.zero);
    final n2 = MyCharacterNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(n2.state.characterId, 'loop_panda');
    expect(n2.state.totalXp, 35);
    expect(n2.state.stage, CharacterStage.child);
  });

  test('進化までの進み具合', () async {
    final n = MyCharacterNotifier();
    await n.grow(20); // baby(10)〜child(30) の中間
    expect(n.state.nextThreshold, 30);
    expect(n.state.progressToNext, closeTo(0.5, 0.001));
    await n.grow(1000);
    expect(n.state.nextThreshold, isNull);
    expect(n.state.progressToNext, 1.0);
  });
}
