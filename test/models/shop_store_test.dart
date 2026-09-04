import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/shop_store.dart';

void main() {
  group('ItemCategory Enum', () {
    test('has all expected categories', () {
      expect(ItemCategory.values.length, 6);
      expect(ItemCategory.values, contains(ItemCategory.cosmetic));
      expect(ItemCategory.values, contains(ItemCategory.special));
    });
  });

  group('ItemRarity Enum', () {
    test('has all expected rarities', () {
      expect(ItemRarity.values.length, 5);
      expect(ItemRarity.values, contains(ItemRarity.legendary));
    });
  });

  group('CurrencyType Enum', () {
    test('has all expected types', () {
      expect(CurrencyType.values.length, 3);
      expect(CurrencyType.values, contains(CurrencyType.both));
    });
  });

  group('ShopItem', () {
    test('creates item with required fields', () {
      final now = DateTime.now();
      final item = ShopItem(
        itemId: 'item1',
        name: 'テスト',
        description: 'Test item',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        addedAt: now,
      );

      expect(item.itemId, 'item1');
      expect(item.name, 'テスト');
      expect(item.isAvailable, true);
    });

    test('isAvailable returns true for non-limited items', () {
      final now = DateTime.now();
      final item = ShopItem(
        itemId: 'item1',
        name: 'Test',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        isLimited: false,
        addedAt: now,
      );

      expect(item.isAvailable, true);
    });

    test('isAvailable returns true for limited items within time', () {
      final now = DateTime.now();
      final item = ShopItem(
        itemId: 'item1',
        name: 'Test',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        isLimited: true,
        limitedUntil: now.add(const Duration(days: 1)),
        addedAt: now,
      );

      expect(item.isAvailable, true);
    });

    test('isAvailable returns false for expired limited items', () {
      final now = DateTime.now();
      final item = ShopItem(
        itemId: 'item1',
        name: 'Test',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        isLimited: true,
        limitedUntil: now.subtract(const Duration(days: 1)),
        addedAt: now,
      );

      expect(item.isAvailable, false);
    });

    test('isPopular returns true for high sales', () {
      final now = DateTime.now();
      final item = ShopItem(
        itemId: 'item1',
        name: 'Test',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        salesCount: 150,
        addedAt: now,
      );

      expect(item.isPopular, true);
    });

    test('getBestPrice returns lower price', () {
      final now = DateTime.now();
      final item = ShopItem(
        itemId: 'item1',
        name: 'Test',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        premiumCoinPrice: 10,
        acceptedCurrency: CurrencyType.both,
        addedAt: now,
      );

      expect(item.getBestPrice(), 10);
    });

    test('toJson serializes item', () {
      final now = DateTime.now();
      final item = ShopItem(
        itemId: 'item1',
        name: 'Test',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        salesCount: 50,
        addedAt: now,
      );

      final json = item.toJson();
      expect(json['itemId'], 'item1');
      expect(json['salesCount'], 50);
    });

    test('fromJson deserializes item', () {
      final now = DateTime.now();
      final json = {
        'itemId': 'item1',
        'name': 'Test',
        'description': 'Test',
        'category': 'cosmetic',
        'rarity': 'common',
        'coinPrice': 500,
        'acceptedCurrency': 'coin',
        'addedAt': now.toIso8601String(),
      };

      final item = ShopItem.fromJson(json);
      expect(item.itemId, 'item1');
      expect(item.category, ItemCategory.cosmetic);
    });
  });

  group('OwnedItem', () {
    test('creates owned item with required fields', () {
      final now = DateTime.now();
      final owned = OwnedItem(
        ownedItemId: 'oi1',
        itemId: 'item1',
        userId: 'user1',
        quantity: 1,
        purchasedAt: now,
      );

      expect(owned.ownedItemId, 'oi1');
      expect(owned.isExpired, false);
    });

    test('isExpired returns true for expired items', () {
      final now = DateTime.now();
      final owned = OwnedItem(
        ownedItemId: 'oi1',
        itemId: 'item1',
        userId: 'user1',
        quantity: 1,
        purchasedAt: now,
        expiresAt: now.subtract(const Duration(hours: 1)),
      );

      expect(owned.isExpired, true);
    });

    test('isExpired returns false for valid items', () {
      final now = DateTime.now();
      final owned = OwnedItem(
        ownedItemId: 'oi1',
        itemId: 'item1',
        userId: 'user1',
        quantity: 1,
        purchasedAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
      );

      expect(owned.isExpired, false);
    });

    test('toJson serializes owned item', () {
      final now = DateTime.now();
      final owned = OwnedItem(
        ownedItemId: 'oi1',
        itemId: 'item1',
        userId: 'user1',
        quantity: 2,
        purchasedAt: now,
        purchasePrice: 500,
      );

      final json = owned.toJson();
      expect(json['quantity'], 2);
      expect(json['purchasePrice'], 500);
    });
  });

  group('PurchaseTransaction', () {
    test('creates transaction with required fields', () {
      final now = DateTime.now();
      final tx = PurchaseTransaction(
        transactionId: 'tx1',
        userId: 'user1',
        itemId: 'item1',
        itemName: 'Test Item',
        quantity: 1,
        amountSpent: 500,
        currencyUsed: 'coin',
        purchasedAt: now,
      );

      expect(tx.transactionId, 'tx1');
      expect(tx.status, 'completed');
    });

    test('toJson serializes transaction', () {
      final now = DateTime.now();
      final tx = PurchaseTransaction(
        transactionId: 'tx1',
        userId: 'user1',
        itemId: 'item1',
        itemName: 'Test Item',
        quantity: 1,
        amountSpent: 500,
        currencyUsed: 'coin',
        purchasedAt: now,
      );

      final json = tx.toJson();
      expect(json['transactionId'], 'tx1');
      expect(json['amountSpent'], 500);
    });

    test('fromJson deserializes transaction', () {
      final now = DateTime.now();
      final json = {
        'transactionId': 'tx1',
        'userId': 'user1',
        'itemId': 'item1',
        'itemName': 'Test Item',
        'quantity': 1,
        'amountSpent': 500,
        'currencyUsed': 'coin',
        'purchasedAt': now.toIso8601String(),
      };

      final tx = PurchaseTransaction.fromJson(json);
      expect(tx.transactionId, 'tx1');
      expect(tx.status, 'completed');
    });
  });

  group('ShopStatistics', () {
    test('creates statistics with required fields', () {
      final now = DateTime.now();
      final stats = ShopStatistics(
        userId: 'user1',
        firstPurchaseAt: now,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalPurchases, 0);
    });

    test('getSpenderTier returns correct tiers', () {
      final now = DateTime.now();

      final browserStats = ShopStatistics(
        userId: 'user1',
        totalSpent: 50,
        firstPurchaseAt: now,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );
      expect(browserStats.getSpenderTier(), 'ブラウザー');

      const collectorStats = ShopStatistics(
        userId: 'user2',
        totalSpent: 1500,
        firstPurchaseAt: DateTime(2024),
        lastPurchaseAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(collectorStats.getSpenderTier(), 'コレクター');

      const vipStats = ShopStatistics(
        userId: 'user3',
        totalSpent: 6000,
        firstPurchaseAt: DateTime(2024),
        lastPurchaseAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(vipStats.getSpenderTier(), 'VIP');
    });

    test('toJson serializes statistics', () {
      final now = DateTime.now();
      final stats = ShopStatistics(
        userId: 'user1',
        totalPurchases: 10,
        totalSpent: 5000,
        firstPurchaseAt: now,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      expect(json['userId'], 'user1');
      expect(json['totalPurchases'], 10);
    });
  });

  group('ShopCollection', () {
    test('creates collection with required fields', () {
      final now = DateTime.now();
      final stats = ShopStatistics(
        userId: 'user1',
        firstPurchaseAt: now,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );

      final collection = ShopCollection(
        userId: 'user1',
        allItems: [],
        ownedItems: [],
        transactions: [],
        statistics: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.allItems.isEmpty, true);
    });

    test('getAvailableItems filters available only', () {
      final now = DateTime.now();
      final available = ShopItem(
        itemId: 'item1',
        name: 'Available',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        isLimited: false,
        addedAt: now,
      );
      final unavailable = ShopItem(
        itemId: 'item2',
        name: 'Expired',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        isLimited: true,
        limitedUntil: now.subtract(const Duration(days: 1)),
        addedAt: now,
      );

      final stats = ShopStatistics(
        userId: 'user1',
        firstPurchaseAt: now,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );

      final collection = ShopCollection(
        userId: 'user1',
        allItems: [available, unavailable],
        ownedItems: [],
        transactions: [],
        statistics: stats,
        generatedAt: now,
      );

      final availableList = collection.getAvailableItems();
      expect(availableList.length, 1);
      expect(availableList[0].itemId, 'item1');
    });

    test('getItemsByCategory filters by category', () {
      final now = DateTime.now();
      final cosmetic = ShopItem(
        itemId: 'item1',
        name: 'Avatar',
        description: 'Test',
        category: ItemCategory.cosmetic,
        rarity: ItemRarity.common,
        coinPrice: 500,
        acceptedCurrency: CurrencyType.coin,
        addedAt: now,
      );
      final powerup = ShopItem(
        itemId: 'item2',
        name: 'Booster',
        description: 'Test',
        category: ItemCategory.powerup,
        rarity: ItemRarity.rare,
        coinPrice: 1000,
        acceptedCurrency: CurrencyType.coin,
        addedAt: now,
      );

      final stats = ShopStatistics(
        userId: 'user1',
        firstPurchaseAt: now,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );

      final collection = ShopCollection(
        userId: 'user1',
        allItems: [cosmetic, powerup],
        ownedItems: [],
        transactions: [],
        statistics: stats,
        generatedAt: now,
      );

      final cosmetics = collection.getItemsByCategory(ItemCategory.cosmetic);
      expect(cosmetics.length, 1);
      expect(cosmetics[0].category, ItemCategory.cosmetic);
    });

    test('getActivePowerups filters non-expired items', () {
      final now = DateTime.now();
      final active = OwnedItem(
        ownedItemId: 'oi1',
        itemId: 'item1',
        userId: 'user1',
        quantity: 1,
        purchasedAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
        isActive: true,
      );
      final expired = OwnedItem(
        ownedItemId: 'oi2',
        itemId: 'item2',
        userId: 'user1',
        quantity: 1,
        purchasedAt: now,
        expiresAt: now.subtract(const Duration(hours: 1)),
        isActive: true,
      );

      final stats = ShopStatistics(
        userId: 'user1',
        firstPurchaseAt: now,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );

      final collection = ShopCollection(
        userId: 'user1',
        allItems: [],
        ownedItems: [active, expired],
        transactions: [],
        statistics: stats,
        generatedAt: now,
      );

      final activePowerups = collection.getActivePowerups();
      expect(activePowerups.length, 1);
      expect(activePowerups[0].ownedItemId, 'oi1');
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final stats = ShopStatistics(
        userId: 'user1',
        firstPurchaseAt: now,
        lastPurchaseAt: now,
        lastUpdatedAt: now,
      );

      final collection = ShopCollection(
        userId: 'user1',
        allItems: [],
        ownedItems: [],
        transactions: [],
        statistics: stats,
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = ShopCollection.fromJson(json);

      expect(restored.userId, collection.userId);
    });
  });
}
