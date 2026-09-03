/// Character gender
enum CharacterGender {
  male,
  female,
  nonBinary,
  custom,
}

/// Head style
enum HeadStyle {
  round,
  oval,
  square,
  triangle,
}

/// Eye color
enum EyeColor {
  brown,
  blue,
  green,
  gray,
  purple,
  red,
}

/// Hair style
enum HairStyle {
  short,
  medium,
  long,
  curly,
  straight,
  wavy,
  afro,
  bald,
}

/// Hair color
enum HairColor {
  black,
  brown,
  blonde,
  red,
  purple,
  blue,
  green,
  gray,
  pink,
  white,
}

/// Skin tone
enum SkinTone {
  veryLight,
  light,
  medium,
  tan,
  deep,
  dark,
  green,
  blue,
}

/// Outfit type
enum OutfitType {
  casual,
  formal,
  sports,
  school,
  fantasy,
  futuristic,
  traditional,
  seasonal,
}

/// Accessory type
enum AccessoryType {
  hat,
  glasses,
  earrings,
  necklace,
  bracelet,
  ring,
  watch,
  bag,
}

/// Rarity of cosmetics
enum CosmeticRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

/// Character appearance settings
class CharacterAppearance {
  final String appearanceId;
  final String userId;
  final CharacterGender gender;
  final HeadStyle headStyle;
  final EyeColor eyeColor;
  final HairStyle hairStyle;
  final HairColor hairColor;
  final SkinTone skinTone;
  final String? customFeatures;        // Custom description for features
  final Map<String, dynamic>? metadata;

  CharacterAppearance({
    required this.appearanceId,
    required this.userId,
    required this.gender,
    required this.headStyle,
    required this.eyeColor,
    required this.hairStyle,
    required this.hairColor,
    required this.skinTone,
    this.customFeatures,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'appearanceId': appearanceId,
        'userId': userId,
        'gender': gender.name,
        'headStyle': headStyle.name,
        'eyeColor': eyeColor.name,
        'hairStyle': hairStyle.name,
        'hairColor': hairColor.name,
        'skinTone': skinTone.name,
        'customFeatures': customFeatures,
        'metadata': metadata,
      };

  factory CharacterAppearance.fromJson(Map<String, dynamic> json) =>
      CharacterAppearance(
        appearanceId: json['appearanceId'] as String,
        userId: json['userId'] as String,
        gender: CharacterGender.values.byName(json['gender'] as String),
        headStyle: HeadStyle.values.byName(json['headStyle'] as String),
        eyeColor: EyeColor.values.byName(json['eyeColor'] as String),
        hairStyle: HairStyle.values.byName(json['hairStyle'] as String),
        hairColor: HairColor.values.byName(json['hairColor'] as String),
        skinTone: SkinTone.values.byName(json['skinTone'] as String),
        customFeatures: json['customFeatures'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Cosmetic item (outfit, accessory, etc.)
class CosmeticItem {
  final String cosmeticId;
  final String name;                  // Cosmetic name (Japanese)
  final String description;
  final CosmeticRarity rarity;
  final OutfitType? outfitType;       // For outfits
  final AccessoryType? accessoryType; // For accessories
  final String? imageId;
  final int? requiredLevel;           // Minimum level to equip
  final int? requiredTier;            // Minimum tier/rank
  final bool isHidden;                // Hidden/secret cosmetic
  final DateTime releasedAt;
  final DateTime? discontinuedAt;     // When removed from availability
  final bool isLimited;               // Limited time only
  final DateTime? limitedUntil;
  final int timesEquipped;            // How many times equipped
  final Map<String, dynamic>? metadata;

  CosmeticItem({
    required this.cosmeticId,
    required this.name,
    required this.description,
    required this.rarity,
    this.outfitType,
    this.accessoryType,
    this.imageId,
    this.requiredLevel,
    this.requiredTier,
    this.isHidden = false,
    required this.releasedAt,
    this.discontinuedAt,
    this.isLimited = false,
    this.limitedUntil,
    this.timesEquipped = 0,
    this.metadata,
  });

  /// Check if cosmetic is available
  bool get isAvailable {
    final now = DateTime.now();
    if (discontinuedAt != null && now.isAfter(discontinuedAt!)) return false;
    if (isLimited && limitedUntil != null && now.isAfter(limitedUntil!)) return false;
    return true;
  }

  /// Get rarity color
  String getRarityColor() {
    switch (rarity) {
      case CosmeticRarity.common:
        return 'gray';
      case CosmeticRarity.uncommon:
        return 'green';
      case CosmeticRarity.rare:
        return 'blue';
      case CosmeticRarity.epic:
        return 'purple';
      case CosmeticRarity.legendary:
        return 'orange';
      case CosmeticRarity.mythic:
        return 'gold';
    }
  }

  Map<String, dynamic> toJson() => {
        'cosmeticId': cosmeticId,
        'name': name,
        'description': description,
        'rarity': rarity.name,
        'outfitType': outfitType?.name,
        'accessoryType': accessoryType?.name,
        'imageId': imageId,
        'requiredLevel': requiredLevel,
        'requiredTier': requiredTier,
        'isHidden': isHidden,
        'releasedAt': releasedAt.toIso8601String(),
        'discontinuedAt': discontinuedAt?.toIso8601String(),
        'isLimited': isLimited,
        'limitedUntil': limitedUntil?.toIso8601String(),
        'timesEquipped': timesEquipped,
        'metadata': metadata,
      };

  factory CosmeticItem.fromJson(Map<String, dynamic> json) => CosmeticItem(
        cosmeticId: json['cosmeticId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        rarity: CosmeticRarity.values.byName(json['rarity'] as String),
        outfitType: json['outfitType'] != null
            ? OutfitType.values.byName(json['outfitType'] as String)
            : null,
        accessoryType: json['accessoryType'] != null
            ? AccessoryType.values.byName(json['accessoryType'] as String)
            : null,
        imageId: json['imageId'] as String?,
        requiredLevel: json['requiredLevel'] as int?,
        requiredTier: json['requiredTier'] as int?,
        isHidden: json['isHidden'] as bool? ?? false,
        releasedAt: DateTime.parse(json['releasedAt'] as String),
        discontinuedAt: json['discontinuedAt'] != null
            ? DateTime.parse(json['discontinuedAt'] as String)
            : null,
        isLimited: json['isLimited'] as bool? ?? false,
        limitedUntil: json['limitedUntil'] != null
            ? DateTime.parse(json['limitedUntil'] as String)
            : null,
        timesEquipped: json['timesEquipped'] as int? ?? 0,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// User's owned cosmetic
class OwnedCosmetic {
  final String ownedCosmeticId;
  final String userId;
  final String cosmeticId;
  final bool isEquipped;              // Currently being worn
  final DateTime acquiredAt;
  final DateTime? lastEquippedAt;
  final int timesWorn;                // Times worn/used
  final Map<String, dynamic>? metadata;

  OwnedCosmetic({
    required this.ownedCosmeticId,
    required this.userId,
    required this.cosmeticId,
    this.isEquipped = false,
    required this.acquiredAt,
    this.lastEquippedAt,
    this.timesWorn = 0,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'ownedCosmeticId': ownedCosmeticId,
        'userId': userId,
        'cosmeticId': cosmeticId,
        'isEquipped': isEquipped,
        'acquiredAt': acquiredAt.toIso8601String(),
        'lastEquippedAt': lastEquippedAt?.toIso8601String(),
        'timesWorn': timesWorn,
        'metadata': metadata,
      };

  factory OwnedCosmetic.fromJson(Map<String, dynamic> json) => OwnedCosmetic(
        ownedCosmeticId: json['ownedCosmeticId'] as String,
        userId: json['userId'] as String,
        cosmeticId: json['cosmeticId'] as String,
        isEquipped: json['isEquipped'] as bool? ?? false,
        acquiredAt: DateTime.parse(json['acquiredAt'] as String),
        lastEquippedAt: json['lastEquippedAt'] != null
            ? DateTime.parse(json['lastEquippedAt'] as String)
            : null,
        timesWorn: json['timesWorn'] as int? ?? 0,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Current character loadout/preset
class CharacterLoadout {
  final String loadoutId;
  final String userId;
  final String loadoutName;           // Loadout name (Japanese)
  final CharacterAppearance appearance;
  final String? equippedOutfitId;     // Equipped outfit cosmetic
  final List<String> equippedAccessories; // Equipped accessory IDs (max 3)
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final bool isFavorite;
  final Map<String, dynamic>? metadata;

  CharacterLoadout({
    required this.loadoutId,
    required this.userId,
    required this.loadoutName,
    required this.appearance,
    this.equippedOutfitId,
    this.equippedAccessories = const [],
    required this.createdAt,
    required this.lastUsedAt,
    this.isFavorite = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'loadoutId': loadoutId,
        'userId': userId,
        'loadoutName': loadoutName,
        'appearance': appearance.toJson(),
        'equippedOutfitId': equippedOutfitId,
        'equippedAccessories': equippedAccessories,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'isFavorite': isFavorite,
        'metadata': metadata,
      };

  factory CharacterLoadout.fromJson(Map<String, dynamic> json) => CharacterLoadout(
        loadoutId: json['loadoutId'] as String,
        userId: json['userId'] as String,
        loadoutName: json['loadoutName'] as String,
        appearance: CharacterAppearance.fromJson(
            json['appearance'] as Map<String, dynamic>),
        equippedOutfitId: json['equippedOutfitId'] as String?,
        equippedAccessories:
            ((json['equippedAccessories'] as List?) ?? []).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
        isFavorite: json['isFavorite'] as bool? ?? false,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Character customization statistics
class CustomizationStatistics {
  final String userId;
  final int totalCosmeticsOwned;
  final int outfitsOwned;
  final int accessoriesOwned;
  final int loadoutsCreated;
  final int rareOrBetterItems;        // Rare+ cosmetics
  final int legendaryCosmeticsOwned;
  final int customizationsChanged;    // Times appearance changed
  final DateTime firstCustomizationAt;
  final DateTime lastCustomizationAt;
  final DateTime lastUpdatedAt;

  CustomizationStatistics({
    required this.userId,
    this.totalCosmeticsOwned = 0,
    this.outfitsOwned = 0,
    this.accessoriesOwned = 0,
    this.loadoutsCreated = 0,
    this.rareOrBetterItems = 0,
    this.legendaryCosmeticsOwned = 0,
    this.customizationsChanged = 0,
    required this.firstCustomizationAt,
    required this.lastCustomizationAt,
    required this.lastUpdatedAt,
  });

  /// Get customization tier
  String getCustomizationTier() {
    if (totalCosmeticsOwned < 5) return '初期段階';
    if (totalCosmeticsOwned < 15) return 'スタイリスト';
    if (totalCosmeticsOwned < 30) return 'ファッショニスタ';
    if (totalCosmeticsOwned < 50) return 'ファッションデザイナー';
    return 'スタイルマスター';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalCosmeticsOwned': totalCosmeticsOwned,
        'outfitsOwned': outfitsOwned,
        'accessoriesOwned': accessoriesOwned,
        'loadoutsCreated': loadoutsCreated,
        'rareOrBetterItems': rareOrBetterItems,
        'legendaryCosmeticsOwned': legendaryCosmeticsOwned,
        'customizationsChanged': customizationsChanged,
        'firstCustomizationAt': firstCustomizationAt.toIso8601String(),
        'lastCustomizationAt': lastCustomizationAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory CustomizationStatistics.fromJson(Map<String, dynamic> json) =>
      CustomizationStatistics(
        userId: json['userId'] as String,
        totalCosmeticsOwned: json['totalCosmeticsOwned'] as int? ?? 0,
        outfitsOwned: json['outfitsOwned'] as int? ?? 0,
        accessoriesOwned: json['accessoriesOwned'] as int? ?? 0,
        loadoutsCreated: json['loadoutsCreated'] as int? ?? 0,
        rareOrBetterItems: json['rareOrBetterItems'] as int? ?? 0,
        legendaryCosmeticsOwned: json['legendaryCosmeticsOwned'] as int? ?? 0,
        customizationsChanged: json['customizationsChanged'] as int? ?? 0,
        firstCustomizationAt:
            DateTime.parse(json['firstCustomizationAt'] as String),
        lastCustomizationAt:
            DateTime.parse(json['lastCustomizationAt'] as String),
        lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      );
}

/// Complete character customization collection
class CharacterCustomizationCollection {
  final String userId;
  final CharacterLoadout activeLoadout;
  final List<CharacterLoadout> loadouts;           // Max 10
  final List<CosmeticItem> allCosmetics;           // Max 200
  final List<OwnedCosmetic> ownedCosmetics;        // Max 500
  final CustomizationStatistics statistics;
  final DateTime generatedAt;

  CharacterCustomizationCollection({
    required this.userId,
    required this.activeLoadout,
    required this.loadouts,
    required this.allCosmetics,
    required this.ownedCosmetics,
    required this.statistics,
    required this.generatedAt,
  });

  /// Get owned cosmetics by outfit type
  List<OwnedCosmetic> getOwnedOutfits() {
    final outfitIds = allCosmetics
        .where((c) => c.outfitType != null)
        .map((c) => c.cosmeticId)
        .toSet();
    return ownedCosmetics.where((o) => outfitIds.contains(o.cosmeticId)).toList();
  }

  /// Get owned cosmetics by accessory type
  List<OwnedCosmetic> getOwnedAccessories() {
    final accessoryIds = allCosmetics
        .where((c) => c.accessoryType != null)
        .map((c) => c.cosmeticId)
        .toSet();
    return ownedCosmetics.where((o) => accessoryIds.contains(o.cosmeticId)).toList();
  }

  /// Get cosmetics by rarity
  List<CosmeticItem> getCosmeticsByRarity(CosmeticRarity rarity) =>
      allCosmetics.where((c) => c.rarity == rarity).toList();

  /// Get available cosmetics for purchase
  List<CosmeticItem> getAvailableCosmetics() =>
      allCosmetics.where((c) => c.isAvailable).toList();

  /// Get featured/new cosmetics
  List<CosmeticItem> getFeaturedCosmetics() => allCosmetics
      .where((c) => c.isAvailable && !c.isHidden)
      .take(20)
      .toList();

  /// Get legendary cosmetics owned
  List<OwnedCosmetic> getLegendaryCosmeticsOwned() {
    final legendaryIds = allCosmetics
        .where((c) => c.rarity == CosmeticRarity.legendary)
        .map((c) => c.cosmeticId)
        .toSet();
    return ownedCosmetics.where((o) => legendaryIds.contains(o.cosmeticId)).toList();
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'activeLoadout': activeLoadout.toJson(),
        'loadouts': loadouts.map((l) => l.toJson()).toList(),
        'allCosmetics': allCosmetics.map((c) => c.toJson()).toList(),
        'ownedCosmetics': ownedCosmetics.map((o) => o.toJson()).toList(),
        'statistics': statistics.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory CharacterCustomizationCollection.fromJson(Map<String, dynamic> json) =>
      CharacterCustomizationCollection(
        userId: json['userId'] as String,
        activeLoadout:
            CharacterLoadout.fromJson(json['activeLoadout'] as Map<String, dynamic>),
        loadouts: ((json['loadouts'] as List?) ?? [])
            .map((l) => CharacterLoadout.fromJson(l as Map<String, dynamic>))
            .toList(),
        allCosmetics: ((json['allCosmetics'] as List?) ?? [])
            .map((c) => CosmeticItem.fromJson(c as Map<String, dynamic>))
            .toList(),
        ownedCosmetics: ((json['ownedCosmetics'] as List?) ?? [])
            .map((o) => OwnedCosmetic.fromJson(o as Map<String, dynamic>))
            .toList(),
        statistics: CustomizationStatistics.fromJson(
            json['statistics'] as Map<String, dynamic>),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
