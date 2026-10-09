import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/coin_provider.dart';
import '../../../providers/progress_provider.dart';
import 'title_items.dart';

const String kEquippedTitleKey = 'equipped_title';

/// いま「つけている」称号ID。何もつけていなければ null。
class TitleNotifier extends StateNotifier<String?> {
  TitleNotifier(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getString(kEquippedTitleKey);
  }

  Future<bool> buy(TitleItem t) async {
    if (!t.isPurchasable) return false;
    return _ref.read(coinProvider.notifier).purchaseItem(t.id, t.coinCost!);
  }

  Future<bool> equip(TitleItem t) async {
    final ok = isTitleAvailable(
      t,
      owned: _ref.read(coinProvider).purchasedItemIds,
      progress: _ref.read(titleProgressProvider),
    );
    if (!ok) return false;
    state = t.id;
    final p = await SharedPreferences.getInstance();
    await p.setString(kEquippedTitleKey, t.id);
    return true;
  }

  Future<void> unequip() async {
    state = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(kEquippedTitleKey);
  }
}

final titleProvider = StateNotifierProvider<TitleNotifier, String?>(TitleNotifier.new);

/// 既存の進捗から作る、称号判定用の値（新しい計測はしない）。
final titleProgressProvider = Provider<TitleProgress>((ref) {
  final map = ref.watch(progressProvider);
  final n = ref.read(progressProvider.notifier);
  return TitleProgress(
    level: n.currentLevel,
    streakDays: n.longestStreak > n.streakDays ? n.longestStreak : n.streakDays,
    clearedStages: map.values.where((p) => p.isCompleted).length,
  );
});

/// 持っている/達成した称号だけに絞った「いまの称号」。無効なら null。
final activeTitleProvider = Provider<TitleItem?>((ref) {
  final t = titleItemById(ref.watch(titleProvider));
  if (t == null) return null;
  final ok = isTitleAvailable(
    t,
    owned: ref.watch(coinProvider).purchasedItemIds,
    progress: ref.watch(titleProgressProvider),
  );
  return ok ? t : null;
});
