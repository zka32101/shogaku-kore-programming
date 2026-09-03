import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/reward_shop.dart';

class ShopState {
  final ShopCatalog? catalog;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;
  final List<String> recentPurchases;  // Purchase IDs completed in this session

  ShopState({
    this.catalog,
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
    this.recentPurchases = const [],
  });

  ShopState copyWith({
    ShopCatalog? catalog,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
    List<String>? recentPurchases,
  }) =>
      ShopState(
        catalog: catalog ?? this.catalog,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        recentPurchases: recentPurchases ?? this.recentPurchases,
      );
}

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier() : super(ShopState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// Generate default shop items
  List<ShopItem> _generateShopItems() {
    final now = DateTime.now();
    return [
      // Badge cosmetics
      ShopItem(
        itemId: 'badge_streak_7',
        name: '7日連続バッジ',
        description: '7日間連続ログインの証',
        type: ShopItemType.badge,
        rarity: ItemRarity.uncommon,
        iconId: 'icon_badge_7day',
        xpCost: 100,
        coinCost: 50,
        premiumCost: 0,
        purchaseLimit: 1,
        currentStock: -1,
        isFeatured: true,
      ),
      ShopItem(
        itemId: 'badge_streak_30',
        name: '30日連続バッジ',
        description: '30日間連続ログインの証',
        type: ShopItemType.badge,
        rarity: ItemRarity.rare,
        iconId: 'icon_badge_30day',
        xpCost: 300,
        coinCost: 150,
        premiumCost: 500,
        purchaseLimit: 1,
        currentStock: -1,
      ),
      ShopItem(
        itemId: 'badge_master_learner',
        name: 'マスターラーナーバッジ',
        description: '1000XP達成記念',
        type: ShopItemType.badge,
        rarity: ItemRarity.epic,
        iconId: 'icon_badge_learner',
        xpCost: 500,
        coinCost: 250,
        premiumCost: 1000,
        purchaseLimit: 1,
        currentStock: -1,
        isNew: true,
      ),
      // Theme customizations
      ShopItem(
        itemId: 'theme_dark_forest',
        name: 'ダークフォレスト',
        description: '落ち着いた緑色のテーマ',
        type: ShopItemType.theme,
        rarity: ItemRarity.common,
        iconId: 'icon_theme_forest',
        xpCost: 50,
        coinCost: 25,
        premiumCost: 0,
        purchaseLimit: -1,
        currentStock: -1,
        isFeatured: true,
      ),
      ShopItem(
        itemId: 'theme_neon_night',
        name: 'ネオンナイト',
        description: 'サイバーパンク風テーマ',
        type: ShopItemType.theme,
        rarity: ItemRarity.uncommon,
        iconId: 'icon_theme_neon',
        xpCost: 150,
        coinCost: 75,
        premiumCost: 300,
        purchaseLimit: -1,
        currentStock: -1,
        isNew: true,
      ),
      ShopItem(
        itemId: 'theme_sakura_spring',
        name: '桜の春',
        description: '日本の春をテーマにしたカラフルなテーマ',
        type: ShopItemType.theme,
        rarity: ItemRarity.rare,
        iconId: 'icon_theme_sakura',
        xpCost: 250,
        coinCost: 125,
        premiumCost: 500,
        purchaseLimit: -1,
        currentStock: -1,
      ),
      // Avatar cosmetics
      ShopItem(
        itemId: 'avatar_ninja_blue',
        name: 'ブルーニンジャ',
        description: '青いニンジャアバター',
        type: ShopItemType.avatar,
        rarity: ItemRarity.uncommon,
        iconId: 'icon_avatar_ninja_blue',
        xpCost: 80,
        coinCost: 40,
        premiumCost: 200,
        purchaseLimit: -1,
        currentStock: -1,
      ),
      ShopItem(
        itemId: 'avatar_wizard_gold',
        name: 'ゴールドウィザード',
        description: '魔法使いアバター（ゴールド）',
        type: ShopItemType.avatar,
        rarity: ItemRarity.epic,
        iconId: 'icon_avatar_wizard',
        xpCost: 400,
        coinCost: 200,
        premiumCost: 1500,
        purchaseLimit: -1,
        currentStock: -1,
        isNew: true,
      ),
      // Power-ups
      ShopItem(
        itemId: 'powerup_double_xp',
        name: 'ダブルXP（1時間）',
        description: '1時間XPを2倍獲得',
        type: ShopItemType.powerup,
        rarity: ItemRarity.uncommon,
        iconId: 'icon_powerup_xp',
        xpCost: 0,
        coinCost: 100,
        premiumCost: 100,
        purchaseLimit: -1,
        currentStock: -1,
      ),
      ShopItem(
        itemId: 'powerup_challenge_reset',
        name: 'チャレンジリセット',
        description: 'チャレンジの進捗をリセット',
        type: ShopItemType.powerup,
        rarity: ItemRarity.rare,
        iconId: 'icon_powerup_reset',
        xpCost: 200,
        coinCost: 0,
        premiumCost: 200,
        purchaseLimit: -1,
        currentStock: 5,
        availableUntil: now.add(const Duration(days: 7)),
      ),
      // Bundle
      ShopItem(
        itemId: 'bundle_starter_pack',
        name: 'スターターパック',
        description: 'バッジ＋テーマ＋アバター',
        type: ShopItemType.bundle,
        rarity: ItemRarity.rare,
        iconId: 'icon_bundle_starter',
        xpCost: 300,
        coinCost: 150,
        premiumCost: 800,
        purchaseLimit: 1,
        currentStock: -1,
        isFeatured: true,
      ),
    ];
  }

  /// Initialize shop catalog
  Future<void> initializeShop(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final inventoryJson = prefs.getString('shop_inventory_$userId');
      final statsJson = prefs.getString('shop_stats_$userId');

      late UserInventory inventory;
      late ShopStats stats;
      final now = DateTime.now();

      if (inventoryJson != null && statsJson != null) {
        inventory = UserInventory.fromJson(
          Map<String, dynamic>.from(inventoryJson as Map),
        );
        stats = ShopStats.fromJson(
          Map<String, dynamic>.from(statsJson as Map),
        );
      } else {
        inventory = UserInventory(
          userId: userId,
          ownedItems: {},
          purchaseCount: {},
          purchaseHistory: [],
          lastUpdatedAt: now,
        );
        stats = ShopStats(
          userId: userId,
          totalXpSpent: 0,
          totalCoinsSpent: 0,
          totalPremiumSpent: 0,
          totalPurchases: 0,
          totalItemsOwned: 0,
          firstPurchaseDate: now,
          lastPurchaseDate: now,
          lastUpdatedAt: now,
        );
      }

      final items = _generateShopItems();
      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      state = state.copyWith(
        catalog: catalog,
        isLoading: false,
        lastUpdatedAt: now,
      );

      await _persistShop(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Purchase an item
  Future<bool> purchaseItem(
    String userId,
    String itemId,
    CurrencyType currency,
    {int quantity = 1, String? giftToUserId}
  ) async {
    try {
      final catalog = state.catalog;
      if (catalog == null) return false;

      final item = catalog.getItem(itemId);

      // Check if available
      if (!item.isAvailable) return false;

      // Check purchase limit
      final timesOwned = catalog.inventory.getPurchaseCount(itemId);
      if (item.purchaseLimit > 0 && timesOwned >= item.purchaseLimit) {
        return false;
      }

      // Calculate cost
      int cost = 0;
      switch (currency) {
        case CurrencyType.xp:
          cost = item.xpCost;
          break;
        case CurrencyType.coins:
          cost = item.coinCost;
          break;
        case CurrencyType.premium:
          cost = item.premiumCost;
          break;
      }

      if (cost == 0) return false;

      // Create purchase record
      final purchaseRecord = PurchaseRecord(
        purchaseId: _generateId('shop_purchase'),
        userId: userId,
        itemId: itemId,
        quantityPurchased: quantity,
        costPaid: cost * quantity,
        currencyUsed: currency,
        purchasedAt: DateTime.now(),
        isGift: giftToUserId != null,
        giftFromUserId: giftToUserId,
      );

      // Update inventory
      final newOwnedItems = Map<String, int>.from(catalog.inventory.ownedItems);
      newOwnedItems[itemId] = (newOwnedItems[itemId] ?? 0) + quantity;

      final newPurchaseCount = Map<String, int>.from(catalog.inventory.purchaseCount);
      newPurchaseCount[itemId] = (newPurchaseCount[itemId] ?? 0) + 1;

      final newPurchaseHistory = [
        purchaseRecord,
        ...catalog.inventory.purchaseHistory,
      ].take(100).toList();

      final updatedInventory = UserInventory(
        userId: catalog.inventory.userId,
        ownedItems: newOwnedItems,
        purchaseCount: newPurchaseCount,
        purchaseHistory: newPurchaseHistory,
        lastUpdatedAt: DateTime.now(),
      );

      // Update stats
      int xpSpent = 0, coinSpent = 0, premiumSpent = 0;
      switch (currency) {
        case CurrencyType.xp:
          xpSpent = cost * quantity;
          break;
        case CurrencyType.coins:
          coinSpent = cost * quantity;
          break;
        case CurrencyType.premium:
          premiumSpent = cost * quantity;
          break;
      }

      final updatedStats = ShopStats(
        userId: catalog.stats.userId,
        totalXpSpent: catalog.stats.totalXpSpent + xpSpent,
        totalCoinsSpent: catalog.stats.totalCoinsSpent + coinSpent,
        totalPremiumSpent: catalog.stats.totalPremiumSpent + premiumSpent,
        totalPurchases: catalog.stats.totalPurchases + 1,
        totalItemsOwned: newOwnedItems.values.fold(0, (sum, count) => sum + count),
        firstPurchaseDate: catalog.stats.firstPurchaseDate,
        lastPurchaseDate: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      final updatedCatalog = ShopCatalog(
        allItems: catalog.allItems,
        inventory: updatedInventory,
        stats: updatedStats,
        generatedAt: DateTime.now(),
      );

      final newRecentPurchases = [...state.recentPurchases, purchaseRecord.purchaseId];

      state = state.copyWith(
        catalog: updatedCatalog,
        recentPurchases: newRecentPurchases,
      );

      await _persistShop(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Refund a purchase
  Future<bool> refundPurchase(String userId, String purchaseId) async {
    try {
      final catalog = state.catalog;
      if (catalog == null) return false;

      final purchase = catalog.inventory.purchaseHistory
          .firstWhere((p) => p.purchaseId == purchaseId, orElse: () => throw Exception('Purchase not found'));

      // Remove from history
      final newHistory = catalog.inventory.purchaseHistory
          .where((p) => p.purchaseId != purchaseId)
          .toList();

      // Update owned items
      final newOwnedItems = Map<String, int>.from(catalog.inventory.ownedItems);
      newOwnedItems[purchase.itemId] = (newOwnedItems[purchase.itemId] ?? 0) - purchase.quantityPurchased;
      if (newOwnedItems[purchase.itemId]! <= 0) {
        newOwnedItems.remove(purchase.itemId);
      }

      final updatedInventory = UserInventory(
        userId: catalog.inventory.userId,
        ownedItems: newOwnedItems,
        purchaseCount: catalog.inventory.purchaseCount,
        purchaseHistory: newHistory,
        lastUpdatedAt: DateTime.now(),
      );

      // Update stats
      int xpRefund = 0, coinRefund = 0, premiumRefund = 0;
      switch (purchase.currencyUsed) {
        case CurrencyType.xp:
          xpRefund = purchase.costPaid;
          break;
        case CurrencyType.coins:
          coinRefund = purchase.costPaid;
          break;
        case CurrencyType.premium:
          premiumRefund = purchase.costPaid;
          break;
      }

      final updatedStats = ShopStats(
        userId: catalog.stats.userId,
        totalXpSpent: (catalog.stats.totalXpSpent - xpRefund).clamp(0, double.infinity).toInt(),
        totalCoinsSpent: (catalog.stats.totalCoinsSpent - coinRefund).clamp(0, double.infinity).toInt(),
        totalPremiumSpent: (catalog.stats.totalPremiumSpent - premiumRefund).clamp(0, double.infinity).toInt(),
        totalPurchases: catalog.stats.totalPurchases - 1,
        totalItemsOwned: newOwnedItems.values.fold(0, (sum, count) => sum + count),
        firstPurchaseDate: catalog.stats.firstPurchaseDate,
        lastPurchaseDate: catalog.stats.lastPurchaseDate,
        lastUpdatedAt: DateTime.now(),
      );

      final updatedCatalog = ShopCatalog(
        allItems: catalog.allItems,
        inventory: updatedInventory,
        stats: updatedStats,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(catalog: updatedCatalog);
      await _persistShop(userId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get recommended items (featured + new + user can afford)
  List<ShopItem> getRecommendedItems(int currentXp, int currentCoins) {
    final catalog = state.catalog;
    if (catalog == null) return [];

    return catalog.allItems
        .where((item) =>
            (item.isFeatured || item.isNew) &&
            item.isAvailable &&
            ((item.xpCost > 0 && item.xpCost <= currentXp) ||
             (item.coinCost > 0 && item.coinCost <= currentCoins)))
        .toList();
  }

  /// Clear recently purchased
  void clearRecentPurchases() {
    state = state.copyWith(recentPurchases: []);
  }

  Future<void> _persistShop(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final catalog = state.catalog;
      if (catalog != null) {
        await prefs.setString(
          'shop_inventory_$userId',
          catalog.inventory.toJson().toString(),
        );
        await prefs.setString(
          'shop_stats_$userId',
          catalog.stats.toJson().toString(),
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  int getTotalSpent() => state.catalog?.stats.getTotalSpent() ?? 0;
  int getTotalPurchases() => state.catalog?.stats.totalPurchases ?? 0;
  int getTotalItemsOwned() => state.catalog?.stats.totalItemsOwned ?? 0;
}

final shopProvider = StateNotifierProvider.autoDispose<ShopNotifier, ShopState>(
  (ref) => ShopNotifier(),
);

final shopCatalogProvider = Provider.autoDispose<ShopCatalog?>(
  (ref) => ref.watch(shopProvider).catalog,
);

final userInventoryProvider = Provider.autoDispose<UserInventory?>(
  (ref) => ref.watch(shopProvider).catalog?.inventory,
);

final shopStatsProvider = Provider.autoDispose<ShopStats?>(
  (ref) => ref.watch(shopProvider).catalog?.stats,
);

final availableItemsProvider = Provider.autoDispose<List<ShopItem>>(
  (ref) => ref.watch(shopProvider).catalog?.getAvailableItems() ?? [],
);

final featuredItemsProvider = Provider.autoDispose<List<ShopItem>>(
  (ref) => ref.watch(shopProvider).catalog?.getFeaturedItems() ?? [],
);

final newItemsProvider = Provider.autoDispose<List<ShopItem>>(
  (ref) => ref.watch(shopProvider).catalog?.getNewItems() ?? [],
);
