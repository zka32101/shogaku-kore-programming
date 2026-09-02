import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/character_customization.dart';

void main() {
  group('CharacterAppearance', () {
    test('creates appearance with required fields', () {
      final app = CharacterAppearance(
        appearanceId: 'app1',
        userId: 'user1',
        gender: CharacterGender.female,
        headStyle: HeadStyle.round,
        eyeColor: EyeColor.blue,
        hairStyle: HairStyle.long,
        hairColor: HairColor.blonde,
        skinTone: SkinTone.light,
      );

      expect(app.appearanceId, 'app1');
      expect(app.gender, CharacterGender.female);
    });

    test('toJson and fromJson roundtrip', () {
      final app = CharacterAppearance(
        appearanceId: 'app1',
        userId: 'user1',
        gender: CharacterGender.male,
        headStyle: HeadStyle.square,
        eyeColor: EyeColor.green,
        hairStyle: HairStyle.short,
        hairColor: HairColor.black,
        skinTone: SkinTone.medium,
      );

      final json = app.toJson();
      final restored = CharacterAppearance.fromJson(json);
      expect(restored.appearanceId, app.appearanceId);
      expect(restored.gender, app.gender);
    });
  });

  group('CosmeticItem', () {
    test('creates cosmetic with required fields', () {
      final now = DateTime.now();
      final cosmetic = CosmeticItem(
        cosmeticId: 'cos1',
        name: '制服',
        description: 'School uniform',
        rarity: CosmeticRarity.common,
        outfitType: OutfitType.school,
        releasedAt: now,
      );

      expect(cosmetic.cosmeticId, 'cos1');
      expect(cosmetic.isAvailable, true);
    });

    test('isAvailable returns false for discontinued', () {
      final now = DateTime.now();
      final cosmetic = CosmeticItem(
        cosmeticId: 'cos1',
        name: 'Test',
        description: 'Test',
        rarity: CosmeticRarity.rare,
        releasedAt: now,
        discontinuedAt: now.subtract(const Duration(days: 1)),
      );

      expect(cosmetic.isAvailable, false);
    });

    test('getRarityColor returns correct colors', () {
      final now = DateTime.now();

      final common = CosmeticItem(
        cosmeticId: 'c1',
        name: 'Test',
        description: 'Test',
        rarity: CosmeticRarity.common,
        releasedAt: now,
      );
      expect(common.getRarityColor(), 'gray');

      final legendary = CosmeticItem(
        cosmeticId: 'c2',
        name: 'Test',
        description: 'Test',
        rarity: CosmeticRarity.legendary,
        releasedAt: now,
      );
      expect(legendary.getRarityColor(), 'orange');

      final mythic = CosmeticItem(
        cosmeticId: 'c3',
        name: 'Test',
        description: 'Test',
        rarity: CosmeticRarity.mythic,
        releasedAt: now,
      );
      expect(mythic.getRarityColor(), 'gold');
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final cosmetic = CosmeticItem(
        cosmeticId: 'cos1',
        name: '制服',
        description: 'School uniform',
        rarity: CosmeticRarity.rare,
        outfitType: OutfitType.school,
        releasedAt: now,
        timesEquipped: 5,
      );

      final json = cosmetic.toJson();
      final restored = CosmeticItem.fromJson(json);
      expect(restored.cosmeticId, 'cos1');
      expect(restored.timesEquipped, 5);
    });
  });

  group('OwnedCosmetic', () {
    test('creates owned cosmetic', () {
      final now = DateTime.now();
      final owned = OwnedCosmetic(
        ownedCosmeticId: 'owned1',
        userId: 'user1',
        cosmeticId: 'cos1',
        acquiredAt: now,
      );

      expect(owned.isEquipped, false);
      expect(owned.timesWorn, 0);
    });

    test('toJson serializes owned cosmetic', () {
      final now = DateTime.now();
      final owned = OwnedCosmetic(
        ownedCosmeticId: 'owned1',
        userId: 'user1',
        cosmeticId: 'cos1',
        isEquipped: true,
        acquiredAt: now,
        timesWorn: 3,
      );

      final json = owned.toJson();
      expect(json['isEquipped'], true);
      expect(json['timesWorn'], 3);
    });
  });

  group('CharacterLoadout', () {
    test('creates loadout', () {
      final now = DateTime.now();
      final app = CharacterAppearance(
        appearanceId: 'app1',
        userId: 'user1',
        gender: CharacterGender.female,
        headStyle: HeadStyle.round,
        eyeColor: EyeColor.blue,
        hairStyle: HairStyle.long,
        hairColor: HairColor.blonde,
        skinTone: SkinTone.light,
      );

      final loadout = CharacterLoadout(
        loadoutId: 'load1',
        userId: 'user1',
        loadoutName: 'Outfit 1',
        appearance: app,
        createdAt: now,
        lastUsedAt: now,
      );

      expect(loadout.loadoutId, 'load1');
      expect(loadout.equippedAccessories.isEmpty, true);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final app = CharacterAppearance(
        appearanceId: 'app1',
        userId: 'user1',
        gender: CharacterGender.male,
        headStyle: HeadStyle.square,
        eyeColor: EyeColor.green,
        hairStyle: HairStyle.short,
        hairColor: HairColor.black,
        skinTone: SkinTone.medium,
      );

      final loadout = CharacterLoadout(
        loadoutId: 'load1',
        userId: 'user1',
        loadoutName: 'Main',
        appearance: app,
        createdAt: now,
        lastUsedAt: now,
        isFavorite: true,
      );

      final json = loadout.toJson();
      final restored = CharacterLoadout.fromJson(json);
      expect(restored.loadoutId, 'load1');
      expect(restored.isFavorite, true);
    });
  });

  group('CustomizationStatistics', () {
    test('creates statistics', () {
      final now = DateTime.now();
      final stats = CustomizationStatistics(
        userId: 'user1',
        firstCustomizationAt: now,
        lastCustomizationAt: now,
        lastUpdatedAt: now,
      );

      expect(stats.userId, 'user1');
      expect(stats.totalCosmeticsOwned, 0);
    });

    test('getCustomizationTier returns correct tiers', () {
      final now = DateTime.now();

      final beginner = CustomizationStatistics(
        userId: 'user1',
        totalCosmeticsOwned: 2,
        firstCustomizationAt: now,
        lastCustomizationAt: now,
        lastUpdatedAt: now,
      );
      expect(beginner.getCustomizationTier(), '初期段階');

      const stylist = CustomizationStatistics(
        userId: 'user2',
        totalCosmeticsOwned: 10,
        firstCustomizationAt: DateTime(2024),
        lastCustomizationAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(stylist.getCustomizationTier(), 'スタイリスト');

      const fashionista = CustomizationStatistics(
        userId: 'user3',
        totalCosmeticsOwned: 25,
        firstCustomizationAt: DateTime(2024),
        lastCustomizationAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(fashionista.getCustomizationTier(), 'ファッショニスタ');

      const designer = CustomizationStatistics(
        userId: 'user4',
        totalCosmeticsOwned: 40,
        firstCustomizationAt: DateTime(2024),
        lastCustomizationAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(designer.getCustomizationTier(), 'ファッションデザイナー');

      const master = CustomizationStatistics(
        userId: 'user5',
        totalCosmeticsOwned: 60,
        firstCustomizationAt: DateTime(2024),
        lastCustomizationAt: DateTime(2024),
        lastUpdatedAt: DateTime(2024),
      );
      expect(master.getCustomizationTier(), 'スタイルマスター');
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final stats = CustomizationStatistics(
        userId: 'user1',
        totalCosmeticsOwned: 20,
        legendaryCosmeticsOwned: 2,
        firstCustomizationAt: now,
        lastCustomizationAt: now,
        lastUpdatedAt: now,
      );

      final json = stats.toJson();
      final restored = CustomizationStatistics.fromJson(json);
      expect(restored.totalCosmeticsOwned, 20);
      expect(restored.legendaryCosmeticsOwned, 2);
    });
  });

  group('CharacterCustomizationCollection', () {
    test('creates collection', () {
      final now = DateTime.now();
      final app = CharacterAppearance(
        appearanceId: 'app1',
        userId: 'user1',
        gender: CharacterGender.female,
        headStyle: HeadStyle.round,
        eyeColor: EyeColor.blue,
        hairStyle: HairStyle.long,
        hairColor: HairColor.blonde,
        skinTone: SkinTone.light,
      );
      final loadout = CharacterLoadout(
        loadoutId: 'load1',
        userId: 'user1',
        loadoutName: 'Main',
        appearance: app,
        createdAt: now,
        lastUsedAt: now,
      );
      final stats = CustomizationStatistics(
        userId: 'user1',
        firstCustomizationAt: now,
        lastCustomizationAt: now,
        lastUpdatedAt: now,
      );

      final collection = CharacterCustomizationCollection(
        userId: 'user1',
        activeLoadout: loadout,
        loadouts: [loadout],
        allCosmetics: [],
        ownedCosmetics: [],
        statistics: stats,
        generatedAt: now,
      );

      expect(collection.userId, 'user1');
      expect(collection.loadouts.length, 1);
    });

    test('getOwnedOutfits filters outfits', () {
      final now = DateTime.now();
      final app = CharacterAppearance(
        appearanceId: 'app1',
        userId: 'user1',
        gender: CharacterGender.female,
        headStyle: HeadStyle.round,
        eyeColor: EyeColor.blue,
        hairStyle: HairStyle.long,
        hairColor: HairColor.blonde,
        skinTone: SkinTone.light,
      );
      final outfit = CosmeticItem(
        cosmeticId: 'outfit1',
        name: 'School',
        description: 'Test',
        rarity: CosmeticRarity.common,
        outfitType: OutfitType.school,
        releasedAt: now,
      );
      final owned = OwnedCosmetic(
        ownedCosmeticId: 'owned1',
        userId: 'user1',
        cosmeticId: 'outfit1',
        acquiredAt: now,
      );
      final loadout = CharacterLoadout(
        loadoutId: 'load1',
        userId: 'user1',
        loadoutName: 'Main',
        appearance: app,
        createdAt: now,
        lastUsedAt: now,
      );
      final stats = CustomizationStatistics(
        userId: 'user1',
        firstCustomizationAt: now,
        lastCustomizationAt: now,
        lastUpdatedAt: now,
      );

      final collection = CharacterCustomizationCollection(
        userId: 'user1',
        activeLoadout: loadout,
        loadouts: [loadout],
        allCosmetics: [outfit],
        ownedCosmetics: [owned],
        statistics: stats,
        generatedAt: now,
      );

      final outfits = collection.getOwnedOutfits();
      expect(outfits.length, 1);
    });

    test('toJson and fromJson roundtrip', () {
      final now = DateTime.now();
      final app = CharacterAppearance(
        appearanceId: 'app1',
        userId: 'user1',
        gender: CharacterGender.female,
        headStyle: HeadStyle.round,
        eyeColor: EyeColor.blue,
        hairStyle: HairStyle.long,
        hairColor: HairColor.blonde,
        skinTone: SkinTone.light,
      );
      final loadout = CharacterLoadout(
        loadoutId: 'load1',
        userId: 'user1',
        loadoutName: 'Main',
        appearance: app,
        createdAt: now,
        lastUsedAt: now,
      );
      final stats = CustomizationStatistics(
        userId: 'user1',
        firstCustomizationAt: now,
        lastCustomizationAt: now,
        lastUpdatedAt: now,
      );

      final collection = CharacterCustomizationCollection(
        userId: 'user1',
        activeLoadout: loadout,
        loadouts: [loadout],
        allCosmetics: [],
        ownedCosmetics: [],
        statistics: stats,
        generatedAt: now,
      );

      final json = collection.toJson();
      final restored = CharacterCustomizationCollection.fromJson(json);
      expect(restored.userId, 'user1');
      expect(restored.loadouts.length, 1);
    });
  });
}
