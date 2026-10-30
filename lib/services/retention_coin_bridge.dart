import 'package:shared_core/shared_core.dart' as sc;

import '../providers/coin_provider.dart' as app;

/// shared_core の定着率施策（連続正解・週次チャレンジ・初回7日間ほか）は
/// shared_core 側の `coinProvider.addCoins()` でコインを付ける。
/// このアプリの残高・ショップは自前の `coinProvider`（coin_provider.dart）を
/// 使っているため、shared_core 側への加算をアプリ側の残高に橋渡しする。
///
/// main.dart で `sc.coinProvider.overrideWith(RetentionCoinBridge.new)` する。
class RetentionCoinBridge extends sc.CoinNotifier {
  @override
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    await ref.read(app.coinProvider.notifier).earnCoins(amount);
    state = sc.CoinState(totalCoins: ref.read(app.coinProvider).balance);
  }
}
