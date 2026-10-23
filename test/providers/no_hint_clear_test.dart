import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('同じステージは1回だけ数え、通算数を返す', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(progressProvider.notifier);

    expect(await n.recordNoHintClear('stage_01'), 1);
    expect(await n.recordNoHintClear('stage_01'), 1);
    expect(await n.recordNoHintClear('stage_02'), 2);
    expect(n.noHintClearCount, 2);
  });

  test('保存され、作り直しても残る。リセットで消える', () async {
    final c1 = ProviderContainer();
    await c1.read(progressProvider.notifier).recordNoHintClear('stage_01');
    c1.dispose();

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final n = c2.read(progressProvider.notifier);
    // 起動時の非同期ロードが終わるまで待つ（固定時間だと負荷で不安定になる）
    for (var i = 0; i < 100 && n.noHintClearCount == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(n.noHintClearCount, 1);

    await n.resetAll();
    expect(n.noHintClearCount, 0);
  });
}
