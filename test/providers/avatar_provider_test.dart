import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shogaku_kore_programming/models/avatar.dart';
import 'package:shogaku_kore_programming/providers/avatar_provider.dart';

void main() {
  group('AvatarState', () {
    test('selectedAvatar returns correct avatar', () {
      final state = AvatarState(
        allAvatars: [
          const Avatar(
            id: 'avatar_1',
            name: 'Ninja',
            emoji: '🥷',
            isDefault: true,
            price: 0,
          ),
        ],
        selectedAvatarId: 'avatar_1',
        ownedAvatarIds: {},
      );

      expect(state.selectedAvatar.id, 'avatar_1');
      expect(state.selectedAvatar.name, 'Ninja');
    });

    test('availableAvatars includes defaults and owned premium', () {
      final avatar1 = const Avatar(
        id: 'avatar_1',
        name: 'Ninja',
        emoji: '🥷',
        isDefault: true,
        price: 0,
      );
      final avatar2 = const Avatar(
        id: 'avatar_2',
        name: 'Premium',
        emoji: '👑',
        isDefault: false,
        price: 200,
      );

      final state = AvatarState(
        allAvatars: [avatar1, avatar2],
        selectedAvatarId: 'avatar_1',
        ownedAvatarIds: {'avatar_2'},
      );

      expect(state.availableAvatars.length, 2);
      expect(
        state.availableAvatars.any((a) => a.id == 'avatar_1'),
        true,
      );
      expect(
        state.availableAvatars.any((a) => a.id == 'avatar_2'),
        true,
      );
    });

    test('purchasableAvatars excludes defaults and owned premium', () {
      final avatar1 = const Avatar(
        id: 'avatar_1',
        name: 'Ninja',
        emoji: '🥷',
        isDefault: true,
        price: 0,
      );
      final avatar2 = const Avatar(
        id: 'avatar_2',
        name: 'Premium 1',
        emoji: '👑',
        isDefault: false,
        price: 200,
      );
      final avatar3 = const Avatar(
        id: 'avatar_3',
        name: 'Premium 2',
        emoji: '🐉',
        isDefault: false,
        price: 250,
      );

      final state = AvatarState(
        allAvatars: [avatar1, avatar2, avatar3],
        selectedAvatarId: 'avatar_1',
        ownedAvatarIds: {'avatar_2'},
      );

      expect(state.purchasableAvatars.length, 1);
      expect(state.purchasableAvatars.first.id, 'avatar_3');
    });

    test('isAvatarOwned returns true for defaults', () {
      final avatar = const Avatar(
        id: 'avatar_1',
        name: 'Ninja',
        emoji: '🥷',
        isDefault: true,
        price: 0,
      );

      final state = AvatarState(
        allAvatars: [avatar],
        selectedAvatarId: 'avatar_1',
        ownedAvatarIds: {},
      );

      expect(state.isAvatarOwned('avatar_1'), true);
    });

    test('isAvatarOwned returns true for owned premium', () {
      final avatar = const Avatar(
        id: 'avatar_2',
        name: 'Premium',
        emoji: '👑',
        isDefault: false,
        price: 200,
      );

      final state = AvatarState(
        allAvatars: [avatar],
        selectedAvatarId: 'avatar_2',
        ownedAvatarIds: {'avatar_2'},
      );

      expect(state.isAvatarOwned('avatar_2'), true);
    });

    test('isAvatarOwned returns false for unowned premium', () {
      final avatar = const Avatar(
        id: 'avatar_2',
        name: 'Premium',
        emoji: '👑',
        isDefault: false,
        price: 200,
      );

      final state = AvatarState(
        allAvatars: [avatar],
        selectedAvatarId: 'avatar_1',
        ownedAvatarIds: {},
      );

      expect(state.isAvatarOwned('avatar_2'), false);
    });

    test('copyWith creates new instance with updated fields', () {
      final state1 = AvatarState(
        allAvatars: const [
          Avatar(
            id: 'avatar_1',
            name: 'Ninja',
            emoji: '🥷',
            isDefault: true,
            price: 0,
          ),
        ],
        selectedAvatarId: 'avatar_1',
        ownedAvatarIds: {},
      );

      final state2 = state1.copyWith(
        selectedAvatarId: 'avatar_1',
        ownedAvatarIds: {'avatar_2'},
      );

      expect(state2.selectedAvatarId, 'avatar_1');
      expect(state2.ownedAvatarIds.contains('avatar_2'), true);
      expect(identical(state1, state2), false);
    });
  });

  group('AvatarNotifier', () {
    test('initialization sets default values', (WidgetTester tester) async {
      final container = ProviderContainer();
      final notifier = AvatarNotifier(container.ref);

      expect(notifier.state.selectedAvatarId, 'avatar_1');
      expect(notifier.state.ownedAvatarIds.isEmpty, true);
      expect(notifier.state.allAvatars.length, 8); // 4 default + 4 premium
    });

    test('getAvatarById returns correct avatar', (WidgetTester tester) {
      final container = ProviderContainer();
      final notifier = AvatarNotifier(container.ref);

      final avatar = notifier.getAvatarById('avatar_1');
      expect(avatar?.id, 'avatar_1');
      expect(avatar?.name, 'Ninja');
    });

    test('getAvatarById returns null for invalid ID', (WidgetTester tester) {
      final container = ProviderContainer();
      final notifier = AvatarNotifier(container.ref);

      final avatar = notifier.getAvatarById('invalid_id');
      expect(avatar, null);
    });

    test('addOwnedAvatarForTesting adds avatar to owned', (WidgetTester tester) {
      final container = ProviderContainer();
      final notifier = AvatarNotifier(container.ref);

      notifier.addOwnedAvatarForTesting('avatar_5');

      expect(notifier.state.ownedAvatarIds.contains('avatar_5'), true);
    });

    test('clearOwnedAvatarsForTesting clears owned avatars', (WidgetTester tester) {
      final container = ProviderContainer();
      final notifier = AvatarNotifier(container.ref);

      notifier.addOwnedAvatarForTesting('avatar_5');
      notifier.addOwnedAvatarForTesting('avatar_6');
      notifier.clearOwnedAvatarsForTesting();

      expect(notifier.state.ownedAvatarIds.isEmpty, true);
    });

    test('all default avatars are accessible', (WidgetTester tester) {
      final container = ProviderContainer();
      final notifier = AvatarNotifier(container.ref);

      final defaultAvatars =
          notifier.state.allAvatars.where((a) => a.isDefault).toList();

      expect(defaultAvatars.length, 4);
      expect(defaultAvatars.every((a) => a.price == 0), true);
    });

    test('all premium avatars have prices', (WidgetTester tester) {
      final container = ProviderContainer();
      final notifier = AvatarNotifier(container.ref);

      final premiumAvatars =
          notifier.state.allAvatars.where((a) => !a.isDefault).toList();

      expect(premiumAvatars.length, 4);
      expect(premiumAvatars.every((a) => a.price > 0), true);
    });
  });
}
