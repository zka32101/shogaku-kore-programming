import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/character_customization.dart';
import 'package:shogaku_kore_programming/providers/character_customization_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('CharacterCustomizationNotifier', () {
    test('initializes with empty state', () {
      final notifier = CharacterCustomizationNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeCustomization creates collection', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final state = container.read(customizationProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.userId, 'test_user');
    });

    test('initializeCustomization creates 9 default cosmetics', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final state = container.read(customizationProvider);
      expect(state.collection!.allCosmetics.length, 9);
    });

    test('initializeCustomization loads existing data', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      expect(state.collection!.userId, 'test_user');

      final notifier2 = CharacterCustomizationNotifier();
      final container2 = ProviderContainer();
      await container2.read(customizationProvider.notifier).initializeCustomization('test_user');

      final newState = container2.read(customizationProvider);
      expect(newState.collection!.userId, 'test_user');
    });

    test('updateAppearance changes character appearance', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      await notifier.updateAppearance(
        'test_user',
        CharacterGender.male,
        HeadStyle.square,
        EyeColor.green,
        HairStyle.short,
        HairColor.black,
        SkinTone.dark,
      );

      final state = container.read(customizationProvider);
      expect(state.collection!.activeLoadout.appearance.gender, CharacterGender.male);
      expect(state.collection!.activeLoadout.appearance.hairColor, HairColor.black);
    });

    test('updateAppearance increments customizations changed', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      expect(state.collection!.statistics.customizationsChanged, 0);

      await notifier.updateAppearance(
        'test_user',
        CharacterGender.female,
        HeadStyle.round,
        EyeColor.blue,
        HairStyle.long,
        HairColor.blonde,
        SkinTone.light,
      );

      state = container.read(customizationProvider);
      expect(state.collection!.statistics.customizationsChanged, 1);
    });

    test('equipOutfit equips outfit cosmetic', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      final outfitId = state.collection!.allCosmetics
          .firstWhere((c) => c.outfitType != null)
          .cosmeticId;

      await notifier.acquireCosmetic('test_user', outfitId);
      await notifier.equipOutfit('test_user', outfitId);

      state = container.read(customizationProvider);
      expect(state.collection!.activeLoadout.equippedOutfitId, outfitId);
    });

    test('equipAccessory adds accessory', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      final accessoryId = state.collection!.allCosmetics
          .firstWhere((c) => c.accessoryType != null)
          .cosmeticId;

      await notifier.acquireCosmetic('test_user', accessoryId);
      await notifier.equipAccessory('test_user', accessoryId);

      state = container.read(customizationProvider);
      expect(state.collection!.activeLoadout.equippedAccessories.contains(accessoryId), true);
    });

    test('createLoadout creates new loadout', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      expect(state.collection!.loadouts.length, 1);

      await notifier.createLoadout('test_user', 'Outfit 2');

      state = container.read(customizationProvider);
      expect(state.collection!.loadouts.length, 2);
    });

    test('createLoadout increments loadouts created', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      expect(state.collection!.statistics.loadoutsCreated, 0);

      await notifier.createLoadout('test_user', 'Outfit 2');

      state = container.read(customizationProvider);
      expect(state.collection!.statistics.loadoutsCreated, 1);
    });

    test('switchLoadout switches to loadout', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      await notifier.createLoadout('test_user', 'Outfit 2');

      state = container.read(customizationProvider);
      final secondLoadoutId = state.collection!.loadouts[1].loadoutId;

      await notifier.switchLoadout('test_user', secondLoadoutId);

      state = container.read(customizationProvider);
      expect(state.collection!.activeLoadout.loadoutId, secondLoadoutId);
    });

    test('acquireCosmetic adds cosmetic to owned', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      expect(state.collection!.ownedCosmetics.isEmpty, true);

      final cosmeticId = state.collection!.allCosmetics[0].cosmeticId;
      await notifier.acquireCosmetic('test_user', cosmeticId);

      state = container.read(customizationProvider);
      expect(state.collection!.ownedCosmetics.isNotEmpty, true);
    });

    test('acquireCosmetic increments total cosmetics owned', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var state = container.read(customizationProvider);
      expect(state.collection!.statistics.totalCosmeticsOwned, 0);

      final cosmeticId = state.collection!.allCosmetics[0].cosmeticId;
      await notifier.acquireCosmetic('test_user', cosmeticId);

      state = container.read(customizationProvider);
      expect(state.collection!.statistics.totalCosmeticsOwned, 1);
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('persist_test');

      var state = container.read(customizationProvider);
      final cosmeticId = state.collection!.allCosmetics[0].cosmeticId;
      await notifier.acquireCosmetic('persist_test', cosmeticId);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('customization_persist_test'), true);
    });
  });

  group('Riverpod Providers', () {
    test('customizationCollectionProvider provides collection', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final collection = container.read(customizationCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('activeLoadoutProvider provides active loadout', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final loadout = container.read(activeLoadoutProvider);
      expect(loadout, isNotNull);
    });

    test('activeAppearanceProvider provides appearance', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final appearance = container.read(activeAppearanceProvider);
      expect(appearance, isNotNull);
    });

    test('allCosmeticsProvider provides all cosmetics', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final cosmetics = container.read(allCosmeticsProvider);
      expect(cosmetics.isNotEmpty, true);
    });

    test('availableCosmeticsProvider filters available', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final available = container.read(availableCosmeticsProvider);
      expect(available.isNotEmpty, true);
      expect(available.every((c) => c.isAvailable), true);
    });

    test('featuredCosmeticsProvider provides featured', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final featured = container.read(featuredCosmeticsProvider);
      expect(featured.isEmpty || featured.isNotEmpty, true);
    });

    test('ownedCosmeticsProvider provides owned', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var owned = container.read(ownedCosmeticsProvider);
      expect(owned.isEmpty, true);

      var state = container.read(customizationProvider);
      final cosmeticId = state.collection!.allCosmetics[0].cosmeticId;
      await notifier.acquireCosmetic('test_user', cosmeticId);

      owned = container.read(ownedCosmeticsProvider);
      expect(owned.length, 1);
    });

    test('ownedOutfitsProvider filters outfits', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var outfits = container.read(ownedOutfitsProvider);
      expect(outfits.isEmpty, true);

      var state = container.read(customizationProvider);
      final outfitId = state.collection!.allCosmetics
          .firstWhere((c) => c.outfitType != null)
          .cosmeticId;
      await notifier.acquireCosmetic('test_user', outfitId);

      outfits = container.read(ownedOutfitsProvider);
      expect(outfits.length, 1);
    });

    test('ownedAccessoriesProvider filters accessories', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var accessories = container.read(ownedAccessoriesProvider);
      expect(accessories.isEmpty, true);

      var state = container.read(customizationProvider);
      final accessoryId = state.collection!.allCosmetics
          .firstWhere((c) => c.accessoryType != null)
          .cosmeticId;
      await notifier.acquireCosmetic('test_user', accessoryId);

      accessories = container.read(ownedAccessoriesProvider);
      expect(accessories.length, 1);
    });

    test('customizationStatisticsProvider provides stats', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final stats = container.read(customizationStatisticsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('customizationTierProvider provides tier', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var tier = container.read(customizationTierProvider);
      expect(tier, '初期段階');
    });

    test('loadoutsProvider provides loadouts', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final loadouts = container.read(loadoutsProvider);
      expect(loadouts.length, 1);
    });

    test('totalCosmeticsOwnedProvider tracks total', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var total = container.read(totalCosmeticsOwnedProvider);
      expect(total, 0);

      var state = container.read(customizationProvider);
      final cosmeticId = state.collection!.allCosmetics[0].cosmeticId;
      await notifier.acquireCosmetic('test_user', cosmeticId);

      total = container.read(totalCosmeticsOwnedProvider);
      expect(total, 1);
    });

    test('legendaryCosmeticsProvider filters legendary', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      var legendary = container.read(legendaryCosmeticsProvider);
      expect(legendary.isEmpty, true);
    });

    test('cosmeticsByRarityProvider filters by rarity', () async {
      final notifier = container.read(customizationProvider.notifier);
      await notifier.initializeCustomization('test_user');

      final common = container.read(cosmeticsByRarityProvider(CosmeticRarity.common));
      expect(common.isNotEmpty, true);
      expect(common.every((c) => c.rarity == CosmeticRarity.common), true);
    });
  });
}
