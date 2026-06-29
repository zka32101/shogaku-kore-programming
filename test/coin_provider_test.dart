import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/providers/coin_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('CoinNotifier - earnCoins()', () {
    test('コインを加算できる', () async {
      final notifier = CoinNotifier();
      // ロード待機
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.earnCoins(10);
      expect(notifier.state.balance, 10);
      expect(notifier.state.totalEarned, 10);
    });

    test('複数回加算が累計される', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.earnCoins(5);
      await notifier.earnCoins(3);
      expect(notifier.state.balance, 8);
      expect(notifier.state.totalEarned, 8);
    });

    test('0以下の加算は無視される', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.earnCoins(0);
      await notifier.earnCoins(-5);
      expect(notifier.state.balance, 0);
    });
  });

  group('CoinNotifier - purchaseItem()', () {
    test('残高十分: 購入成功・残高減少・purchased登録', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.earnCoins(300);

      final result = await notifier.purchaseItem('char_ninja', 200);

      expect(result, true);
      expect(notifier.state.balance, 100);
      expect(notifier.state.isPurchased('char_ninja'), true);
    });

    test('残高不足: 購入失敗・残高変わらず', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.earnCoins(50);

      final result = await notifier.purchaseItem('char_ninja', 200);

      expect(result, false);
      expect(notifier.state.balance, 50);
      expect(notifier.state.isPurchased('char_ninja'), false);
    });

    test('購入済みアイテムの再購入は失敗', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.earnCoins(1000);

      await notifier.purchaseItem('char_ninja', 200);
      final secondResult = await notifier.purchaseItem('char_ninja', 200);

      expect(secondResult, false);
      expect(notifier.state.balance, 800); // 1回分のみ消費
    });
  });

  group('CoinNotifier - purchaseHint()', () {
    test('ヒント×1購入: hintCount+1', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.earnCoins(100);

      final result = await notifier.purchaseHint('hint_x1', 50, 1);

      expect(result, true);
      expect(notifier.state.balance, 50);
      expect(notifier.state.hintCount, 1);
    });

    test('ヒント×3購入: hintCount+3', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.earnCoins(200);

      final result = await notifier.purchaseHint('hint_x3', 120, 3);

      expect(result, true);
      expect(notifier.state.balance, 80);
      expect(notifier.state.hintCount, 3);
    });

    test('ヒント残高不足: 購入失敗', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await notifier.purchaseHint('hint_x1', 50, 1);

      expect(result, false);
      expect(notifier.state.hintCount, 0);
    });
  });

  group('CoinNotifier - useHint()', () {
    test('ヒント所持時: 使用成功・枚数減少', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.earnCoins(100);
      await notifier.purchaseHint('hint_x1', 50, 1);

      final result = await notifier.useHint();

      expect(result, true);
      expect(notifier.state.hintCount, 0);
    });

    test('ヒント未所持: 使用失敗', () async {
      final notifier = CoinNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await notifier.useHint();

      expect(result, false);
    });
  });

  group('CoinState - isPurchased()', () {
    test('購入していないアイテムはfalse', () {
      const state = CoinState();
      expect(state.isPurchased('char_ninja'), false);
    });

    test('購入済みアイテムはtrue', () {
      final state = CoinState(purchasedItemIds: {'char_ninja', 'bg_space'});
      expect(state.isPurchased('char_ninja'), true);
      expect(state.isPurchased('bg_space'), true);
      expect(state.isPurchased('char_alien'), false);
    });
  });
}
