import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/shop_store.dart';

/// Shop state
class ShopState {
  final ShopCollection? collection;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  ShopState({
    this.collection,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  ShopState copyWith({
    ShopCollection? collection,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      ShopState(
        collection: collection ?? this.collection,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

/// Shop notifier
class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier() : super(ShopState());

  /// Initialize shop
  Future<void> initializeShop(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'shop_$userId';

      final stored = prefs.getString(key);
      if (stored != null) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        state = state.copyWith(
          collection: ShopCollection.fromJson(json),
          isLoading: false,
          lastUpdatedAt: DateTime.now(),
        );
        return;
      }

      final now = DateTime.now();
      final defaultItems = _createDefaultShopItems(now);

      final collection = ShopCollection(
        userId: userId,
        allItems: defaultItems,
        ownedItems: [],
        transactions: [],
        statistics: ShopStatistics(
          userId: userId,
          firstPurchaseAt: now,
          lastPurchaseAt: now,
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
        error: 'Failed to initialize shop: $e',
      );
    }
  }

  /// Purchase item
  Future<void> purchaseItem(
    String userId,
    String itemId,
    int quantity,
    String currencyType, // 'coin' or 'premiumCoin'
  ) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final item = collection.allItems.firstWhere(
        (i) => i.itemId == itemId,
        orElse: () => throw Exception('Item not found'),
      );

      if (!item.isAvailable) throw Exception('Item not available');

      // Check if user can use this currency
      if (currencyType == 'coin' && item.coinPrice == 0) {
        throw Exception('Item not available for coins');
      }
      if (currencyType == 'premiumCoin' && item.premiumCoinPrice == null) {
        throw Exception('Item not available for premium coins');
      }

      final price = currencyType == 'coin' ? item.coinPrice : item.premiumCoinPrice!;
      final totalPrice = price * quantity;

      final now = DateTime.now();
      final ownedItemId = 'oi_${now.millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';

      // Calculate expiration for timed items
      DateTime? expiresAt;
      if (item.durationMinutes != null) {
        expiresAt = now.add(Duration(minutes: item.durationMinutes!));
      }

      final ownedItem = OwnedItem(
        ownedItemId: ownedItemId,
        itemId: itemId,
        userId: userId,
        quantity: quantity,
        purchasedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        purchasePrice: price,
        purchaseCurrency: currencyType,
      );

      final transactionId = 'tx_${now.millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
      final transaction = PurchaseTransaction(
        transactionId: transactionId,
        userId: userId,
        itemId: itemId,
        itemName: item.name,
        quantity: quantity,
        amountSpent: totalPrice,
        currencyUsed: currencyType,
        purchasedAt: now,
        status: 'completed',
      );

      final updatedItems = [...collection.allItems];
      final itemIndex = updatedItems.indexWhere((i) => i.itemId == itemId);
      if (itemIndex >= 0) {
        updatedItems[itemIndex] = ShopItem(
          itemId: item.itemId,
          name: item.name,
          description: item.description,
          category: item.category,
          rarity: item.rarity,
          imageId: item.imageId,
          coinPrice: item.coinPrice,
          premiumCoinPrice: item.premiumCoinPrice,
          acceptedCurrency: item.acceptedCurrency,
          durationMinutes: item.durationMinutes,
          effectDescription: item.effectDescription,
          maxStackable: item.maxStackable,
          isLimited: item.isLimited,
          limitedUntil: item.limitedUntil,
          salesCount: item.salesCount + quantity,
          averageRating: item.averageRating,
          reviewCount: item.reviewCount,
          addedAt: item.addedAt,
          metadata: item.metadata,
        );
      }

      final updatedOwnedItems = [...collection.ownedItems, ownedItem];
      final updatedTransactions = [...collection.transactions, transaction];

      final stats = collection.statistics;
      final spentAmount = currencyType == 'coin'
          ? stats.totalCoinSpent + totalPrice
          : stats.totalPremiumCoinSpent + totalPrice;

      final updatedStats = ShopStatistics(
        userId: userId,
        totalPurchases: stats.totalPurchases + 1,
        totalSpent: stats.totalSpent + totalPrice,
        totalCoinSpent:
            currencyType == 'coin' ? stats.totalCoinSpent + totalPrice : stats.totalCoinSpent,
        totalPremiumCoinSpent: currencyType == 'premiumCoin'
            ? stats.totalPremiumCoinSpent + totalPrice
            : stats.totalPremiumCoinSpent,
        uniqueItemsOwned: stats.uniqueItemsOwned + 1,
        cosmecticItemsOwned: item.category == ItemCategory.cosmetic
            ? stats.cosmecticItemsOwned + 1
            : stats.cosmecticItemsOwned,
        powerupsOwned: item.category == ItemCategory.powerup
            ? stats.powerupsOwned + 1
            : stats.powerupsOwned,
        consumablesUsed: stats.consumablesUsed,
        firstPurchaseAt: stats.firstPurchaseAt,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );

      final updatedCollection = ShopCollection(
        userId: userId,
        allItems: updatedItems.take(200).toList(),
        ownedItems: updatedOwnedItems.take(1000).toList(),
        transactions: updatedTransactions.take(500).toList(),
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to purchase item: $e');
    }
  }

  /// Activate power-up
  Future<void> activatePowerup(String userId, String ownedItemId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedOwnedItems = collection.ownedItems.map((item) {
        if (item.ownedItemId == ownedItemId) {
          return OwnedItem(
            ownedItemId: item.ownedItemId,
            itemId: item.itemId,
            userId: item.userId,
            quantity: item.quantity,
            purchasedAt: item.purchasedAt,
            expiresAt: item.expiresAt ?? now.add(const Duration(hours: 1)),
            isActive: true,
            purchasePrice: item.purchasePrice,
            purchaseCurrency: item.purchaseCurrency,
          );
        }
        return item;
      }).toList();

      final updatedCollection = ShopCollection(
        userId: userId,
        allItems: collection.allItems,
        ownedItems: updatedOwnedItems,
        transactions: collection.transactions,
        statistics: collection.statistics,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to activate power-up: $e');
    }
  }

  /// Use consumable item
  Future<void> useConsumable(String userId, String ownedItemId) async {
    if (state.collection == null) return;

    try {
      final collection = state.collection!;
      final now = DateTime.now();

      final updatedOwnedItems = collection.ownedItems
          .where((item) => item.ownedItemId != ownedItemId)
          .toList();

      final stats = collection.statistics;
      final updatedStats = ShopStatistics(
        userId: userId,
        totalPurchases: stats.totalPurchases,
        totalSpent: stats.totalSpent,
        totalCoinSpent: stats.totalCoinSpent,
        totalPremiumCoinSpent: stats.totalPremiumCoinSpent,
        uniqueItemsOwned: stats.uniqueItemsOwned,
        cosmecticItemsOwned: stats.cosmecticItemsOwned,
        powerupsOwned: stats.powerupsOwned,
        consumablesUsed: stats.consumablesUsed + 1,
        firstPurchaseAt: stats.firstPurchaseAt,
        lastPurchaseAt: stats.lastPurchaseAt,
        lastUpdatedAt: now,
      );

      final updatedCollection = ShopCollection(
        userId: userId,
        allItems: collection.allItems,
        ownedItems: updatedOwnedItems,
        transactions: collection.transactions,
        statistics: updatedStats,
        generatedAt: collection.generatedAt,
      );

      await _persist(userId, updatedCollection);
      state = state.copyWith(collection: updatedCollection, lastUpdatedAt: now);
    } catch (e) {
      state = state.copyWith(error: 'Failed to use consumable: $e');
    }
  }

  /// Persist to SharedPreferences
  Future<void> _persist(String userId, ShopCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'shop_$userId',
      jsonEncode(collection.toJson()),
    );
  }

  /// Create default shop items
  List<ShopItem> _createDefaultShopItems(DateTime now) {
    final items = <ShopItem>[];

    // Cosmetics
    items.add(ShopItem(
      itemId: 'cosmetic_avatar_1',
      name: 'かわいいロボット',
      description: 'キュートなロボットアバター',
      category: ItemCategory.cosmetic,
      rarity: ItemRarity.common,
      coinPrice: 500,
      premiumCoinPrice: 5,
      acceptedCurrency: CurrencyType.both,
      addedAt: now,
    ));

    items.add(ShopItem(
      itemId: 'cosmetic_theme_dark',
      name: 'ダークテーマ',
      description: 'ダークモード UI テーマ',
      category: ItemCategory.cosmetic,
      rarity: ItemRarity.uncommon,
      coinPrice: 1000,
      premiumCoinPrice: 10,
      acceptedCurrency: CurrencyType.both,
      addedAt: now,
    ));

    // Power-ups
    items.add(ShopItem(
      itemId: 'powerup_2x_xp',
      name: '2倍 XP ブースター',
      description: '1時間、XPを2倍獲得',
      category: ItemCategory.powerup,
      rarity: ItemRarity.rare,
      coinPrice: 2000,
      premiumCoinPrice: 20,
      acceptedCurrency: CurrencyType.both,
      durationMinutes: 60,
      effectDescription: 'XP x2 for 1 hour',
      addedAt: now,
    ));

    items.add(ShopItem(
      itemId: 'powerup_streak_protect',
      name: 'ストリーク保護',
      description: '1日逃してもストリークが保護される',
      category: ItemCategory.powerup,
      rarity: ItemRarity.epic,
      coinPrice: 3000,
      premiumCoinPrice: 30,
      acceptedCurrency: CurrencyType.both,
      durationMinutes: 1440, // 24 hours
      effectDescription: 'Protects streak for 1 missed day',
      addedAt: now,
    ));

    // Boosters
    items.add(ShopItem(
      itemId: 'booster_coin_generator',
      name: 'コイン発電機',
      description: '毎日100コイン獲得',
      category: ItemCategory.booster,
      rarity: ItemRarity.legendary,
      premiumCoinPrice: 50,
      acceptedCurrency: CurrencyType.premiumCoin,
      durationMinutes: 10080, // 7 days
      effectDescription: '+100 coins daily',
      addedAt: now,
    ));

    // Consumables
    items.add(ShopItem(
      itemId: 'consumable_lucky_ticket',
      name: 'ラッキーチケット',
      description: '1回、ボーナスコインを獲得するチャンス',
      category: ItemCategory.consumable,
      rarity: ItemRarity.uncommon,
      coinPrice: 500,
      premiumCoinPrice: 5,
      acceptedCurrency: CurrencyType.both,
      maxStackable: 99,
      addedAt: now,
    ));

    // Limited item
    items.add(ShopItem(
      itemId: 'special_sakura_badge',
      name: '桜バッジ',
      description: '春の季節限定バッジ',
      category: ItemCategory.badge,
      rarity: ItemRarity.legendary,
      coinPrice: 5000,
      premiumCoinPrice: 50,
      acceptedCurrency: CurrencyType.both,
      isLimited: true,
      limitedUntil: now.add(const Duration(days: 7)),
      addedAt: now,
    ));

    return items;
  }
}

// Riverpod providers
final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  return ShopNotifier();
});

final shopCollectionProvider = Provider<ShopCollection?>((ref) {
  final state = ref.watch(shopProvider);
  return state.collection;
});

final allShopItemsProvider = Provider<List<ShopItem>>((ref) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.allItems ?? [];
});

final availableItemsProvider = Provider<List<ShopItem>>((ref) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.getAvailableItems() ?? [];
});

final featuredItemsProvider = Provider<List<ShopItem>>((ref) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.getFeaturedItems() ?? [];
});

final itemsByCategoryProvider =
    Provider.family<List<ShopItem>, ItemCategory>((ref, category) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.getItemsByCategory(category) ?? [];
});

final itemsByRarityProvider = Provider.family<List<ShopItem>, ItemRarity>((ref, rarity) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.getItemsByRarity(rarity) ?? [];
});

final ownedItemsProvider = Provider<List<OwnedItem>>((ref) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.ownedItems ?? [];
});

final activePowerupsProvider = Provider<List<OwnedItem>>((ref) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.getActivePowerups() ?? [];
});

final ownedCosmeticsProvider = Provider<List<OwnedItem>>((ref) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.getOwnedCosmetics() ?? [];
});

final shopStatisticsProvider = Provider<ShopStatistics?>((ref) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.statistics;
});

final spenderTierProvider = Provider<String>((ref) {
  final stats = ref.watch(shopStatisticsProvider);
  return stats?.getSpenderTier() ?? 'ブラウザー';
});

final transactionHistoryProvider = Provider<List<PurchaseTransaction>>((ref) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.transactions ?? [];
});

final recentPurchasesProvider =
    Provider.family<List<PurchaseTransaction>, int>((ref, days) {
  final collection = ref.watch(shopCollectionProvider);
  return collection?.getRecentPurchases(days: days) ?? [];
});

final totalSpentProvider = Provider<int>((ref) {
  final stats = ref.watch(shopStatisticsProvider);
  return stats?.totalSpent ?? 0;
});

final uniqueItemsOwnedProvider = Provider<int>((ref) {
  final stats = ref.watch(shopStatisticsProvider);
  return stats?.uniqueItemsOwned ?? 0;
});

final searchShopItemsProvider =
    Provider.family<List<ShopItem>, String>((ref, query) {
  final items = ref.watch(allShopItemsProvider);
  return items
      .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
});
