/// Shop item type/category
enum ShopItemType {
  badge,         // Badge/achievement cosmetic
  theme,         // App theme customization
  avatar,        // User avatar/profile picture
  powerup,       // Temporary boost/power-up
  cosmetic,      // Other cosmetic item
  bundle,        // Multi-item bundle
}

/// Currency type for pricing
enum CurrencyType {
  xp,            // Experience points
  coins,         // In-game coins
  premium,       // Premium currency (real money)
}

/// Item rarity/exclusivity
enum ItemRarity {
  common,        // Easy to obtain
  uncommon,      // Moderately rare
  rare,          // Hard to obtain
  epic,          // Very rare
  legendary,     // Extremely rare
}

/// Shop item for purchase
class ShopItem {
  final String itemId;
  final String name;                 // Item name (Japanese)
  final String description;          // Item description
  final ShopItemType type;
  final ItemRarity rarity;
  final String iconId;               // Icon/image identifier
  final int xpCost;                  // Cost in XP (0 if not available)
  final int coinCost;                // Cost in coins (0 if not available)
  final int premiumCost;             // Cost in premium currency (0 if not available)
  final int purchaseLimit;           // Max purchases (-1 = unlimited)
  final int currentStock;            // Current available stock (-1 = unlimited)
  final DateTime? availableUntil;    // Limited time availability
  final bool isFeatured;             // Show in featured section
  final bool isNew;                  // Mark as new item
  final List<String>? unlockAchievementIds;  // Achievements that unlock this

  ShopItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.iconId,
    required this.xpCost,
    required this.coinCost,
    this.premiumCost = 0,
    this.purchaseLimit = -1,
    this.currentStock = -1,
    this.availableUntil,
    this.isFeatured = false,
    this.isNew = false,
    this.unlockAchievementIds,
  });

  /// Check if item is available for purchase
  bool get isAvailable {
    if (currentStock == 0) return false;
    if (availableUntil != null && DateTime.now().isAfter(availableUntil!)) {
      return false;
    }
    return true;
  }

  /// Check if item is in stock
  bool get inStock => currentStock != 0;

  /// Get minimum cost (lowest available currency option)
  int getMinCost() {
    final costs = [
      if (xpCost > 0) xpCost,
      if (coinCost > 0) coinCost,
      if (premiumCost > 0) premiumCost,
    ];
    return costs.isEmpty ? 0 : costs.reduce((a, b) => a < b ? a : b);
  }

  /// Get available currency options
  List<CurrencyType> getAvailableCurrencies() {
    final currencies = <CurrencyType>[];
    if (xpCost > 0) currencies.add(CurrencyType.xp);
    if (coinCost > 0) currencies.add(CurrencyType.coins);
    if (premiumCost > 0) currencies.add(CurrencyType.premium);
    return currencies;
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'name': name,
        'description': description,
        'type': type.name,
        'rarity': rarity.name,
        'iconId': iconId,
        'xpCost': xpCost,
        'coinCost': coinCost,
        'premiumCost': premiumCost,
        'purchaseLimit': purchaseLimit,
        'currentStock': currentStock,
        'availableUntil': availableUntil?.toIso8601String(),
        'isFeatured': isFeatured,
        'isNew': isNew,
        'unlockAchievementIds': unlockAchievementIds,
      };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        itemId: json['itemId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: ShopItemType.values.byName(json['type'] as String),
        rarity: ItemRarity.values.byName(json['rarity'] as String),
        iconId: json['iconId'] as String,
        xpCost: json['xpCost'] as int? ?? 0,
        coinCost: json['coinCost'] as int? ?? 0,
        premiumCost: json['premiumCost'] as int? ?? 0,
        purchaseLimit: json['purchaseLimit'] as int? ?? -1,
        currentStock: json['currentStock'] as int? ?? -1,
        availableUntil: json['availableUntil'] != null
            ? DateTime.parse(json['availableUntil'] as String)
            : null,
        isFeatured: json['isFeatured'] as bool? ?? false,
        isNew: json['isNew'] as bool? ?? false,
        unlockAchievementIds:
            (json['unlockAchievementIds'] as List?)?.cast<String>(),
      );
}

/// User's purchase record
class PurchaseRecord {
  final String purchaseId;
  final String userId;
  final String itemId;
  final int quantityPurchased;
  final int costPaid;               // Actual cost paid (could be discounted)
  final CurrencyType currencyUsed;
  final DateTime purchasedAt;
  final bool isGift;                // Was this a gift?
  final String? giftFromUserId;     // If gift, who sent it

  PurchaseRecord({
    required this.purchaseId,
    required this.userId,
    required this.itemId,
    required this.quantityPurchased,
    required this.costPaid,
    required this.currencyUsed,
    required this.purchasedAt,
    this.isGift = false,
    this.giftFromUserId,
  });

  Map<String, dynamic> toJson() => {
        'purchaseId': purchaseId,
        'userId': userId,
        'itemId': itemId,
        'quantityPurchased': quantityPurchased,
        'costPaid': costPaid,
        'currencyUsed': currencyUsed.name,
        'purchasedAt': purchasedAt.toIso8601String(),
        'isGift': isGift,
        'giftFromUserId': giftFromUserId,
      };

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) =>
      PurchaseRecord(
        purchaseId: json['purchaseId'] as String,
        userId: json['userId'] as String,
        itemId: json['itemId'] as String,
        quantityPurchased: json['quantityPurchased'] as int,
        costPaid: json['costPaid'] as int,
        currencyUsed: CurrencyType.values.byName(json['currencyUsed'] as String),
        purchasedAt: DateTime.parse(json['purchasedAt'] as String),
        isGift: json['isGift'] as bool? ?? false,
        giftFromUserId: json['giftFromUserId'] as String?,
      );
}

/// User's shop inventory
class UserInventory {
  final String userId;
  final Map<String, int> ownedItems;      // itemId -> quantity
  final Map<String, int> purchaseCount;   // itemId -> times purchased
  final List<PurchaseRecord> purchaseHistory;  // Max 100 records
  final DateTime lastUpdatedAt;

  UserInventory({
    required this.userId,
    required this.ownedItems,
    required this.purchaseCount,
    required this.purchaseHistory,
    required this.lastUpdatedAt,
  });

  /// Get quantity of item owned
  int getItemCount(String itemId) => ownedItems[itemId] ?? 0;

  /// Get times item was purchased
  int getPurchaseCount(String itemId) => purchaseCount[itemId] ?? 0;

  /// Check if user owns item
  bool ownsItem(String itemId) => (ownedItems[itemId] ?? 0) > 0;

  /// Get total items in inventory
  int get totalItems => ownedItems.values.fold(0, (sum, count) => sum + count);

  /// Get total spent (all currencies combined)
  int getTotalSpent() =>
      purchaseHistory.fold(0, (sum, record) => sum + record.costPaid);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'ownedItems': ownedItems,
        'purchaseCount': purchaseCount,
        'purchaseHistory':
            purchaseHistory.map((r) => r.toJson()).toList(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory UserInventory.fromJson(Map<String, dynamic> json) => UserInventory(
        userId: json['userId'] as String,
        ownedItems: (json['ownedItems'] as Map?)?.cast<String, int>() ?? {},
        purchaseCount: (json['purchaseCount'] as Map?)?.cast<String, int>() ?? {},
        purchaseHistory: ((json['purchaseHistory'] as List?) ?? [])
            .map((r) => PurchaseRecord.fromJson(r as Map<String, dynamic>))
            .toList(),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Shop statistics and analytics
class ShopStats {
  final String userId;
  final int totalXpSpent;              // Total XP spent
  final int totalCoinsSpent;           // Total coins spent
  final int totalPremiumSpent;         // Total premium spent
  final int totalPurchases;            // Total purchase transactions
  final int totalItemsOwned;           // Total unique items owned
  final DateTime firstPurchaseDate;    // When first purchase was made
  final DateTime lastPurchaseDate;     // Most recent purchase
  final DateTime lastUpdatedAt;

  ShopStats({
    required this.userId,
    required this.totalXpSpent,
    required this.totalCoinsSpent,
    required this.totalPremiumSpent,
    required this.totalPurchases,
    required this.totalItemsOwned,
    required this.firstPurchaseDate,
    required this.lastPurchaseDate,
    required this.lastUpdatedAt,
  });

  /// Get total currency spent
  int getTotalSpent() => totalXpSpent + totalCoinsSpent + totalPremiumSpent;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalXpSpent': totalXpSpent,
        'totalCoinsSpent': totalCoinsSpent,
        'totalPremiumSpent': totalPremiumSpent,
        'totalPurchases': totalPurchases,
        'totalItemsOwned': totalItemsOwned,
        'firstPurchaseDate': firstPurchaseDate.toIso8601String(),
        'lastPurchaseDate': lastPurchaseDate.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory ShopStats.fromJson(Map<String, dynamic> json) => ShopStats(
        userId: json['userId'] as String,
        totalXpSpent: json['totalXpSpent'] as int? ?? 0,
        totalCoinsSpent: json['totalCoinsSpent'] as int? ?? 0,
        totalPremiumSpent: json['totalPremiumSpent'] as int? ?? 0,
        totalPurchases: json['totalPurchases'] as int? ?? 0,
        totalItemsOwned: json['totalItemsOwned'] as int? ?? 0,
        firstPurchaseDate:
            DateTime.parse(json['firstPurchaseDate'] as String),
        lastPurchaseDate:
            DateTime.parse(json['lastPurchaseDate'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Shop catalog and user data
class ShopCatalog {
  final List<ShopItem> allItems;        // All available items
  final UserInventory inventory;        // User's inventory
  final ShopStats stats;                // User's shop statistics
  final DateTime generatedAt;

  ShopCatalog({
    required this.allItems,
    required this.inventory,
    required this.stats,
    required this.generatedAt,
  });

  /// Get item by ID
  ShopItem? getItem(String itemId) =>
      allItems.firstWhere(
        (item) => item.itemId == itemId,
        orElse: () => throw Exception('Item not found: $itemId'),
      );

  /// Get items by type
  List<ShopItem> getByType(ShopItemType type) =>
      allItems.where((item) => item.type == type).toList();

  /// Get items by rarity
  List<ShopItem> getByRarity(ItemRarity rarity) =>
      allItems.where((item) => item.rarity == rarity).toList();

  /// Get available items (in stock, not expired)
  List<ShopItem> getAvailableItems() =>
      allItems.where((item) => item.isAvailable).toList();

  /// Get featured items
  List<ShopItem> getFeaturedItems() =>
      allItems.where((item) => item.isFeatured && item.isAvailable).toList();

  /// Get new items
  List<ShopItem> getNewItems() =>
      allItems.where((item) => item.isNew && item.isAvailable).toList();

  /// Get items user can afford
  List<ShopItem> getAffordableItems(int xp, int coins) =>
      allItems
          .where((item) =>
              (item.xpCost > 0 && item.xpCost <= xp) ||
              (item.coinCost > 0 && item.coinCost <= coins))
          .toList();

  Map<String, dynamic> toJson() => {
        'allItems': allItems.map((item) => item.toJson()).toList(),
        'inventory': inventory.toJson(),
        'stats': stats.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ShopCatalog.fromJson(Map<String, dynamic> json) => ShopCatalog(
        allItems: ((json['allItems'] as List?) ?? [])
            .map((item) => ShopItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        inventory: UserInventory.fromJson(
            json['inventory'] as Map<String, dynamic>),
        stats: ShopStats.fromJson(json['stats'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
