import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// お気に入りステージIDを永続保存するプロバイダー

class FavoritesState {
  final Set<String> favoriteIds;
  const FavoritesState({this.favoriteIds = const {}});

  FavoritesState copyWith({Set<String>? favoriteIds}) =>
      FavoritesState(favoriteIds: favoriteIds ?? this.favoriteIds);

  bool isFavorite(String id) => favoriteIds.contains(id);
  int get count => favoriteIds.length;
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState()) {
    _load();
  }

  static const _key = 'favorites_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = (json.decode(raw) as List).cast<String>();
      state = state.copyWith(favoriteIds: Set.from(list));
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(state.favoriteIds.toList()));
  }

  /// お気に入りをトグルする。(wasAdded, newCount) を返す。
  Future<(bool wasAdded, int newCount)> toggle(String challengeId) async {
    final current = Set<String>.from(state.favoriteIds);
    final wasAdded = !current.contains(challengeId);
    if (wasAdded) {
      current.add(challengeId);
    } else {
      current.remove(challengeId);
    }
    state = state.copyWith(favoriteIds: current);
    await _save();
    return (wasAdded, current.length);
  }

  Future<void> clearAll() async {
    state = const FavoritesState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
        (ref) => FavoritesNotifier());
