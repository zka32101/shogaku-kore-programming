import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart' as sc show coinProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/providers/coin_provider.dart';
import 'package:shogaku_kore_programming/services/retention_coin_bridge.dart';

void main() {
  test('shared_core の addCoins がアプリの残高・永続データに反映される', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [sc.coinProvider.overrideWith(RetentionCoinBridge.new)],
    );
    addTearDown(container.dispose);
    container.read(coinProvider); // ロード開始
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container.read(sc.coinProvider.notifier).addCoins(30);

    expect(container.read(coinProvider).balance, 30);
    expect(container.read(coinProvider).totalEarned, 30);
    expect(container.read(sc.coinProvider).totalCoins, 30);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('coin_balance'), 30);
  });
}
