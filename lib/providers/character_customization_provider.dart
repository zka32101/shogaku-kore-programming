import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/character_customization.dart';

/// Character customization state
class CharacterCustomizationState {
  final CharacterCustomizationCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  CharacterCustomizationState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  CharacterCustomizationState copyWith({
    CharacterCustomizationCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      CharacterCustomizationState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

/// Character customization notifier
class CharacterCustomizationNotifier extends StateNotifier<CharacterCustomizationState> {
  CharacterCustomizationNotifier() : super(CharacterCustomizationState());

  /// Initialize character customization
  Future<void> initializeCustomization(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'customization_$userId';

      final stored = prefs.getString(key);
      if (stored != null) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        state = state.copyWith(
          collection: CharacterCustomizationCollection.fromJson(json),
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
        return;
      }

      final now = DateTime.now();
      final defaultCosmetics = _createDefaultCosmetics(now);
      final defaultAppearance = _createDefaultAppearance(userId, now);
      final defaultLoadout = _createDefaultLoadout(userId, defaultAppearance, now);

      final collection = CharacterCustomizationCollection(
        userId: userId,
        activeLoadout: defaultLoadout,
        loadouts: [defaultLoadout],
        allCosmetics: defaultCosmetics,
        ownedCosmetics: [],
        statistics: CustomizationStatistics(
          userId: userId,
          firstCustomizationAt: now,
          lastCustomizationAt: now,
          lastUpdatedAt: now,
        ),
        generatedAt: now,
      );

      await prefs.setString(key, jsonEncode(collection.toJson()));
      state = state.copyWith(
        collection: collection,
        isLoading: false,
        lastUpdatedAt: now,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize customization: $e',
      );
    }
  }

  /// Update character appearance
  Future<void> updateAppearance(
    String userId,
    CharacterGender gender,
    HeadStyle headStyle,
    EyeColor eyeColor,
    HairStyle hairStyle,
    HairColor hairColor,
    SkinTone skinTone,
  ) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final newAppearance = CharacterAppearance(
        appearanceId: 'app_${now.millisecondsSinceEpoch}',
        userId: userId,
        gender: gender,
        headStyle: headStyle,
        eyeColor: eyeColor,
        hairStyle: hairStyle,
        hairColor: hairColor,
        skinTone: skinTone,
      );

      // Update active loadout with new appearance
      final updatedActiveLoadout = CharacterLoadout(
        loadoutId: collection.activeLoadout.loadoutId,
        userId: userId,
        loadoutName: collection.activeLoadout.loadoutName,
        appearance: newAppearance,
        equippedOutfitId: collection.activeLoadout.equippedOutfitId,
        equippedAccessories: collection.activeLoadout.equippedAccessories,
        createdAt: collection.activeLoadout.createdAt,
        lastUsedAt: now,
        isFavorite: collection.activeLoadout.isFavorite,
      );

      final updatedLoadouts = collection.loadouts.map((l) {
        if (l.loadoutId == collection.activeLoadout.loadoutId) {
          return updatedActiveLoadout;
        }
        return l;
      }).toList();

      final stats = collection.statistics;
      final updatedStats = CustomizationStatistics(
        userId: userId,
        totalCosmeticsOwned: stats.totalCosmeticsOwned,
        outfitsOwned: stats.outfitsOwned,
        accessoriesOwned: stats.accessoriesOwned,
        loadoutsCreated: stats.loadoutsCreated,
        rareOrBetterItems: stats.rareOrBetterItems,
        legendaryCosmeticsOwned: stats.legendaryCosmeticsOwned,
        customizationsChanged: stats.customizationsChanged + 1,
        firstCustomizationAt: stats.firstCustomizationAt,
        lastCustomizationAt: now,
        lastUpdatedAt: now,
      );

      final updatedCollection = CharacterCustomizationCollection(
        userId: userId,
        activeLoadout: updatedActiveLoadout,
        loadouts: updatedLoadouts,
        allCosmetics: collection.allCosmetics,
        ownedCosmetics: collection.ownedCosmetics,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update appearance: $e');
    }
  }

  /// Equip outfit cosmetic
  Future<void> equipOutfit(String userId, String cosmeticId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      // Check if owned
      final ownedCosmetic = collection.ownedCosmetics.firstWhere(
        (o) => o.cosmeticId == cosmeticId && o.userId == userId,
        orElse: () => throw Exception('Cosmetic not owned'),
      );

      // Get cosmetic to verify it's an outfit
      final cosmetic = collection.allCosmetics.firstWhere(
        (c) => c.cosmeticId == cosmeticId,
        orElse: () => throw Exception('Cosmetic not found'),
      );

      if (cosmetic.outfitType == null) {
        throw Exception('Not an outfit');
      }

      // Update active loadout
      final updatedActiveLoadout = CharacterLoadout(
        loadoutId: collection.activeLoadout.loadoutId,
        userId: userId,
        loadoutName: collection.activeLoadout.loadoutName,
        appearance: collection.activeLoadout.appearance,
        equippedOutfitId: cosmeticId,
        equippedAccessories: collection.activeLoadout.equippedAccessories,
        createdAt: collection.activeLoadout.createdAt,
        lastUsedAt: now,
        isFavorite: collection.activeLoadout.isFavorite,
      );

      // Update owned cosmetic
      final updatedOwnedCosmetics = collection.ownedCosmetics.map((o) {
        if (o.ownedCosmeticId == ownedCosmetic.ownedCosmeticId) {
          return OwnedCosmetic(
            ownedCosmeticId: o.ownedCosmeticId,
            userId: o.userId,
            cosmeticId: o.cosmeticId,
            isEquipped: true,
            acquiredAt: o.acquiredAt,
            lastEquippedAt: now,
            timesWorn: o.timesWorn + 1,
            metadata: o.metadata,
          );
        }
        return o;
      }).toList();

      // Update cosmetic play count
      final updatedCosmetics = collection.allCosmetics.map((c) {
        if (c.cosmeticId == cosmeticId) {
          return CosmeticItem(
            cosmeticId: c.cosmeticId,
            name: c.name,
            description: c.description,
            rarity: c.rarity,
            outfitType: c.outfitType,
            accessoryType: c.accessoryType,
            imageId: c.imageId,
            requiredLevel: c.requiredLevel,
            requiredTier: c.requiredTier,
            isHidden: c.isHidden,
            releasedAt: c.releasedAt,
            discontinuedAt: c.discontinuedAt,
            isLimited: c.isLimited,
            limitedUntil: c.limitedUntil,
            timesEquipped: c.timesEquipped + 1,
            metadata: c.metadata,
          );
        }
        return c;
      }).toList();

      final updatedLoadouts = collection.loadouts.map((l) {
        if (l.loadoutId == collection.activeLoadout.loadoutId) {
          return updatedActiveLoadout;
        }
        return l;
      }).toList();

      final updatedCollection = CharacterCustomizationCollection(
        userId: userId,
        activeLoadout: updatedActiveLoadout,
        loadouts: updatedLoadouts,
        allCosmetics: updatedCosmetics,
        ownedCosmetics: updatedOwnedCosmetics,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to equip outfit: $e');
    }
  }

  /// Equip accessory
  Future<void> equipAccessory(String userId, String cosmeticId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      // Check if owned
      final ownedCosmetic = collection.ownedCosmetics.firstWhere(
        (o) => o.cosmeticId == cosmeticId && o.userId == userId,
        orElse: () => throw Exception('Cosmetic not owned'),
      );

      // Get cosmetic to verify it's an accessory
      final cosmetic = collection.allCosmetics.firstWhere(
        (c) => c.cosmeticId == cosmeticId,
        orElse: () => throw Exception('Cosmetic not found'),
      );

      if (cosmetic.accessoryType == null) {
        throw Exception('Not an accessory');
      }

      // Check max accessories
      if (collection.activeLoadout.equippedAccessories.length >= 3) {
        throw Exception('Max accessories equipped');
      }

      // Update active loadout
      final newAccessories = [
        ...collection.activeLoadout.equippedAccessories,
        cosmeticId
      ];

      final updatedActiveLoadout = CharacterLoadout(
        loadoutId: collection.activeLoadout.loadoutId,
        userId: userId,
        loadoutName: collection.activeLoadout.loadoutName,
        appearance: collection.activeLoadout.appearance,
        equippedOutfitId: collection.activeLoadout.equippedOutfitId,
        equippedAccessories: newAccessories,
        createdAt: collection.activeLoadout.createdAt,
        lastUsedAt: now,
        isFavorite: collection.activeLoadout.isFavorite,
      );

      // Update owned cosmetic
      final updatedOwnedCosmetics = collection.ownedCosmetics.map((o) {
        if (o.ownedCosmeticId == ownedCosmetic.ownedCosmeticId) {
          return OwnedCosmetic(
            ownedCosmeticId: o.ownedCosmeticId,
            userId: o.userId,
            cosmeticId: o.cosmeticId,
            isEquipped: true,
            acquiredAt: o.acquiredAt,
            lastEquippedAt: now,
            timesWorn: o.timesWorn + 1,
            metadata: o.metadata,
          );
        }
        return o;
      }).toList();

      final updatedLoadouts = collection.loadouts.map((l) {
        if (l.loadoutId == collection.activeLoadout.loadoutId) {
          return updatedActiveLoadout;
        }
        return l;
      }).toList();

      final updatedCollection = CharacterCustomizationCollection(
        userId: userId,
        activeLoadout: updatedActiveLoadout,
        loadouts: updatedLoadouts,
        allCosmetics: collection.allCosmetics,
        ownedCosmetics: updatedOwnedCosmetics,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to equip accessory: $e');
    }
  }

  /// Create new loadout
  Future<void> createLoadout(String userId, String loadoutName) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      if (collection.loadouts.length >= 10) {
        throw Exception('Max loadouts reached');
      }

      final newLoadout = CharacterLoadout(
        loadoutId: 'loadout_${now.millisecondsSinceEpoch}',
        userId: userId,
        loadoutName: loadoutName,
        appearance: collection.activeLoadout.appearance,
        equippedOutfitId: collection.activeLoadout.equippedOutfitId,
        equippedAccessories: collection.activeLoadout.equippedAccessories,
        createdAt: now,
        lastUsedAt: now,
      );

      final updatedLoadouts = [...collection.loadouts, newLoadout].take(10).toList();

      final stats = collection.statistics;
      final updatedStats = CustomizationStatistics(
        userId: userId,
        totalCosmeticsOwned: stats.totalCosmeticsOwned,
        outfitsOwned: stats.outfitsOwned,
        accessoriesOwned: stats.accessoriesOwned,
        loadoutsCreated: stats.loadoutsCreated + 1,
        rareOrBetterItems: stats.rareOrBetterItems,
        legendaryCosmeticsOwned: stats.legendaryCosmeticsOwned,
        customizationsChanged: stats.customizationsChanged,
        firstCustomizationAt: stats.firstCustomizationAt,
        lastCustomizationAt: stats.lastCustomizationAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = CharacterCustomizationCollection(
        userId: userId,
        activeLoadout: collection.activeLoadout,
        loadouts: updatedLoadouts,
        allCosmetics: collection.allCosmetics,
        ownedCosmetics: collection.ownedCosmetics,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create loadout: $e');
    }
  }

  /// Switch to loadout
  Future<void> switchLoadout(String userId, String loadoutId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final loadout = collection.loadouts.firstWhere(
        (l) => l.loadoutId == loadoutId,
        orElse: () => throw Exception('Loadout not found'),
      );

      final updatedLoadout = CharacterLoadout(
        loadoutId: loadout.loadoutId,
        userId: loadout.userId,
        loadoutName: loadout.loadoutName,
        appearance: loadout.appearance,
        equippedOutfitId: loadout.equippedOutfitId,
        equippedAccessories: loadout.equippedAccessories,
        createdAt: loadout.createdAt,
        lastUsedAt: now,
        isFavorite: loadout.isFavorite,
      );

      final updatedLoadouts = collection.loadouts.map((l) {
        if (l.loadoutId == loadoutId) {
          return updatedLoadout;
        }
        return l;
      }).toList();

      final updatedCollection = CharacterCustomizationCollection(
        userId: userId,
        activeLoadout: updatedLoadout,
        loadouts: updatedLoadouts,
        allCosmetics: collection.allCosmetics,
        ownedCosmetics: collection.ownedCosmetics,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch loadout: $e');
    }
  }

  /// Acquire cosmetic
  Future<void> acquireCosmetic(String userId, String cosmeticId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final cosmetic = collection.allCosmetics.firstWhere(
        (c) => c.cosmeticId == cosmeticId,
        orElse: () => throw Exception('Cosmetic not found'),
      );

      if (!cosmetic.isAvailable) {
        throw Exception('Cosmetic not available');
      }

      // Check if already owned
      final alreadyOwned = collection.ownedCosmetics
          .any((o) => o.cosmeticId == cosmeticId && o.userId == userId);

      if (alreadyOwned) {
        throw Exception('Already owned');
      }

      final ownedId = 'owned_${now.millisecondsSinceEpoch}_${(now.microsecond % 10000)}';
      final ownedCosmetic = OwnedCosmetic(
        ownedCosmeticId: ownedId,
        userId: userId,
        cosmeticId: cosmeticId,
        acquiredAt: now,
      );

      final updatedOwnedCosmetics = [...collection.ownedCosmetics, ownedCosmetic]
          .take(500)
          .toList();

      final stats = collection.statistics;
      int outfitsOwned = stats.outfitsOwned;
      int accessoriesOwned = stats.accessoriesOwned;
      int rareOrBetter = stats.rareOrBetterItems;
      int legendaryOwned = stats.legendaryCosmeticsOwned;

      if (cosmetic.outfitType != null) outfitsOwned++;
      if (cosmetic.accessoryType != null) accessoriesOwned++;
      if (cosmetic.rarity.index >= CosmeticRarity.rare.index) rareOrBetter++;
      if (cosmetic.rarity == CosmeticRarity.legendary ||
          cosmetic.rarity == CosmeticRarity.mythic) legendaryOwned++;

      final updatedStats = CustomizationStatistics(
        userId: userId,
        totalCosmeticsOwned: stats.totalCosmeticsOwned + 1,
        outfitsOwned: outfitsOwned,
        accessoriesOwned: accessoriesOwned,
        loadoutsCreated: stats.loadoutsCreated,
        rareOrBetterItems: rareOrBetter,
        legendaryCosmeticsOwned: legendaryOwned,
        customizationsChanged: stats.customizationsChanged,
        firstCustomizationAt: stats.firstCustomizationAt,
        lastCustomizationAt: stats.lastCustomizationAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = CharacterCustomizationCollection(
        userId: userId,
        activeLoadout: collection.activeLoadout,
        loadouts: collection.loadouts,
        allCosmetics: collection.allCosmetics,
        ownedCosmetics: updatedOwnedCosmetics,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to acquire cosmetic: $e');
    }
  }

  /// Persist to SharedPreferences
  Future<void> _persist(String userId, CharacterCustomizationCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'customization_$userId',
      jsonEncode(collection.toJson()),
    );
  }

  /// Create default appearance
  CharacterAppearance _createDefaultAppearance(String userId, DateTime now) {
    return CharacterAppearance(
      appearanceId: 'app_${now.millisecondsSinceEpoch}',
      userId: userId,
      gender: CharacterGender.nonBinary,
      headStyle: HeadStyle.round,
      eyeColor: EyeColor.brown,
      hairStyle: HairStyle.medium,
      hairColor: HairColor.black,
      skinTone: SkinTone.medium,
    );
  }

  /// Create default loadout
  CharacterLoadout _createDefaultLoadout(
    String userId,
    CharacterAppearance appearance,
    DateTime now,
  ) {
    return CharacterLoadout(
      loadoutId: 'loadout_${now.millisecondsSinceEpoch}',
      userId: userId,
      loadoutName: 'デフォルト',
      appearance: appearance,
      createdAt: now,
      lastUsedAt: now,
    );
  }

  /// Create default cosmetics
  List<CosmeticItem> _createDefaultCosmetics(DateTime now) {
    final cosmetics = <CosmeticItem>[];

    // School uniform outfit
    cosmetics.add(CosmeticItem(
      cosmeticId: 'outfit_school_1',
      name: '学校制服',
      description: 'クラシックな学校制服',
      rarity: CosmeticRarity.common,
      outfitType: OutfitType.school,
      releasedAt: now,
    ));

    // Casual outfit
    cosmetics.add(CosmeticItem(
      cosmeticId: 'outfit_casual_1',
      name: 'カジュアル',
      description: 'カジュアルな服装',
      rarity: CosmeticRarity.common,
      outfitType: OutfitType.casual,
      releasedAt: now,
    ));

    // Sports outfit
    cosmetics.add(CosmeticItem(
      cosmeticId: 'outfit_sports_1',
      name: 'スポーツウェア',
      description: 'スポーツ用衣装',
      rarity: CosmeticRarity.uncommon,
      outfitType: OutfitType.sports,
      releasedAt: now,
    ));

    // Formal outfit
    cosmetics.add(CosmeticItem(
      cosmeticId: 'outfit_formal_1',
      name: 'フォーマル',
      description: 'フォーマルな衣装',
      rarity: CosmeticRarity.rare,
      outfitType: OutfitType.formal,
      releasedAt: now,
    ));

    // Fantasy outfit
    cosmetics.add(CosmeticItem(
      cosmeticId: 'outfit_fantasy_1',
      name: 'ファンタジー',
      description: 'ファンタジー風衣装',
      rarity: CosmeticRarity.epic,
      outfitType: OutfitType.fantasy,
      releasedAt: now,
    ));

    // Hat accessory
    cosmetics.add(CosmeticItem(
      cosmeticId: 'accessory_hat_1',
      name: '帽子',
      description: 'シンプルな帽子',
      rarity: CosmeticRarity.common,
      accessoryType: AccessoryType.hat,
      releasedAt: now,
    ));

    // Glasses accessory
    cosmetics.add(CosmeticItem(
      cosmeticId: 'accessory_glasses_1',
      name: 'メガネ',
      description: 'クラシックメガネ',
      rarity: CosmeticRarity.uncommon,
      accessoryType: AccessoryType.glasses,
      releasedAt: now,
    ));

    // Necklace accessory
    cosmetics.add(CosmeticItem(
      cosmeticId: 'accessory_necklace_1',
      name: 'ネックレス',
      description: 'ゴールドネックレス',
      rarity: CosmeticRarity.rare,
      accessoryType: AccessoryType.necklace,
      releasedAt: now,
    ));

    // Legendary outfit
    cosmetics.add(CosmeticItem(
      cosmeticId: 'outfit_legendary_1',
      name: 'レジェンド服',
      description: 'レアなレジェンド衣装',
      rarity: CosmeticRarity.legendary,
      outfitType: OutfitType.futuristic,
      releasedAt: now,
    ));

    return cosmetics;
  }
}

// Riverpod providers
final customizationProvider =
    StateNotifierProvider<CharacterCustomizationNotifier, CharacterCustomizationState>((ref) {
  return CharacterCustomizationNotifier();
});

final customizationCollectionProvider =
    Provider<CharacterCustomizationCollection?>((ref) {
  final state = ref.watch(customizationProvider);
  return state.collection;
});

final activeLoadoutProvider = Provider<CharacterLoadout?>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.activeLoadout;
});

final activeAppearanceProvider = Provider<CharacterAppearance?>((ref) {
  final loadout = ref.watch(activeLoadoutProvider);
  return loadout?.appearance;
});

final allCosmeticsProvider = Provider<List<CosmeticItem>>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.allCosmetics ?? [];
});

final availableCosmeticsProvider = Provider<List<CosmeticItem>>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.getAvailableCosmetics() ?? [];
});

final featuredCosmeticsProvider = Provider<List<CosmeticItem>>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.getFeaturedCosmetics() ?? [];
});

final ownedCosmeticsProvider = Provider<List<OwnedCosmetic>>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.ownedCosmetics ?? [];
});

final ownedOutfitsProvider = Provider<List<OwnedCosmetic>>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.getOwnedOutfits() ?? [];
});

final ownedAccessoriesProvider = Provider<List<OwnedCosmetic>>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.getOwnedAccessories() ?? [];
});

final customizationStatisticsProvider = Provider<CustomizationStatistics?>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.statistics;
});

final customizationTierProvider = Provider<String>((ref) {
  final stats = ref.watch(customizationStatisticsProvider);
  return stats?.getCustomizationTier() ?? '初期段階';
});

final loadoutsProvider = Provider<List<CharacterLoadout>>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.loadouts ?? [];
});

final totalCosmeticsOwnedProvider = Provider<int>((ref) {
  final stats = ref.watch(customizationStatisticsProvider);
  return stats?.totalCosmeticsOwned ?? 0;
});

final legendaryCosmeticsProvider = Provider<List<OwnedCosmetic>>((ref) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.getLegendaryCosmeticsOwned() ?? [];
});

final cosmeticsByRarityProvider =
    Provider.family<List<CosmeticItem>, CosmeticRarity>((ref, rarity) {
  final collection = ref.watch(customizationCollectionProvider);
  return collection?.getCosmeticsByRarity(rarity) ?? [];
});
