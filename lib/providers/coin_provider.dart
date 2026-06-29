import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// コイン残高・購入済みアイテムを管理するステート
class CoinState {
  final int balance;
  final int totalEarned;
  final Set<String> purchasedItemIds;
  final int hintCount; // 消耗品ヒントの残り枚数

  const CoinState({
    this.balance = 0,
    this.totalEarned = 0,
    this.purchasedItemIds = const {},
    this.hintCount = 0,
  });

  CoinState copyWith({
    int? balance,
    int? totalEarned,
    Set<String>? purchasedItemIds,
    int? hintCount,
  }) {
    return CoinState(
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      purchasedItemIds: purchasedItemIds ?? this.purchasedItemIds,
      hintCount: hintCount ?? this.hintCount,
    );
  }

  bool isPurchased(String itemId) => purchasedItemIds.contains(itemId);
}

class CoinNotifier extends StateNotifier<CoinState> {
  CoinNotifier() : super(const CoinState()) {
    _load();
  }

  static const _balanceKey = 'coin_balance';
  static const _totalEarnedKey = 'coin_total_earned';
  static const _purchasedKey = 'coin_purchased_ids';
  static const _hintCountKey = 'coin_hint_count';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final balance = prefs.getInt(_balanceKey) ?? 0;
    final totalEarned = prefs.getInt(_totalEarnedKey) ?? 0;
    final hintCount = prefs.getInt(_hintCountKey) ?? 0;
    final purchasedJson = prefs.getString(_purchasedKey) ?? '[]';
    final purchasedList = List<String>.from(
      (jsonDecode(purchasedJson) as List).map((e) => e.toString()),
    );
    state = CoinState(
      balance: balance,
      totalEarned: totalEarned,
      purchasedItemIds: Set.from(purchasedList),
      hintCount: hintCount,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, state.balance);
    await prefs.setInt(_totalEarnedKey, state.totalEarned);
    await prefs.setInt(_hintCountKey, state.hintCount);
    await prefs.setString(
      _purchasedKey,
      jsonEncode(state.purchasedItemIds.toList()),
    );
  }

  /// コインを獲得する
  Future<void> earnCoins(int amount) async {
    if (amount <= 0) return;
    state = state.copyWith(
      balance: state.balance + amount,
      totalEarned: state.totalEarned + amount,
    );
    await _save();
  }

  /// 通常アイテムを購入する（コスメ/サウンド等）
  /// 成功: true, 残高不足/購入済み: false
  Future<bool> purchaseItem(String itemId, int cost) async {
    if (state.balance < cost) return false;
    if (state.purchasedItemIds.contains(itemId)) return false;
    state = state.copyWith(
      balance: state.balance - cost,
      purchasedItemIds: {...state.purchasedItemIds, itemId},
    );
    await _save();
    return true;
  }

  /// ヒント（消耗品）を購入する
  /// hintCount: 追加枚数（1 or 3）
  Future<bool> purchaseHint(String itemId, int cost, int hintCount) async {
    if (state.balance < cost) return false;
    state = state.copyWith(
      balance: state.balance - cost,
      hintCount: state.hintCount + hintCount,
    );
    await _save();
    return true;
  }

  /// ヒントを1枚消費する
  Future<bool> useHint() async {
    if (state.hintCount <= 0) return false;
    state = state.copyWith(hintCount: state.hintCount - 1);
    await _save();
    return true;
  }
}

final coinProvider = StateNotifierProvider<CoinNotifier, CoinState>(
  (ref) => CoinNotifier(),
);

// ─── コイン計算ヘルパー ───

/// クイズ難易度からコイン単価を返す
int coinPerCorrect(String level) {
  switch (level) {
    case '初級': return 1;
    case '中級': return 2;
    case '上級': return 3;
    default:    return 1;
  }
}

/// クイズ結果からコイン合計を計算する
/// [level]       : ステージ難易度（'初級'/'中級'/'上級'）
/// [correctCount]: 正解数
/// [totalCount]  : 問題数
/// [maxCombo]    : セッション中の最大連続正解数
/// 戻り値: (coinTotal, comboBonus, perfectBonus)
(int, int, int) calcQuizCoins({
  required String level,
  required int correctCount,
  required int totalCount,
  required int maxCombo,
}) {
  final base = correctCount * coinPerCorrect(level);
  final comboBonus = maxCombo >= 3 ? 5 : 0;
  final perfectBonus = (correctCount == totalCount && totalCount > 0) ? 10 : 0;
  return (base + comboBonus + perfectBonus, comboBonus, perfectBonus);
}

/// エディタ（ビジュアル型）の正解コイン
int calcEditorCoins(String level) {
  // ビジュアル型は一問クリア扱い。難易度×2
  return coinPerCorrect(level) * 2;
}
