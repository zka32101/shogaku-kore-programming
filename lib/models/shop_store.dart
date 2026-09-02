/// Shop item category
enum ItemCategory {
  cosmetic,      // Avatar, banner, themes
  powerup,       // Temporary enhancements
  booster,       // XP/Coin multipliers
  consumable,    // Single-use items
  badge,         // Collectible badges
  special,       // Limited/seasonal items
}

/// Item rarity tier
enum ItemRarity {
  common,        // Standard items
  uncommon,      // More valuable
  rare,          // Hard to find
  epic,          // Very valuable
  legendary,     // Ultra-rare
}

/// Currency type for purchases
enum CurrencyType {
  coin,          // In-game currency
  premiumCoin,   // Premium/paid currency
  both,          // Accepts either
}

/// Shop item details
class ShopItem {
  final String itemId;
  final String name;                 // Item name (Japanese)
  final String description;
  final ItemCategory category;
  final ItemRarity rarity;
  final String? imageId;
  final int coinPrice;               // 0 if not available for coins
  final int? premiumCoinPrice;       // null if not available for premium
  final CurrencyType acceptedCurrency;
  final int? durationMinutes;        // For timed power-ups (null = permanent)
  final String? effectDescription;   // Effect if it's a power-up
  final int? maxStackable;           // Max times user can own this
  final bool isLimited;              // Limited availability
  final DateTime? limitedUntil;
  final int salesCount;              // Total times purchased
  final double averageRating;        // 1-5 stars
  final int reviewCount;
  final DateTime addedAt;
  final Map<String, dynamic>? metadata; // Custom data

  ShopItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    this.imageId,
    required this.coinPrice,
    this.premiumCoinPrice,
    required this.acceptedCurrency,
    this.durationMinutes,
    this.effectDescription,
    this.maxStackable,
    this.isLimited = false,
    this.limitedUntil,
    this.salesCount = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.addedAt,
    this.metadata,
  });

  /// Check if item is currently available
  bool get isAvailable {
    if (!isLimited) return true;
    if (limitedUntil == null) return true;
    return DateTime.now().isBefore(limitedUntil!);
  }

  /// Get time remaining for limited items
  Duration? get timeRemaining {
    if (!isLimited || limitedUntil == null) return null;
    final remaining = limitedUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Check if item is popular (high sales)
  bool get isPopular => salesCount >= 100;

  /// Get best price (coin or premium)
  int getBestPrice() {
    if (coinPrice > 0 && premiumCoinPrice == null) return coinPrice;
    if (premiumCoinPrice != null && coinPrice == 0) return premiumCoinPrice!;
    if (coinPrice > 0 && premiumCoinPrice != null) {
      return coinPrice < premiumCoinPrice! ? coinPrice : premiumCoinPrice!;
    }
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'name': name,
        'description': description,
        'category': category.name,
        'rarity': rarity.name,
        'imageId': imageId,
        'coinPrice': coinPrice,
        'premiumCoinPrice': premiumCoinPrice,
        'acceptedCurrency': acceptedCurrency.name,
        'durationMinutes': durationMinutes,
        'effectDescription': effectDescription,
        'maxStackable': maxStackable,
        'isLimited': isLimited,
        'limitedUntil': limitedUntil?.toIso8601String(),
        'salesCount': salesCount,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'addedAt': addedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        itemId: json['itemId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category: ItemCategory.values.byName(json['category'] as String),
        rarity: ItemRarity.values.byName(json['rarity'] as String),
        imageId: json['imageId'] as String?,
        coinPrice: json['coinPrice'] as int? ?? 0,
        premiumCoinPrice: json['premiumCoinPrice'] as int?,
        acceptedCurrency: CurrencyType.values.byName(json['acceptedCurrency'] as String? ?? 'both'),
        durationMinutes: json['durationMinutes'] as int?,
        effectDescription: json['effectDescription'] as String?,
        maxStackable: json['maxStackable'] as int?,
        isLimited: json['isLimited'] as bool? ?? false,
        limitedUntil: json['limitedUntil'] != null ? DateTime.parse(json['limitedUntil'] as String) : null,
        salesCount: json['salesCount'] as int? ?? 0,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        addedAt: DateTime.parse(json['addedAt'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// User's purchased item
class OwnedItem {
  final String ownedItemId;
  final String itemId;
  final String userId;
  final int quantity;                // How many owned (for stackable items)
  final DateTime purchasedAt;
  final DateTime? expiresAt;         // When power-up expires
  final bool isActive;               // For power-ups
  final int? purchasePrice;          // Price paid at time of purchase
  final String? purchaseCurrency;    // 'coin' or 'premiumCoin'

  OwnedItem({
    required this.ownedItemId,
    required this.itemId,
    required this.userId,
    required this.quantity,
    required this.purchasedAt,
    this.expiresAt,
    this.isActive = true,
    this.purchasePrice,
    this.purchaseCurrency,
  });

  /// Check if item is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get time remaining before expiration
  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Map<String, dynamic> toJson() => {
        'ownedItemId': ownedItemId,
        'itemId': itemId,
        'userId': userId,
        'quantity': quantity,
        'purchasedAt': purchasedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'isActive': isActive,
        'purchasePrice': purchasePrice,
        'purchaseCurrency': purchaseCurrency,
      };

  factory OwnedItem.fromJson(Map<String, dynamic> json) => OwnedItem(
        ownedItemId: json['ownedItemId'] as String,
        itemId: json['itemId'] as String,
        userId: json['userId'] as String,
        quantity: json['quantity'] as int? ?? 1,
        purchasedAt: DateTime.parse(json['purchasedAt'] as String),
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
        isActive: json['isActive'] as bool? ?? true,
        purchasePrice: json['purchasePrice'] as int?,
        purchaseCurrency: json['purchaseCurrency'] as String?,
      );
}

/// Purchase transaction record
class PurchaseTransaction {
  final String transactionId;
  final String userId;
  final String itemId;
  final String itemName;
  final int quantity;
  final int amountSpent;
  final String currencyUsed;         // 'coin' or 'premiumCoin'
  final DateTime purchasedAt;
  final String status;               // 'completed', 'pending', 'failed'
  final String? paymentMethod;       // For premium purchases
  final Map<String, dynamic>? metadata;

  PurchaseTransaction({
    required this.transactionId,
    required this.userId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.amountSpent,
    required this.currencyUsed,
    required this.purchasedAt,
    this.status = 'completed',
    this.paymentMethod,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'userId': userId,
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'amountSpent': amountSpent,
        'currencyUsed': currencyUsed,
        'purchasedAt': purchasedAt.toIso8601String(),
        'status': status,
        'paymentMethod': paymentMethod,
        'metadata': metadata,
      };

  factory PurchaseTransaction.fromJson(Map<String, dynamic> json) =>
      PurchaseTransaction(
        transactionId: json['transactionId'] as String,
        userId: json['userId'] as String,
        itemId: json['itemId'] as String,
        itemName: json['itemName'] as String,
        quantity: json['quantity'] as int? ?? 1,
        amountSpent: json['amountSpent'] as int,
        currencyUsed: json['currencyUsed'] as String,
        purchasedAt: DateTime.parse(json['purchasedAt'] as String),
        status: json['status'] as String? ?? 'completed',
        paymentMethod: json['paymentMethod'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// User's shop statistics
class ShopStatistics {
  final String userId;
  final int totalPurchases;
  final int totalSpent;              // Total coins/premium coins spent
  final int totalCoinSpent;
  final int totalPremiumCoinSpent;
  final int uniqueItemsOwned;
  final int cosmecticItemsOwned;
  final int powerupsOwned;
  final int consumablesUsed;
  final DateTime firstPurchaseAt;
  final DateTime lastPurchaseAt;
  final DateTime lastUpdatedAt;

  ShopStatistics({
    required this.userId,
    this.totalPurchases = 0,
    this.totalSpent = 0,
    this.totalCoinSpent = 0,
    this.totalPremiumCoinSpent = 0,
    this.uniqueItemsOwned = 0,
    this.cosmecticItemsOwned = 0,
    this.powerupsOwned = 0,
    this.consumablesUsed = 0,
    required this.firstPurchaseAt,
    required this.lastPurchaseAt,
    required this.lastUpdatedAt,
  });

  /// Get spender tier based on total spent
  String getSpenderTier() {
    if (totalSpent < 100) return 'ブラウザー';
    if (totalSpent < 500) return 'カジュアル';
    if (totalSpent < 2000) return 'コレクター';
    if (totalSpent < 5000) return 'エンスージアスト';
    return 'VIP';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalPurchases': totalPurchases,
        'totalSpent': totalSpent,
        'totalCoinSpent': totalCoinSpent,
        'totalPremiumCoinSpent': totalPremiumCoinSpent,
        'uniqueItemsOwned': uniqueItemsOwned,
        'cosmecticItemsOwned': cosmecticItemsOwned,
        'powerupsOwned': powerupsOwned,
        'consumablesUsed': consumablesUsed,
        'firstPurchaseAt': firstPurchaseAt.toIso8601String(),
        'lastPurchaseAt': lastPurchaseAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory ShopStatistics.fromJson(Map<String, dynamic> json) => ShopStatistics(
        userId: json['userId'] as String,
        totalPurchases: json['totalPurchases'] as int? ?? 0,
        totalSpent: json['totalSpent'] as int? ?? 0,
        totalCoinSpent: json['totalCoinSpent'] as int? ?? 0,
        totalPremiumCoinSpent: json['totalPremiumCoinSpent'] as int? ?? 0,
        uniqueItemsOwned: json['uniqueItemsOwned'] as int? ?? 0,
        cosmecticItemsOwned: json['cosmecticItemsOwned'] as int? ?? 0,
        powerupsOwned: json['powerupsOwned'] as int? ?? 0,
        consumablesUsed: json['consumablesUsed'] as int? ?? 0,
        firstPurchaseAt: DateTime.parse(json['firstPurchaseAt'] as String),
        lastPurchaseAt: DateTime.parse(json['lastPurchaseAt'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Complete shop collection
class ShopCollection {
  final String userId;
  final List<ShopItem> allItems;            // Max 200 items
  final List<OwnedItem> ownedItems;         // Max 1000
  final List<PurchaseTransaction> transactions; // Max 500
  final ShopStatistics statistics;
  final DateTime generatedAt;

  ShopCollection({
    required this.userId,
    required this.allItems,
    required this.ownedItems,
    required this.transactions,
    required this.statistics,
    required this.generatedAt,
  });

  /// Get available items for purchase
  List<ShopItem> getAvailableItems() => allItems.where((item) => item.isAvailable).toList();

  /// Get items by category
  List<ShopItem> getItemsByCategory(ItemCategory category) =>
      allItems.where((item) => item.category == category).toList();

  /// Get items by rarity
  List<ShopItem> getItemsByRarity(ItemRarity rarity) =>
      allItems.where((item) => item.rarity == rarity).toList();

  /// Get featured/popular items
  List<ShopItem> getFeaturedItems() => allItems
      .where((item) => item.isAvailable && (item.isPopular || item.isLimited))
      .take(20)
      .toList();

  /// Get active power-ups (not expired)
  List<OwnedItem> getActivePowerups() =>
      ownedItems.where((item) => !item.isExpired && item.isActive).toList();

  /// Get cosmetics owned
  List<OwnedItem> getOwnedCosmetics() =>
      ownedItems.where((item) => item.itemId.contains('cosmetic')).toList();

  /// Get recent purchases
  List<PurchaseTransaction> getRecentPurchases({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return transactions.where((t) => t.purchasedAt.isAfter(cutoff)).toList();
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'allItems': allItems.map((i) => i.toJson()).toList(),
        'ownedItems': ownedItems.map((i) => i.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'statistics': statistics.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory ShopCollection.fromJson(Map<String, dynamic> json) => ShopCollection(
        userId: json['userId'] as String,
        allItems: ((json['allItems'] as List?) ?? [])
            .map((i) => ShopItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        ownedItems: ((json['ownedItems'] as List?) ?? [])
            .map((i) => OwnedItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        transactions: ((json['transactions'] as List?) ?? [])
            .map((t) => PurchaseTransaction.fromJson(t as Map<String, dynamic>))
            .toList(),
        statistics: ShopStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
