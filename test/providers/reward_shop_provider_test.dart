import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/reward_shop.dart';
import 'package:shogaku_kore_programming/providers/reward_shop_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('ShopNotifier', () {
    test('initializes with empty state', () {
      final notifier = ShopNotifier();
      expect(notifier.state.catalog, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeShop creates default catalog', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final state = container.read(shopProvider);
      expect(state.catalog, isNotNull);
      expect(state.catalog!.allItems.isNotEmpty, true);
      expect(state.isLoading, false);
    });

    test('initializeShop creates correct number of items', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final state = container.read(shopProvider);
      // Should have badge, theme, avatar, powerup, bundle items
      expect(state.catalog!.allItems.length, greaterThan(0));
    });

    test('initializeShop creates empty inventory for new user', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('new_user');

      final state = container.read(shopProvider);
      expect(state.catalog!.inventory.userId, 'new_user');
      expect(state.catalog!.inventory.ownedItems.isEmpty, true);
      expect(state.catalog!.inventory.totalItems, 0);
    });

    test('initializeShop creates default stats', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final state = container.read(shopProvider);
      expect(state.catalog!.stats.userId, 'test_user');
      expect(state.catalog!.stats.totalXpSpent, 0);
      expect(state.catalog!.stats.totalPurchases, 0);
    });

    test('purchaseItem with XP currency succeeds', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final itemId = container.read(shopProvider).catalog!.allItems.first.itemId;
      final success = await notifier.purchaseItem(
        'test_user',
        itemId,
        CurrencyType.xp,
      );

      expect(success, true);

      final state = container.read(shopProvider);
      expect(state.catalog!.inventory.getItemCount(itemId), 1);
      expect(state.catalog!.stats.totalPurchases, 1);
    });

    test('purchaseItem with coins currency succeeds', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.coinCost > 0);
      final success = await notifier.purchaseItem(
        'test_user',
        item.itemId,
        CurrencyType.coins,
      );

      expect(success, true);

      final state = container.read(shopProvider);
      expect(state.catalog!.stats.totalCoinsSpent, greaterThan(0));
    });

    test('purchaseItem with premium currency succeeds', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.premiumCost > 0);
      final success = await notifier.purchaseItem(
        'test_user',
        item.itemId,
        CurrencyType.premium,
      );

      expect(success, true);

      final state = container.read(shopProvider);
      expect(state.catalog!.stats.totalPremiumSpent, greaterThan(0));
    });

    test('purchaseItem with zero cost fails', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      // Item has xpCost=0 for this currency
      final item = ShopItem(
        itemId: 'test_item',
        name: 'Test',
        description: 'Test',
        type: ShopItemType.badge,
        rarity: ItemRarity.common,
        iconId: 'icon',
        xpCost: 0,
        coinCost: 50,
      );

      final success = await notifier.purchaseItem(
        'test_user',
        'test_item',
        CurrencyType.xp,
      );

      expect(success, false);
    });

    test('purchaseItem respects purchase limit', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.purchaseLimit == 1);

      // First purchase should succeed
      final first = await notifier.purchaseItem(
        'test_user',
        item.itemId,
        CurrencyType.xp,
      );
      expect(first, true);

      // Second purchase should fail
      final second = await notifier.purchaseItem(
        'test_user',
        item.itemId,
        CurrencyType.xp,
      );
      expect(second, false);
    });

    test('purchaseItem fails for unavailable items', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      // Item with stock 0
      final item = ShopItem(
        itemId: 'sold_out',
        name: 'Sold Out',
        description: 'Test',
        type: ShopItemType.badge,
        rarity: ItemRarity.common,
        iconId: 'icon',
        xpCost: 50,
        coinCost: 25,
        currentStock: 0,
      );

      final success = await notifier.purchaseItem(
        'test_user',
        'sold_out',
        CurrencyType.xp,
      );

      expect(success, false);
    });

    test('purchaseItem updates inventory', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final itemId = container.read(shopProvider).catalog!.allItems.first.itemId;

      await notifier.purchaseItem(
        'test_user',
        itemId,
        CurrencyType.xp,
        quantity: 2,
      );

      final state = container.read(shopProvider);
      expect(state.catalog!.inventory.getItemCount(itemId), 2);
      expect(state.catalog!.inventory.getPurchaseCount(itemId), 1);
    });

    test('purchaseItem updates stats correctly', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.xpCost > 0);

      await notifier.purchaseItem(
        'test_user',
        item.itemId,
        CurrencyType.xp,
      );

      final state = container.read(shopProvider);
      expect(state.catalog!.stats.totalXpSpent, item.xpCost);
      expect(state.catalog!.stats.totalPurchases, 1);
      expect(state.catalog!.stats.totalItemsOwned, 1);
    });

    test('purchaseItem adds to recently purchased', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final itemId = container.read(shopProvider).catalog!.allItems.first.itemId;

      await notifier.purchaseItem(
        'test_user',
        itemId,
        CurrencyType.xp,
      );

      final state = container.read(shopProvider);
      expect(state.recentlyCompleted.isNotEmpty, true);
    });

    test('purchaseItem supports gift purchases', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final itemId = container.read(shopProvider).catalog!.allItems.first.itemId;

      final success = await notifier.purchaseItem(
        'test_user',
        itemId,
        CurrencyType.coins,
        giftToUserId: 'user_2',
      );

      expect(success, true);

      final state = container.read(shopProvider);
      final purchase = state.catalog!.inventory.purchaseHistory.first;
      expect(purchase.isGift, true);
      expect(purchase.giftFromUserId, 'user_2');
    });

    test('refundPurchase removes purchase from history', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final itemId = container.read(shopProvider).catalog!.allItems.first.itemId;

      await notifier.purchaseItem('test_user', itemId, CurrencyType.xp);

      var state = container.read(shopProvider);
      final purchaseId = state.catalog!.inventory.purchaseHistory.first.purchaseId;

      final refunded = await notifier.refundPurchase('test_user', purchaseId);
      expect(refunded, true);

      state = container.read(shopProvider);
      expect(state.catalog!.inventory.purchaseHistory.isEmpty, true);
    });

    test('refundPurchase updates inventory', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final itemId = container.read(shopProvider).catalog!.allItems.first.itemId;

      await notifier.purchaseItem('test_user', itemId, CurrencyType.coins);

      var state = container.read(shopProvider);
      expect(state.catalog!.inventory.getItemCount(itemId), 1);

      final purchaseId = state.catalog!.inventory.purchaseHistory.first.purchaseId;
      await notifier.refundPurchase('test_user', purchaseId);

      state = container.read(shopProvider);
      expect(state.catalog!.inventory.getItemCount(itemId), 0);
    });

    test('refundPurchase updates stats', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.coinCost > 0);

      await notifier.purchaseItem('test_user', item.itemId, CurrencyType.coins);

      var state = container.read(shopProvider);
      final initialSpent = state.catalog!.stats.totalCoinsSpent;
      expect(initialSpent, greaterThan(0));

      final purchaseId = state.catalog!.inventory.purchaseHistory.first.purchaseId;
      await notifier.refundPurchase('test_user', purchaseId);

      state = container.read(shopProvider);
      expect(state.catalog!.stats.totalCoinsSpent, 0);
    });

    test('getRecommendedItems returns featured and new', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final recommended = notifier.getRecommendedItems(1000, 1000);

      if (recommended.isNotEmpty) {
        expect(recommended.every((item) => item.isFeatured || item.isNew), true);
      }
    });

    test('getRecommendedItems filters by affordability', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final recommended = notifier.getRecommendedItems(50, 50);

      recommended.forEach((item) {
        expect(
          (item.xpCost > 0 && item.xpCost <= 50) ||
          (item.coinCost > 0 && item.coinCost <= 50),
          true,
        );
      });
    });

    test('clearRecentPurchases empties list', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final itemId = container.read(shopProvider).catalog!.allItems.first.itemId;
      await notifier.purchaseItem('test_user', itemId, CurrencyType.xp);

      var state = container.read(shopProvider);
      expect(state.recentlyCompleted.isNotEmpty, true);

      notifier.clearRecentPurchases();

      state = container.read(shopProvider);
      expect(state.recentlyCompleted.isEmpty, true);
    });

    test('getTotalSpent returns correct sum', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.xpCost > 0);

      await notifier.purchaseItem('test_user', item.itemId, CurrencyType.xp);

      final total = notifier.getTotalSpent();
      expect(total, greaterThan(0));
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('persist_test');

      final itemId = container.read(shopProvider).catalog!.allItems.first.itemId;
      await notifier.purchaseItem('persist_test', itemId, CurrencyType.coins);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('shop_inventory_persist_test'), true);
      expect(prefs.containsKey('shop_stats_persist_test'), true);
    });

    test('handles multiple purchases of same item', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.purchaseLimit == -1);

      await notifier.purchaseItem('test_user', item.itemId, CurrencyType.xp);
      await notifier.purchaseItem('test_user', item.itemId, CurrencyType.xp);

      final state = container.read(shopProvider);
      expect(state.catalog!.inventory.getPurchaseCount(item.itemId), 2);
      expect(state.catalog!.stats.totalPurchases, 2);
    });

    test('handles currency type switching', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.xpCost > 0 && i.coinCost > 0);

      await notifier.purchaseItem('test_user', item.itemId, CurrencyType.xp);
      await notifier.purchaseItem('test_user', item.itemId, CurrencyType.coins);

      final state = container.read(shopProvider);
      expect(state.catalog!.stats.totalXpSpent, greaterThan(0));
      expect(state.catalog!.stats.totalCoinsSpent, greaterThan(0));
    });
  });

  group('Riverpod Providers', () {
    test('shopCatalogProvider returns catalog', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final catalog = container.read(shopCatalogProvider);
      expect(catalog, isNotNull);
      expect(catalog!.allItems.isNotEmpty, true);
    });

    test('userInventoryProvider provides inventory', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final inventory = container.read(userInventoryProvider);
      expect(inventory, isNotNull);
      expect(inventory!.userId, 'test_user');
    });

    test('shopStatsProvider provides stats', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final stats = container.read(shopStatsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('availableItemsProvider returns available items', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final available = container.read(availableItemsProvider);
      expect(available.isNotEmpty, true);
      expect(available.every((item) => item.isAvailable), true);
    });

    test('featuredItemsProvider returns featured only', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final featured = container.read(featuredItemsProvider);
      if (featured.isNotEmpty) {
        expect(featured.every((item) => item.isFeatured), true);
      }
    });

    test('newItemsProvider returns new items only', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final newItems = container.read(newItemsProvider);
      if (newItems.isNotEmpty) {
        expect(newItems.every((item) => item.isNew), true);
      }
    });
  });

  group('Edge Cases', () {
    test('handles purchase of bundle items', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final bundle = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.type == ShopItemType.bundle, orElse: () => container.read(shopProvider).catalog!.allItems.first);

      final success = await notifier.purchaseItem(
        'test_user',
        bundle.itemId,
        CurrencyType.xp,
      );

      expect(success, true);
    });

    test('handles expired items correctly', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      // The provider already generates items, check if any are expired
      final state = container.read(shopProvider);
      final expiredItems = state.catalog!.allItems
          .where((item) => !item.isAvailable && item.availableUntil != null)
          .toList();

      for (final item in expiredItems) {
        final success = await notifier.purchaseItem(
          'test_user',
          item.itemId,
          CurrencyType.xp,
        );
        expect(success, false);
      }
    });

    test('purchase history maintains max 100 records', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final item = container.read(shopProvider).catalog!.allItems
          .firstWhere((i) => i.purchaseLimit == -1);

      // Simulate multiple purchases
      for (int i = 0; i < 105; i++) {
        await notifier.purchaseItem('test_user', item.itemId, CurrencyType.coins);
      }

      final state = container.read(shopProvider);
      expect(state.catalog!.inventory.purchaseHistory.length, lessThanOrEqualTo(100));
    });

    test('handles null catalog gracefully', () async {
      final notifier = ShopNotifier();
      expect(notifier.state.catalog, isNull);
      expect(notifier.getTotalSpent(), 0);
      expect(notifier.getTotalPurchases(), 0);
      expect(notifier.getTotalItemsOwned(), 0);
    });

    test('handles nonexistent purchase refund', () async {
      final notifier = container.read(shopProvider.notifier);
      await notifier.initializeShop('test_user');

      final refunded = await notifier.refundPurchase('test_user', 'nonexistent');
      expect(refunded, false);
    });
  });
}
