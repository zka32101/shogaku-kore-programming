import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/reward_shop.dart';

void main() {
  group('ShopItem', () {
    test('creates instance with all required fields', () {
      final item = ShopItem(
        itemId: 'badge_7day',
        name: '7日バッジ',
        description: '7日連続ログイン',
        type: ShopItemType.badge,
        rarity: ItemRarity.uncommon,
        iconId: 'icon_7day',
        xpCost: 100,
        coinCost: 50,
      );

      expect(item.itemId, 'badge_7day');
      expect(item.name, '7日バッジ');
      expect(item.type, ShopItemType.badge);
      expect(item.rarity, ItemRarity.uncommon);
      expect(item.xpCost, 100);
      expect(item.coinCost, 50);
    });

    test('isAvailable returns true for in-stock items', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 50,
        coinCost: 25,
        currentStock: 5,
      );

      expect(item.isAvailable, true);
    });

    test('isAvailable returns false for out-of-stock items', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 50,
        coinCost: 25,
        currentStock: 0,
      );

      expect(item.isAvailable, false);
    });

    test('isAvailable returns false for expired items', () {
      final now = DateTime.now();
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 50,
        coinCost: 25,
        availableUntil: now.subtract(const Duration(days: 1)),
      );

      expect(item.isAvailable, false);
    });

    test('inStock returns true for unlimited stock', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 50,
        coinCost: 25,
        currentStock: -1,
      );

      expect(item.inStock, true);
    });

    test('inStock returns false for zero stock', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 50,
        coinCost: 25,
        currentStock: 0,
      );

      expect(item.inStock, false);
    });

    test('getMinCost returns lowest cost option', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 200,
        coinCost: 100,
        premiumCost: 50,
      );

      expect(item.getMinCost(), 50);
    });

    test('getMinCost ignores zero costs', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 100,
        coinCost: 0,
        premiumCost: 0,
      );

      expect(item.getMinCost(), 100);
    });

    test('getAvailableCurrencies returns all available options', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 100,
        coinCost: 50,
        premiumCost: 25,
      );

      final currencies = item.getAvailableCurrencies();
      expect(currencies.length, 3);
      expect(currencies.contains(CurrencyType.xp), true);
      expect(currencies.contains(CurrencyType.coins), true);
      expect(currencies.contains(CurrencyType.premium), true);
    });

    test('getAvailableCurrencies excludes zero-cost options', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Test',
        type: ShopItemType.cosmetic,
        rarity: ItemRarity.common,
        iconId: 'icon1',
        xpCost: 100,
        coinCost: 0,
        premiumCost: 0,
      );

      final currencies = item.getAvailableCurrencies();
      expect(currencies.length, 1);
      expect(currencies.contains(CurrencyType.xp), true);
    });

    test('JSON serialization round-trip', () {
      final now = DateTime.now();
      final original = ShopItem(
        itemId: 'badge_test',
        name: 'テストバッジ',
        description: 'テスト説明',
        type: ShopItemType.badge,
        rarity: ItemRarity.epic,
        iconId: 'icon_test',
        xpCost: 150,
        coinCost: 75,
        premiumCost: 500,
        purchaseLimit: 1,
        currentStock: 10,
        availableUntil: now,
        isFeatured: true,
        isNew: true,
      );

      final json = original.toJson();
      final restored = ShopItem.fromJson(json);

      expect(restored.itemId, original.itemId);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.rarity, original.rarity);
      expect(restored.xpCost, original.xpCost);
      expect(restored.isFeatured, original.isFeatured);
    });

    test('toJson includes all fields', () {
      final item = ShopItem(
        itemId: 'item1',
        name: 'Item 1',
        description: 'Description',
        type: ShopItemType.theme,
        rarity: ItemRarity.rare,
        iconId: 'icon1',
        xpCost: 100,
        coinCost: 50,
      );

      final json = item.toJson();
      expect(json.containsKey('itemId'), true);
      expect(json.containsKey('name'), true);
      expect(json.containsKey('type'), true);
      expect(json.containsKey('xpCost'), true);
    });
  });

  group('PurchaseRecord', () {
    test('creates instance with all fields', () {
      final now = DateTime.now();
      final record = PurchaseRecord(
        purchaseId: 'purchase_1',
        userId: 'user_1',
        itemId: 'item_1',
        quantityPurchased: 1,
        costPaid: 100,
        currencyUsed: CurrencyType.xp,
        purchasedAt: now,
      );

      expect(record.purchaseId, 'purchase_1');
      expect(record.userId, 'user_1');
      expect(record.costPaid, 100);
      expect(record.currencyUsed, CurrencyType.xp);
      expect(record.isGift, false);
    });

    test('creates gift purchase correctly', () {
      final now = DateTime.now();
      final record = PurchaseRecord(
        purchaseId: 'purchase_1',
        userId: 'user_1',
        itemId: 'item_1',
        quantityPurchased: 1,
        costPaid: 100,
        currencyUsed: CurrencyType.coins,
        purchasedAt: now,
        isGift: true,
        giftFromUserId: 'user_2',
      );

      expect(record.isGift, true);
      expect(record.giftFromUserId, 'user_2');
    });

    test('JSON serialization round-trip', () {
      final now = DateTime.now();
      final original = PurchaseRecord(
        purchaseId: 'pur_test',
        userId: 'user_test',
        itemId: 'item_test',
        quantityPurchased: 2,
        costPaid: 250,
        currencyUsed: CurrencyType.premium,
        purchasedAt: now,
        isGift: false,
      );

      final json = original.toJson();
      final restored = PurchaseRecord.fromJson(json);

      expect(restored.purchaseId, original.purchaseId);
      expect(restored.userId, original.userId);
      expect(restored.costPaid, original.costPaid);
      expect(restored.currencyUsed, original.currencyUsed);
    });

    test('supports multiple quantities', () {
      final now = DateTime.now();
      final record = PurchaseRecord(
        purchaseId: 'purchase_1',
        userId: 'user_1',
        itemId: 'item_1',
        quantityPurchased: 5,
        costPaid: 500,
        currencyUsed: CurrencyType.coins,
        purchasedAt: now,
      );

      expect(record.quantityPurchased, 5);
      expect(record.costPaid, 500);
    });
  });

  group('UserInventory', () {
    test('creates instance with empty inventory', () {
      final now = DateTime.now();
      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      expect(inventory.userId, 'user_1');
      expect(inventory.ownedItems.isEmpty, true);
      expect(inventory.totalItems, 0);
    });

    test('getItemCount returns correct quantity', () {
      final now = DateTime.now();
      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {'item_1': 3, 'item_2': 1},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      expect(inventory.getItemCount('item_1'), 3);
      expect(inventory.getItemCount('item_2'), 1);
      expect(inventory.getItemCount('item_3'), 0);
    });

    test('getPurchaseCount returns purchase times', () {
      final now = DateTime.now();
      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {'item_1': 2, 'item_2': 5},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      expect(inventory.getPurchaseCount('item_1'), 2);
      expect(inventory.getPurchaseCount('item_2'), 5);
      expect(inventory.getPurchaseCount('item_3'), 0);
    });

    test('ownsItem returns true only for owned items', () {
      final now = DateTime.now();
      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {'item_1': 1, 'item_2': 3},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      expect(inventory.ownsItem('item_1'), true);
      expect(inventory.ownsItem('item_2'), true);
      expect(inventory.ownsItem('item_3'), false);
    });

    test('totalItems calculates sum correctly', () {
      final now = DateTime.now();
      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {'item_1': 5, 'item_2': 3, 'item_3': 2},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      expect(inventory.totalItems, 10);
    });

    test('getTotalSpent aggregates all costs', () {
      final now = DateTime.now();
      final purchase1 = PurchaseRecord(
        purchaseId: 'p1',
        userId: 'user_1',
        itemId: 'item_1',
        quantityPurchased: 1,
        costPaid: 100,
        currencyUsed: CurrencyType.xp,
        purchasedAt: now,
      );
      final purchase2 = PurchaseRecord(
        purchaseId: 'p2',
        userId: 'user_1',
        itemId: 'item_2',
        quantityPurchased: 1,
        costPaid: 50,
        currencyUsed: CurrencyType.coins,
        purchasedAt: now,
      );

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [purchase1, purchase2],
        lastUpdatedAt: now,
      );

      expect(inventory.getTotalSpent(), 150);
    });

    test('JSON serialization round-trip', () {
      final now = DateTime.now();
      final original = UserInventory(
        userId: 'user_test',
        ownedItems: {'item_1': 2, 'item_2': 1},
        purchaseCount: {'item_1': 3},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final json = original.toJson();
      final restored = UserInventory.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.getItemCount('item_1'), 2);
      expect(restored.getPurchaseCount('item_1'), 3);
      expect(restored.totalItems, 3);
    });

    test('handles purchase history with max 100 records', () {
      final now = DateTime.now();
      final purchases = List.generate(
        100,
        (i) => PurchaseRecord(
          purchaseId: 'p_$i',
          userId: 'user_1',
          itemId: 'item_1',
          quantityPurchased: 1,
          costPaid: 10,
          currencyUsed: CurrencyType.coins,
          purchasedAt: now,
        ),
      );

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {'item_1': 100},
        purchaseCount: {},
        purchaseHistory: purchases,
        lastUpdatedAt: now,
      );

      expect(inventory.purchaseHistory.length, 100);
    });
  });

  group('ShopStats', () {
    test('creates instance with all stats', () {
      final now = DateTime.now();
      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 500,
        totalCoinsSpent: 250,
        totalPremiumSpent: 100,
        totalPurchases: 5,
        totalItemsOwned: 10,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user_1');
      expect(stats.totalXpSpent, 500);
      expect(stats.totalPurchases, 5);
    });

    test('getTotalSpent aggregates all currencies', () {
      final now = DateTime.now();
      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 300,
        totalCoinsSpent: 200,
        totalPremiumSpent: 100,
        totalPurchases: 3,
        totalItemsOwned: 5,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      expect(stats.getTotalSpent(), 600);
    });

    test('JSON serialization round-trip', () {
      final now = DateTime.now();
      final original = ShopStats(
        userId: 'user_test',
        totalXpSpent: 150,
        totalCoinsSpent: 75,
        totalPremiumSpent: 25,
        totalPurchases: 2,
        totalItemsOwned: 3,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final json = original.toJson();
      final restored = ShopStats.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.totalXpSpent, original.totalXpSpent);
      expect(restored.getTotalSpent(), original.getTotalSpent());
    });

    test('tracks purchase dates correctly', () {
      final first = DateTime.now().subtract(const Duration(days: 7));
      final last = DateTime.now();

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 2,
        totalItemsOwned: 0,
        firstPurchaseDate: first,
        lastPurchaseDate: last,
        lastUpdatedAt: last,
      );

      expect(stats.firstPurchaseDate, first);
      expect(stats.lastPurchaseDate, last);
    });
  });

  group('ShopCatalog', () {
    test('creates catalog with items', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'item_1',
          name: 'Item 1',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_1',
          xpCost: 50,
          coinCost: 25,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 0,
        totalItemsOwned: 0,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      expect(catalog.allItems.length, 1);
      expect(catalog.inventory.userId, 'user_1');
    });

    test('getItem returns item by ID', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'badge_7day',
          name: '7日バッジ',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.uncommon,
          iconId: 'icon_7day',
          xpCost: 100,
          coinCost: 50,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 0,
        totalItemsOwned: 0,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      final item = catalog.getItem('badge_7day');
      expect(item.name, '7日バッジ');
    });

    test('getByType filters items correctly', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'badge_1',
          name: 'Badge 1',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_1',
          xpCost: 50,
          coinCost: 25,
        ),
        ShopItem(
          itemId: 'theme_1',
          name: 'Theme 1',
          description: 'Test',
          type: ShopItemType.theme,
          rarity: ItemRarity.common,
          iconId: 'icon_2',
          xpCost: 50,
          coinCost: 25,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 0,
        totalItemsOwned: 0,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      final badges = catalog.getByType(ShopItemType.badge);
      expect(badges.length, 1);
      expect(badges.first.itemId, 'badge_1');
    });

    test('getByRarity filters correctly', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'item_common',
          name: 'Common',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_1',
          xpCost: 50,
          coinCost: 25,
        ),
        ShopItem(
          itemId: 'item_epic',
          name: 'Epic',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.epic,
          iconId: 'icon_2',
          xpCost: 500,
          coinCost: 250,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 0,
        totalItemsOwned: 0,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      final epics = catalog.getByRarity(ItemRarity.epic);
      expect(epics.length, 1);
      expect(epics.first.itemId, 'item_epic');
    });

    test('getAvailableItems returns only available items', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'available',
          name: 'Available',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_1',
          xpCost: 50,
          coinCost: 25,
          currentStock: 5,
        ),
        ShopItem(
          itemId: 'sold_out',
          name: 'Sold Out',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_2',
          xpCost: 50,
          coinCost: 25,
          currentStock: 0,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 0,
        totalItemsOwned: 0,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      final available = catalog.getAvailableItems();
      expect(available.length, 1);
      expect(available.first.itemId, 'available');
    });

    test('getFeaturedItems returns featured only', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'featured',
          name: 'Featured',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_1',
          xpCost: 50,
          coinCost: 25,
          isFeatured: true,
        ),
        ShopItem(
          itemId: 'normal',
          name: 'Normal',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_2',
          xpCost: 50,
          coinCost: 25,
          isFeatured: false,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 0,
        totalItemsOwned: 0,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      final featured = catalog.getFeaturedItems();
      expect(featured.length, 1);
      expect(featured.first.isFeatured, true);
    });

    test('getNewItems returns new items only', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'new_item',
          name: 'New',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_1',
          xpCost: 50,
          coinCost: 25,
          isNew: true,
        ),
        ShopItem(
          itemId: 'old_item',
          name: 'Old',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_2',
          xpCost: 50,
          coinCost: 25,
          isNew: false,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 0,
        totalItemsOwned: 0,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      final newItems = catalog.getNewItems();
      expect(newItems.length, 1);
      expect(newItems.first.isNew, true);
    });

    test('getAffordableItems filters by currency', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'cheap_xp',
          name: 'Cheap XP',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_1',
          xpCost: 50,
          coinCost: 0,
        ),
        ShopItem(
          itemId: 'expensive',
          name: 'Expensive',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.epic,
          iconId: 'icon_2',
          xpCost: 500,
          coinCost: 250,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_1',
        ownedItems: {},
        purchaseCount: {},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_1',
        totalXpSpent: 0,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 0,
        totalItemsOwned: 0,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final catalog = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      final affordable = catalog.getAffordableItems(100, 100);
      expect(affordable.length, 1);
      expect(affordable.first.itemId, 'cheap_xp');
    });

    test('JSON serialization round-trip', () {
      final now = DateTime.now();
      final items = [
        ShopItem(
          itemId: 'test_item',
          name: 'Test',
          description: 'Test',
          type: ShopItemType.badge,
          rarity: ItemRarity.common,
          iconId: 'icon_test',
          xpCost: 50,
          coinCost: 25,
        ),
      ];

      final inventory = UserInventory(
        userId: 'user_test',
        ownedItems: {'test_item': 1},
        purchaseCount: {'test_item': 1},
        purchaseHistory: [],
        lastUpdatedAt: now,
      );

      final stats = ShopStats(
        userId: 'user_test',
        totalXpSpent: 50,
        totalCoinsSpent: 0,
        totalPremiumSpent: 0,
        totalPurchases: 1,
        totalItemsOwned: 1,
        firstPurchaseDate: now,
        lastPurchaseDate: now,
        lastUpdatedAt: now,
      );

      final original = ShopCatalog(
        allItems: items,
        inventory: inventory,
        stats: stats,
        generatedAt: now,
      );

      final json = original.toJson();
      final restored = ShopCatalog.fromJson(json);

      expect(restored.allItems.length, 1);
      expect(restored.inventory.userId, 'user_test');
      expect(restored.stats.totalXpSpent, 50);
    });
  });
}
