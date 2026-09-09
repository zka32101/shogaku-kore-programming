// フレンド機能のデータモデル
//
// このアプリはこれまでフレンド機能を持っていなかった（ランキング画面には
// 「自分の記録」のみが表示され、`SocialProvider`（social_provider.dart）は
// モックデータのみでUIには一切繋がっていない）。本モデルは Firestore を
// バックエンドとした実際のフレンド機能（ユーザーID検索 → 申請 → 承認）向けに
// 新規に用意する。

/// 公開プロフィール（フレンド検索・表示用の最小限の情報）。
/// `users/{uid}` ドキュメントとして保存し、認証済みユーザーなら誰でも
/// 読み取れる（メールアドレス等の個人情報は含めない）。
class PublicProfile {
  final String uid;
  final String nickname;
  final String avatarEmoji;
  final int points; // 友達ランキング表示用（totalStarsEarned * 50 と同じ計算）
  final DateTime updatedAt;

  const PublicProfile({
    required this.uid,
    required this.nickname,
    required this.avatarEmoji,
    required this.points,
    required this.updatedAt,
  });

  factory PublicProfile.fromMap(String uid, Map<String, dynamic> data) {
    return PublicProfile(
      uid: uid,
      nickname: data['nickname'] as String? ?? 'たんけんか',
      avatarEmoji: data['avatarEmoji'] as String? ?? '🧑‍💻',
      points: data['points'] as int? ?? 0,
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nickname': nickname,
        'avatarEmoji': avatarEmoji,
        'points': points,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// フレンド1人分のデータ（自分の `friends` サブコレクションに保存される）
class FriendData {
  final String uid;
  final String nickname;
  final String avatarEmoji;
  final int points;
  final DateTime addedAt;

  const FriendData({
    required this.uid,
    required this.nickname,
    required this.avatarEmoji,
    required this.points,
    required this.addedAt,
  });

  factory FriendData.fromMap(String uid, Map<String, dynamic> data) {
    return FriendData(
      uid: uid,
      nickname: data['nickname'] as String? ?? 'たんけんか',
      avatarEmoji: data['avatarEmoji'] as String? ?? '🧑‍💻',
      points: data['points'] as int? ?? 0,
      addedAt: DateTime.tryParse(data['addedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nickname': nickname,
        'avatarEmoji': avatarEmoji,
        'points': points,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FriendData.fromPublicProfile(PublicProfile profile) => FriendData(
        uid: profile.uid,
        nickname: profile.nickname,
        avatarEmoji: profile.avatarEmoji,
        points: profile.points,
        addedAt: DateTime.now(),
      );
}

/// 受信したフレンド申請（自分の `friendRequests` サブコレクションに保存される）
class FriendRequestData {
  final String fromUserId;
  final String fromNickname;
  final String fromAvatarEmoji;
  final DateTime requestedAt;

  const FriendRequestData({
    required this.fromUserId,
    required this.fromNickname,
    required this.fromAvatarEmoji,
    required this.requestedAt,
  });

  factory FriendRequestData.fromMap(String fromUserId, Map<String, dynamic> data) {
    return FriendRequestData(
      fromUserId: fromUserId,
      fromNickname: data['fromNickname'] as String? ?? 'たんけんか',
      fromAvatarEmoji: data['fromAvatarEmoji'] as String? ?? '🧑‍💻',
      requestedAt: DateTime.tryParse(data['requestedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fromNickname': fromNickname,
        'fromAvatarEmoji': fromAvatarEmoji,
        'requestedAt': requestedAt.toIso8601String(),
      };
}
