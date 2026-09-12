import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/badge.dart';

void main() {
  group('Badge Model Tests', () {
    test('Badge creation with required parameters', () {
      final badge = Badge(
        icon: '⭐',
        name: 'Test Badge',
        description: 'A test badge',
        category: 'quiz',
        isUnlocked: false,
      );

      expect(badge.icon, '⭐');
      expect(badge.name, 'Test Badge');
      expect(badge.description, 'A test badge');
      expect(badge.category, 'quiz');
      expect(badge.isUnlocked, false);
      expect(badge.progressCurrent, null);
      expect(badge.progressTarget, null);
    });

    test('Badge with progress parameters', () {
      final badge = Badge(
        icon: '📝',
        name: 'Progress Badge',
        description: 'Testing progress',
        category: 'progress',
        isUnlocked: false,
        progressCurrent: 7,
        progressTarget: 10,
      );

      expect(badge.progressCurrent, 7);
      expect(badge.progressTarget, 10);
      expect(badge.progressRatio, 0.7);
    });

    test('Badge progressRatio calculation', () {
      final badge1 = Badge(
        icon: '⭐',
        name: 'Test',
        description: 'Test',
        category: 'quiz',
        isUnlocked: false,
        progressCurrent: 5,
        progressTarget: 10,
      );
      expect(badge1.progressRatio, 0.5);

      final badge2 = Badge(
        icon: '⭐',
        name: 'Test',
        description: 'Test',
        category: 'quiz',
        isUnlocked: false,
        progressCurrent: 15,
        progressTarget: 10,
      );
      expect(badge2.progressRatio, 1.0);

      final badge3 = Badge(
        icon: '⭐',
        name: 'Test',
        description: 'Test',
        category: 'quiz',
        isUnlocked: false,
      );
      expect(badge3.progressRatio, null);
    });

    test('Badge progressRatio with zero target', () {
      final badge = Badge(
        icon: '⭐',
        name: 'Test',
        description: 'Test',
        category: 'quiz',
        isUnlocked: false,
        progressCurrent: 5,
        progressTarget: 0,
      );
      expect(badge.progressRatio, null);
    });

    test('Badge unlocked state', () {
      final unlockedBadge = Badge(
        icon: '✓',
        name: 'Unlocked Badge',
        description: 'An unlocked badge',
        category: 'quiz',
        isUnlocked: true,
      );

      final lockedBadge = Badge(
        icon: '🔒',
        name: 'Locked Badge',
        description: 'A locked badge',
        category: 'quiz',
        isUnlocked: false,
      );

      expect(unlockedBadge.isUnlocked, true);
      expect(lockedBadge.isUnlocked, false);
    });

    test('Badge categories', () {
      final categories = ['quiz', 'progress', 'consistency', 'mastery', 'social'];

      for (final category in categories) {
        final badge = Badge(
          icon: '⭐',
          name: 'Test',
          description: 'Test',
          category: category,
          isUnlocked: false,
        );
        expect(badge.category, category);
      }
    });

    test('Multiple badges with different icons', () {
      final icons = ['⭐', '✨', '🎉', '📝', '🏆'];

      for (final icon in icons) {
        final badge = Badge(
          icon: icon,
          name: 'Test Badge',
          description: 'Test',
          category: 'quiz',
          isUnlocked: false,
        );
        expect(badge.icon, icon);
      }
    });

    test('Badge with all parameters', () {
      final badge = Badge(
        icon: '🏆',
        name: 'Complete Badge',
        description: 'A complete badge with all parameters',
        category: 'mastery',
        isUnlocked: true,
        progressCurrent: 100,
        progressTarget: 100,
      );

      expect(badge.icon, '🏆');
      expect(badge.name, 'Complete Badge');
      expect(badge.description, 'A complete badge with all parameters');
      expect(badge.category, 'mastery');
      expect(badge.isUnlocked, true);
      expect(badge.progressCurrent, 100);
      expect(badge.progressTarget, 100);
      expect(badge.progressRatio, 1.0);
    });
  });
}
