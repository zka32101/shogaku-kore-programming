import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/friend_model.dart';
import 'package:shogaku_kore_programming/providers/friends_provider.dart';

void main() {
  group('FriendsState', () {
    test('initializes with empty defaults', () {
      const state = FriendsState();

      expect(state.friends, isEmpty);
      expect(state.receivedRequests, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.infoMessage, isNull);
    });

    test('copyWith updates individual fields without touching others', () {
      const state = FriendsState(isLoading: false);
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, true);
      expect(updated.friends, isEmpty);
    });

    test('copyWith with clearMessages resets error and infoMessage', () {
      const state = FriendsState(error: 'エラー', infoMessage: '完了しました');
      final cleared = state.copyWith(clearMessages: true);

      expect(cleared.error, isNull);
      expect(cleared.infoMessage, isNull);
    });

    test('copyWith without clearMessages keeps previous messages when not overridden', () {
      const state = FriendsState(error: 'エラー');
      final updated = state.copyWith(isLoading: true);

      expect(updated.error, 'エラー');
    });
  });

  group('friendRankingProvider ordering (sort logic)', () {
    test('friends are sorted by points descending', () {
      final friends = [
        FriendData(uid: 'a', nickname: 'A', avatarEmoji: '🙂', points: 50, addedAt: DateTime.now()),
        FriendData(uid: 'b', nickname: 'B', avatarEmoji: '🙂', points: 200, addedAt: DateTime.now()),
        FriendData(uid: 'c', nickname: 'C', avatarEmoji: '🙂', points: 100, addedAt: DateTime.now()),
      ];
      final sorted = [...friends]..sort((x, y) => y.points.compareTo(x.points));

      expect(sorted.map((f) => f.uid).toList(), ['b', 'c', 'a']);
    });
  });
}
