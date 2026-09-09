import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_model.dart';

/// フレンド機能の Firestore アクセス層。
///
/// データ構造（他の小学コレシリーズと同様のユーザーID検索方式）:
/// - `users/{uid}`                      : 公開プロフィール（nickname/avatarEmoji/points）
/// - `users/{uid}/friends/{friendUid}`  : 自分のフレンド一覧
/// - `users/{uid}/friendRequests/{fromUid}` : 自分宛の受信中フレンド申請
class FriendService {
  static final FriendService _instance = FriendService._internal();

  factory FriendService() => _instance;

  FriendService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// 自分の公開プロフィールを最新の状態で公開する。
  /// フレンド検索・フレンドランキング表示のため、起動時やニックネーム変更時、
  /// ポイント更新時に呼び出す。
  Future<void> publishPublicProfile({
    required String uid,
    required String nickname,
    required String avatarEmoji,
    required int points,
  }) async {
    final profile = PublicProfile(
      uid: uid,
      nickname: nickname,
      avatarEmoji: avatarEmoji,
      points: points,
      updatedAt: DateTime.now(),
    );
    await _users.doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  /// ユーザーIDから公開プロフィールを検索する。見つからない場合は null。
  Future<PublicProfile?> findUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return PublicProfile.fromMap(doc.id, data);
  }

  /// フレンド申請を送信する（相手の friendRequests に自分の情報を書き込む）。
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromNickname,
    required String fromAvatarEmoji,
    required String toUserId,
  }) async {
    final request = FriendRequestData(
      fromUserId: fromUserId,
      fromNickname: fromNickname,
      fromAvatarEmoji: fromAvatarEmoji,
      requestedAt: DateTime.now(),
    );
    await _users
        .doc(toUserId)
        .collection('friendRequests')
        .doc(fromUserId)
        .set(request.toMap());
  }

  /// 自分宛の受信中フレンド申請一覧を取得する。
  Future<List<FriendRequestData>> fetchReceivedRequests(String uid) async {
    final snapshot = await _users
        .doc(uid)
        .collection('friendRequests')
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => FriendRequestData.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// フレンド申請を承認する。双方の friends サブコレクションに互いを追加し、
  /// 申請ドキュメントを削除する。
  Future<void> acceptFriendRequest({
    required String myUid,
    required String myNickname,
    required String myAvatarEmoji,
    required int myPoints,
    required FriendRequestData request,
  }) async {
    final now = DateTime.now();

    final myEntry = FriendData(
      uid: request.fromUserId,
      nickname: request.fromNickname,
      avatarEmoji: request.fromAvatarEmoji,
      points: 0, // 相手の最新ポイントは公開プロフィール経由で別途取得する
      addedAt: now,
    );
    final theirEntry = FriendData(
      uid: myUid,
      nickname: myNickname,
      avatarEmoji: myAvatarEmoji,
      points: myPoints,
      addedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(
      _users.doc(myUid).collection('friends').doc(request.fromUserId),
      myEntry.toMap(),
    );
    batch.set(
      _users.doc(request.fromUserId).collection('friends').doc(myUid),
      theirEntry.toMap(),
    );
    batch.delete(
      _users.doc(myUid).collection('friendRequests').doc(request.fromUserId),
    );
    await batch.commit();
  }

  /// フレンド申請を拒否する（申請ドキュメントを削除するのみ）。
  Future<void> rejectFriendRequest({
    required String myUid,
    required String fromUserId,
  }) async {
    await _users
        .doc(myUid)
        .collection('friendRequests')
        .doc(fromUserId)
        .delete();
  }

  /// 自分のフレンド一覧を取得する。
  Future<List<FriendData>> fetchFriends(String uid) async {
    final snapshot = await _users
        .doc(uid)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => FriendData.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// フレンドを削除する（双方の friends サブコレクションから削除）。
  Future<void> removeFriend({
    required String myUid,
    required String friendUid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_users.doc(myUid).collection('friends').doc(friendUid));
    batch.delete(_users.doc(friendUid).collection('friends').doc(myUid));
    await batch.commit();
  }

  /// フレンドランキング表示用に、フレンド1人分の最新ポイントを公開プロフィール
  /// から取得し直す。存在しない/取得失敗時は null。
  Future<int?> fetchLatestPoints(String uid) async {
    final profile = await findUserById(uid);
    return profile?.points;
  }
}
