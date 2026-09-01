import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/avatar.dart';
import 'coin_provider.dart';

/// Pre-defined default avatars (first 4 available to all users)
const List<Avatar> _defaultAvatars = [
  Avatar(
    id: 'avatar_1',
    name: 'Ninja',
    emoji: '🥷',
    isDefault: true,
    price: 0,
  ),
  Avatar(
    id: 'avatar_2',
    name: 'Astronaut',
    emoji: '👨‍🚀',
    isDefault: true,
    price: 0,
  ),
  Avatar(
    id: 'avatar_3',
    name: 'Scholar',
    emoji: '🧑‍🎓',
    isDefault: true,
    price: 0,
  ),
  Avatar(
    id: 'avatar_4',
    name: 'Artist',
    emoji: '🎨',
    isDefault: true,
    price: 0,
  ),
];

/// Premium avatars available for purchase
const List<Avatar> _premiumAvatars = [
  Avatar(
    id: 'avatar_5',
    name: 'Dragon Master',
    emoji: '🐉',
    isDefault: false,
    price: 200,
  ),
  Avatar(
    id: 'avatar_6',
    name: 'Golden Guardian',
    emoji: '👑',
    isDefault: false,
    price: 250,
  ),
  Avatar(
    id: 'avatar_7',
    name: 'Alien Explorer',
    emoji: '👽',
    isDefault: false,
    price: 300,
  ),
  Avatar(
    id: 'avatar_8',
    name: 'Robot Engineer',
    emoji: '🤖',
    isDefault: false,
    price: 350,
  ),
];

/// Avatar state class
class AvatarState {
  final List<Avatar> allAvatars;
  final String selectedAvatarId;
  final Set<String> ownedAvatarIds;

  const AvatarState({
    required this.allAvatars,
    required this.selectedAvatarId,
    required this.ownedAvatarIds,
  });

  /// Get currently selected avatar
  Avatar get selectedAvatar =>
      allAvatars.firstWhere((a) => a.id == selectedAvatarId);

  /// Get available avatars (default + owned premium)
  List<Avatar> get availableAvatars => allAvatars
      .where((a) => a.isDefault || ownedAvatarIds.contains(a.id))
      .toList();

  /// Get purchasable avatars (premium not owned)
  List<Avatar> get purchasableAvatars => allAvatars
      .where((a) => !a.isDefault && !ownedAvatarIds.contains(a.id))
      .toList();

  /// Check if avatar is owned
  bool isAvatarOwned(String avatarId) {
    final avatar = allAvatars.firstWhere((a) => a.id == avatarId);
    return avatar.isDefault || ownedAvatarIds.contains(avatarId);
  }

  /// Copy with new selected avatar
  AvatarState copyWith({
    List<Avatar>? allAvatars,
    String? selectedAvatarId,
    Set<String>? ownedAvatarIds,
  }) =>
      AvatarState(
        allAvatars: allAvatars ?? this.allAvatars,
        selectedAvatarId: selectedAvatarId ?? this.selectedAvatarId,
        ownedAvatarIds: ownedAvatarIds ?? this.ownedAvatarIds,
      );
}

/// Avatar notifier for managing avatar state
class AvatarNotifier extends StateNotifier<AvatarState> {
  late SharedPreferences _prefs;
  final Ref _ref;

  static const String _selectedAvatarKey = 'selected_avatar';
  static const String _ownedAvatarsKey = 'owned_avatars';

  AvatarNotifier(this._ref)
      : super(
          AvatarState(
            allAvatars: [..._defaultAvatars, ..._premiumAvatars],
            selectedAvatarId: 'avatar_1',
            ownedAvatarIds: {},
          ),
        );

  /// Initialize avatar provider with persisted data
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPersistedData();
  }

  /// Load persisted avatar selection and owned avatars
  Future<void> _loadPersistedData() async {
    final selectedId = _prefs.getString(_selectedAvatarKey) ?? 'avatar_1';
    final ownedJson = _prefs.getStringList(_ownedAvatarsKey) ?? [];
    final owned = ownedJson.toSet();

    state = state.copyWith(
      selectedAvatarId: selectedId,
      ownedAvatarIds: owned,
    );
  }

  /// Select an avatar
  Future<bool> selectAvatar(String avatarId) async {
    // Verify avatar exists and is owned
    if (!state.isAvatarOwned(avatarId)) {
      return false;
    }

    state = state.copyWith(selectedAvatarId: avatarId);
    await _prefs.setString(_selectedAvatarKey, avatarId);
    return true;
  }

  /// Purchase avatar with coins
  Future<bool> purchaseAvatar(String avatarId) async {
    final avatar = state.allAvatars.firstWhere((a) => a.id == avatarId);

    // Check if already owned
    if (state.isAvatarOwned(avatarId)) {
      return false;
    }

    // Check if premium (purchasable)
    if (avatar.isDefault) {
      return false;
    }

    // Get coin provider and deduct coins
    final coinNotifier = _ref.read(coinNotifierProvider.notifier);
    final currentBalance = _ref.read(coinNotifierProvider).balance;

    if (currentBalance < avatar.price) {
      return false; // Not enough coins
    }

    try {
      // Deduct coins
      await coinNotifier.deductCoins(avatar.price);

      // Add to owned avatars
      final updatedOwned = {...state.ownedAvatarIds, avatarId};
      state = state.copyWith(ownedAvatarIds: updatedOwned);

      // Persist owned avatars
      await _prefs.setStringList(_ownedAvatarsKey, updatedOwned.toList());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get avatar by ID
  Avatar? getAvatarById(String id) {
    try {
      return state.allAvatars.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add premium avatar to owned (for testing)
  void addOwnedAvatarForTesting(String avatarId) {
    final updated = {...state.ownedAvatarIds, avatarId};
    state = state.copyWith(ownedAvatarIds: updated);
  }

  /// Clear owned avatars (for testing)
  void clearOwnedAvatarsForTesting() {
    state = state.copyWith(ownedAvatarIds: {});
  }
}

/// Riverpod provider for avatar state
final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarState>((ref) {
  final notifier = AvatarNotifier(ref);
  return notifier;
});

/// Future provider for avatar initialization
final avatarInitializationProvider = FutureProvider<void>((ref) async {
  final notifier = ref.watch(avatarProvider.notifier);
  await notifier.initialize();
});
