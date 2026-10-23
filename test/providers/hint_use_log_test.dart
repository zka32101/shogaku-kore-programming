import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('直近7日間のヒント使用を、使った日数の多い順に返す', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(progressProvider.notifier);
    final now = DateTime(2026, 10, 23, 12);

    await n.recordHintUse('a', now: DateTime(2026, 10, 23));
    await n.recordHintUse('b', now: DateTime(2026, 10, 22));
    await n.recordHintUse('b', now: DateTime(2026, 10, 21));
    await n.recordHintUse('old', now: DateTime(2026, 10, 1)); // 期間外

    expect(n.hintStageIdsWithin(now: now), ['b', 'a']);
  });

  test('同じ日の同じステージは1件だけ数える', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(progressProvider.notifier);
    final d = DateTime(2026, 10, 23);

    await n.recordHintUse('a', now: d);
    await n.recordHintUse('a', now: d);
    await n.recordHintUse('b', now: d);

    expect(n.hintStageIdsWithin(now: d), unorderedEquals(['a', 'b']));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('hint_uses'), hasLength(2));
  });

  test('リセットで消える', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(progressProvider.notifier);
    await n.recordHintUse('a', now: DateTime(2026, 10, 23));
    await n.resetAll();
    expect(n.hintStageIdsWithin(now: DateTime(2026, 10, 23)), isEmpty);
  });
}
