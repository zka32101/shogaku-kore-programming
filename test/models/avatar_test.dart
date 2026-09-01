import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/avatar.dart';

void main() {
  group('Avatar', () {
    const testAvatar = Avatar(
      id: 'avatar_1',
      name: 'Ninja',
      emoji: '🥷',
      isDefault: true,
      price: 0,
    );

    test('creates instance with required fields', () {
      expect(testAvatar.id, 'avatar_1');
      expect(testAvatar.name, 'Ninja');
      expect(testAvatar.emoji, '🥷');
      expect(testAvatar.isDefault, true);
      expect(testAvatar.price, 0);
    });

    test('toJson converts avatar to JSON', () {
      final json = testAvatar.toJson();

      expect(json['id'], 'avatar_1');
      expect(json['name'], 'Ninja');
      expect(json['emoji'], '🥷');
      expect(json['isDefault'], true);
      expect(json['price'], 0);
    });

    test('fromJson creates avatar from JSON', () {
      final json = {
        'id': 'avatar_1',
        'name': 'Ninja',
        'emoji': '🥷',
        'isDefault': true,
        'price': 0,
      };

      final avatar = Avatar.fromJson(json);

      expect(avatar.id, 'avatar_1');
      expect(avatar.name, 'Ninja');
      expect(avatar.emoji, '🥷');
      expect(avatar.isDefault, true);
      expect(avatar.price, 0);
    });

    test('fromJson handles missing isDefault', () {
      final json = {
        'id': 'avatar_1',
        'name': 'Ninja',
        'emoji': '🥷',
        'price': 0,
      };

      final avatar = Avatar.fromJson(json);

      expect(avatar.isDefault, false);
    });

    test('fromJson handles missing price', () {
      final json = {
        'id': 'avatar_1',
        'name': 'Ninja',
        'emoji': '🥷',
        'isDefault': true,
      };

      final avatar = Avatar.fromJson(json);

      expect(avatar.price, 0);
    });

    test('equality based on id', () {
      const avatar1 = Avatar(
        id: 'avatar_1',
        name: 'Ninja',
        emoji: '🥷',
      );
      const avatar2 = Avatar(
        id: 'avatar_1',
        name: 'Different Name',
        emoji: '🎨',
      );
      const avatar3 = Avatar(
        id: 'avatar_2',
        name: 'Ninja',
        emoji: '🥷',
      );

      expect(avatar1 == avatar2, true);
      expect(avatar1 == avatar3, false);
    });

    test('hashCode based on id', () {
      const avatar1 = Avatar(
        id: 'avatar_1',
        name: 'Ninja',
        emoji: '🥷',
      );
      const avatar2 = Avatar(
        id: 'avatar_1',
        name: 'Different Name',
        emoji: '🎨',
      );

      expect(avatar1.hashCode == avatar2.hashCode, true);
    });

    test('JSON round-trip preserves data', () {
      const avatar = Avatar(
        id: 'avatar_5',
        name: 'Dragon Master',
        emoji: '🐉',
        isDefault: false,
        price: 200,
      );

      final json = avatar.toJson();
      final restored = Avatar.fromJson(json);

      expect(restored, avatar);
      expect(restored.toJson(), json);
    });
  });
}
