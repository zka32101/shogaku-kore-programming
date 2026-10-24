import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/coin_provider.dart';
import 'decor_items.dart';

/// いま「つけている」きせかえ。種類ごとに1つ。何もつけていなければ null。
class DecorState {
  const DecorState({this.background, this.frame, this.effect});

  final String? background;
  final String? frame;
  final String? effect;

  String? of(DecorKind kind) {
    switch (kind) {
      case DecorKind.background:
        return background;
      case DecorKind.frame:
        return frame;
      case DecorKind.effect:
        return effect;
    }
  }

  DecorState withKind(DecorKind kind, String? id) {
    switch (kind) {
      case DecorKind.background:
        return DecorState(background: id, frame: frame, effect: effect);
      case DecorKind.frame:
        return DecorState(background: background, frame: id, effect: effect);
      case DecorKind.effect:
        return DecorState(background: background, frame: frame, effect: id);
    }
  }
}

class DecorNotifier extends StateNotifier<DecorState> {
  DecorNotifier(this._ref) : super(const DecorState()) {
    _load();
  }

  final Ref _ref;

  static const keyOf = {
    DecorKind.background: 'decor_background',
    DecorKind.frame: 'decor_frame',
    DecorKind.effect: 'decor_effect',
  };

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = DecorState(
      background: p.getString(keyOf[DecorKind.background]!),
      frame: p.getString(keyOf[DecorKind.frame]!),
      effect: p.getString(keyOf[DecorKind.effect]!),
    );
  }

  /// 買ったきせかえをつける。持っていないものはつけられない。
  Future<bool> equip(DecorItem item) async {
    final owned = _ref.read(coinProvider).purchasedItemIds;
    if (!owned.contains(item.id)) return false;
    state = state.withKind(item.kind, item.id);
    final p = await SharedPreferences.getInstance();
    await p.setString(keyOf[item.kind]!, item.id);
    return true;
  }

  /// はずす。
  Future<void> unequip(DecorKind kind) async {
    state = state.withKind(kind, null);
    final p = await SharedPreferences.getInstance();
    await p.remove(keyOf[kind]!);
  }
}

final decorProvider = StateNotifierProvider<DecorNotifier, DecorState>(DecorNotifier.new);

/// 持っているものだけに絞った「いまのきせかえ」。持っていない・知らない・種類違いのIDは無視する。
final activeDecorProvider = Provider<DecorState>((ref) {
  final s = ref.watch(decorProvider);
  final owned = ref.watch(coinProvider).purchasedItemIds;
  String? valid(DecorKind k) {
    final item = decorItemById(s.of(k));
    return (item != null && item.kind == k && owned.contains(item.id)) ? item.id : null;
  }

  return DecorState(
    background: valid(DecorKind.background),
    frame: valid(DecorKind.frame),
    effect: valid(DecorKind.effect),
  );
});
