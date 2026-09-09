import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/friend_model.dart';

void main() {
  group('PublicProfile', () {
    test('fromMap / toMap round trip', () {
      final now = DateTime(2026, 9, 9, 12, 0, 0);
      final map = {
        'nickname': 'たろう',
        'avatarEmoji': '🚀',
        'points': 250,
        'updatedAt': now.toIso8601String(),
      };
      final profile = PublicProfile.fromMap('uid_1', map);

      expect(profile.uid, 'uid_1');
      expect(profile.nickname, 'たろう');
      expect(profile.avatarEmoji, '🚀');
      expect(profile.points, 250);
      expect(profile.updatedAt, now);
      expect(profile.toMap()['nickname'], 'たろう');
      expect(profile.toMap()['points'], 250);
    });

    test('fromMap falls back to defaults when fields are missing', () {
      final profile = PublicProfile.fromMap('uid_2', {});
      expect(profile.nickname, 'たんけんか');
      expect(profile.avatarEmoji, '🧑‍💻');
      expect(profile.points, 0);
    });
  });

  group('FriendData', () {
    test('fromMap / toMap round trip', () {
      final now = DateTime(2026, 9, 1);
      final map = {
        'nickname': 'はなこ',
        'avatarEmoji': '🌸',
        'points': 100,
        'addedAt': now.toIso8601String(),
      };
      final friend = FriendData.fromMap('uid_3', map);

      expect(friend.uid, 'uid_3');
      expect(friend.nickname, 'はなこ');
      expect(friend.points, 100);
      expect(friend.addedAt, now);
      expect(friend.toMap()['nickname'], 'はなこ');
    });

    test('fromPublicProfile copies displayed fields and sets addedAt to now', () {
      final profile = PublicProfile(
        uid: 'uid_4',
        nickname: 'じろう',
        avatarEmoji: '🎮',
        points: 300,
        updatedAt: DateTime.now(),
      );
      final friend = FriendData.fromPublicProfile(profile);

      expect(friend.uid, 'uid_4');
      expect(friend.nickname, 'じろう');
      expect(friend.avatarEmoji, '🎮');
      expect(friend.points, 300);
    });
  });

  group('FriendRequestData', () {
    test('fromMap / toMap round trip', () {
      final now = DateTime(2026, 9, 5);
      final map = {
        'fromNickname': 'さぶろう',
        'fromAvatarEmoji': '⚡',
        'requestedAt': now.toIso8601String(),
      };
      final request = FriendRequestData.fromMap('uid_5', map);

      expect(request.fromUserId, 'uid_5');
      expect(request.fromNickname, 'さぶろう');
      expect(request.fromAvatarEmoji, '⚡');
      expect(request.requestedAt, now);
      expect(request.toMap()['fromNickname'], 'さぶろう');
    });
  });
}
