import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/badge.dart';

void main() {
  group('Badge Model Tests', () {
    test('Badge creation with required parameters', () {
      final badge = Badge(
        id: 'test_badge',
        name: 'Test Badge',
        description: 'A test badge',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      expect(badge.id, 'test_badge');
      expect(badge.name, 'Test Badge');
      expect(badge.description, 'A test badge');
      expect(badge.emoji, '⭐');
      expect(badge.category, BadgeCategory.quiz);
      expect(badge.difficulty, BadgeDifficulty.bronze);
      expect(badge.requiredValue, 10);
      expect(badge.hint, null);
      expect(badge.unlockedAt, null);
    });

    test('Badge isUnlocked getter', () {
      final unlockedBadge = Badge(
        id: 'unlocked',
        name: 'Unlocked Badge',
        description: 'An unlocked badge',
        emoji: '✓',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 1,
        unlockedAt: DateTime.now(),
      );

      final lockedBadge = Badge(
        id: 'locked',
        name: 'Locked Badge',
        description: 'A locked badge',
        emoji: '🔒',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      expect(unlockedBadge.isUnlocked, true);
      expect(lockedBadge.isUnlocked, false);
    });

    test('Badge copyWith', () {
      final original = Badge(
        id: 'original',
        name: 'Original',
        description: 'Original description',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final copied = original.copyWith(
        name: 'Modified',
        difficulty: BadgeDifficulty.gold,
        unlockedAt: DateTime.now(),
      );

      expect(copied.id, 'original');
      expect(copied.name, 'Modified');
      expect(copied.description, 'Original description');
      expect(copied.emoji, '⭐');
      expect(copied.category, BadgeCategory.quiz);
      expect(copied.difficulty, BadgeDifficulty.gold);
      expect(copied.requiredValue, 10);
      expect(copied.unlockedAt, isNotNull);
    });

    test('Badge JSON serialization', () {
      final badge = Badge(
        id: 'json_test',
        name: 'JSON Test',
        description: 'Testing JSON serialization',
        emoji: '📝',
        category: BadgeCategory.progress,
        difficulty: BadgeDifficulty.silver,
        requiredValue: 25,
        hint: 'This is a hint',
      );

      final json = badge.toJson();

      expect(json['id'], 'json_test');
      expect(json['name'], 'JSON Test');
      expect(json['description'], 'Testing JSON serialization');
      expect(json['emoji'], '📝');
      expect(json['category'], 'progress');
      expect(json['difficulty'], 'silver');
      expect(json['requiredValue'], 25);
      expect(json['hint'], 'This is a hint');
      expect(json['unlockedAt'], null);
    });

    test('Badge JSON deserialization', () {
      final json = {
        'id': 'deserialized',
        'name': 'Deserialized Badge',
        'description': 'Deserialized from JSON',
        'emoji': '🎉',
        'category': 'quiz',
        'difficulty': 'gold',
        'requiredValue': 50,
        'hint': 'Solve 50 quizzes',
        'unlockedAt': null,
      };

      final badge = Badge.fromJson(json);

      expect(badge.id, 'deserialized');
      expect(badge.name, 'Deserialized Badge');
      expect(badge.description, 'Deserialized from JSON');
      expect(badge.emoji, '🎉');
      expect(badge.category, BadgeCategory.quiz);
      expect(badge.difficulty, BadgeDifficulty.gold);
      expect(badge.requiredValue, 50);
      expect(badge.hint, 'Solve 50 quizzes');
      expect(badge.unlockedAt, null);
    });

    test('Badge JSON round-trip serialization', () {
      final now = DateTime.now();
      final original = Badge(
        id: 'roundtrip',
        name: 'Round Trip Test',
        description: 'Testing round trip serialization',
        emoji: '🔄',
        category: BadgeCategory.consistency,
        difficulty: BadgeDifficulty.platinum,
        requiredValue: 100,
        hint: 'Keep consistent',
        unlockedAt: now,
      );

      final json = original.toJson();
      final deserialized = Badge.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.name, original.name);
      expect(deserialized.description, original.description);
      expect(deserialized.emoji, original.emoji);
      expect(deserialized.category, original.category);
      expect(deserialized.difficulty, original.difficulty);
      expect(deserialized.requiredValue, original.requiredValue);
      expect(deserialized.hint, original.hint);
      expect(
        deserialized.unlockedAt?.toIso8601String(),
        original.unlockedAt?.toIso8601String(),
      );
    });

    test('Badge equality', () {
      final badge1 = Badge(
        id: 'same_id',
        name: 'Badge 1',
        description: 'Description 1',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final badge2 = Badge(
        id: 'same_id',
        name: 'Badge 2',
        description: 'Description 2',
        emoji: '✨',
        category: BadgeCategory.progress,
        difficulty: BadgeDifficulty.gold,
        requiredValue: 50,
      );

      final badge3 = Badge(
        id: 'different_id',
        name: 'Badge 1',
        description: 'Description 1',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      expect(badge1, badge2); // Same ID
      expect(badge1, isNot(badge3)); // Different ID
    });

    test('Badge hash code', () {
      final badge1 = Badge(
        id: 'test_id',
        name: 'Test',
        description: 'Test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final badge2 = Badge(
        id: 'test_id',
        name: 'Different Name',
        description: 'Different Description',
        emoji: '✨',
        category: BadgeCategory.progress,
        difficulty: BadgeDifficulty.gold,
        requiredValue: 50,
      );

      expect(badge1.hashCode, badge2.hashCode);
    });

    test('Badge toString', () {
      final badge = Badge(
        id: 'test',
        name: 'Test Badge',
        description: 'A test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      expect(badge.toString(), contains('test'));
      expect(badge.toString(), contains('Test Badge'));
    });
  });

  group('BadgeCategory Enum Tests', () {
    test('BadgeCategory values', () {
      expect(BadgeCategory.values.length, 6);
      expect(BadgeCategory.values, contains(BadgeCategory.quiz));
      expect(BadgeCategory.values, contains(BadgeCategory.progress));
      expect(BadgeCategory.values, contains(BadgeCategory.consistency));
      expect(BadgeCategory.values, contains(BadgeCategory.mastery));
      expect(BadgeCategory.values, contains(BadgeCategory.social));
      expect(BadgeCategory.values, contains(BadgeCategory.special));
    });

    test('BadgeCategory name property', () {
      expect(BadgeCategory.quiz.name, 'quiz');
      expect(BadgeCategory.progress.name, 'progress');
      expect(BadgeCategory.consistency.name, 'consistency');
      expect(BadgeCategory.mastery.name, 'mastery');
      expect(BadgeCategory.social.name, 'social');
      expect(BadgeCategory.special.name, 'special');
    });

    test('BadgeCategory byName', () {
      expect(BadgeCategory.values.byName('quiz'), BadgeCategory.quiz);
      expect(BadgeCategory.values.byName('progress'), BadgeCategory.progress);
    });
  });

  group('BadgeDifficulty Enum Tests', () {
    test('BadgeDifficulty values', () {
      expect(BadgeDifficulty.values.length, 4);
      expect(BadgeDifficulty.values, contains(BadgeDifficulty.bronze));
      expect(BadgeDifficulty.values, contains(BadgeDifficulty.silver));
      expect(BadgeDifficulty.values, contains(BadgeDifficulty.gold));
      expect(BadgeDifficulty.values, contains(BadgeDifficulty.platinum));
    });

    test('BadgeDifficulty name property', () {
      expect(BadgeDifficulty.bronze.name, 'bronze');
      expect(BadgeDifficulty.silver.name, 'silver');
      expect(BadgeDifficulty.gold.name, 'gold');
      expect(BadgeDifficulty.platinum.name, 'platinum');
    });

    test('BadgeDifficulty byName', () {
      expect(BadgeDifficulty.values.byName('bronze'), BadgeDifficulty.bronze);
      expect(BadgeDifficulty.values.byName('platinum'), BadgeDifficulty.platinum);
    });
  });

  group('BadgeProgress Tests', () {
    test('BadgeProgress creation', () {
      final badge = Badge(
        id: 'test',
        name: 'Test Badge',
        description: 'Test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final progress = BadgeProgress(
        badge: badge,
        currentValue: 7,
        progress: 0.7,
      );

      expect(progress.badge.id, 'test');
      expect(progress.currentValue, 7);
      expect(progress.progress, 0.7);
    });

    test('BadgeProgress remainingValue', () {
      final badge = Badge(
        id: 'test',
        name: 'Test Badge',
        description: 'Test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final progress1 = BadgeProgress(
        badge: badge,
        currentValue: 7,
        progress: 0.7,
      );

      final progress2 = BadgeProgress(
        badge: badge,
        currentValue: 12,
        progress: 1.0,
      );

      expect(progress1.remainingValue, 3);
      expect(progress2.remainingValue, 2);
    });

    test('BadgeProgress canUnlock', () {
      final badge = Badge(
        id: 'test',
        name: 'Test Badge',
        description: 'Test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final notReady = BadgeProgress(
        badge: badge,
        currentValue: 5,
        progress: 0.5,
      );

      final ready = BadgeProgress(
        badge: badge,
        currentValue: 10,
        progress: 1.0,
      );

      final unlockedBadge = badge.copyWith(unlockedAt: DateTime.now());
      final alreadyUnlocked = BadgeProgress(
        badge: unlockedBadge,
        currentValue: 10,
        progress: 1.0,
      );

      expect(notReady.canUnlock, false);
      expect(ready.canUnlock, true);
      expect(alreadyUnlocked.canUnlock, false);
    });

    test('BadgeProgress toString', () {
      final badge = Badge(
        id: 'test',
        name: 'Test Badge',
        description: 'Test',
        emoji: '⭐',
        category: BadgeCategory.quiz,
        difficulty: BadgeDifficulty.bronze,
        requiredValue: 10,
      );

      final progress = BadgeProgress(
        badge: badge,
        currentValue: 7,
        progress: 0.7,
      );

      expect(progress.toString(), contains('Test Badge'));
      expect(progress.toString(), contains('7/10'));
    });
  });
}
