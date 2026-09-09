import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_model.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';

class FriendsState {
  final List<FriendData> friends;
  final List<FriendRequestData> receivedRequests;
  final bool isLoading;
  final String? error;
  final String? infoMessage; // 「リクエストを送信しました」等の一時メッセージ

  const FriendsState({
    this.friends = const [],
    this.receivedRequests = const [],
    this.isLoading = false,
    this.error,
    this.infoMessage,
  });

  FriendsState copyWith({
    List<FriendData>? friends,
    List<FriendRequestData>? receivedRequests,
    bool? isLoading,
    String? error,
    String? infoMessage,
    bool clearMessages = false,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      isLoading: isLoading ?? this.isLoading,
      error: clearMessages ? null : (error ?? this.error),
      infoMessage: clearMessages ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

/// フレンド機能の状態管理。
///
/// Firestore へのアクセスは [FriendService] に委譲する。自分のユーザーIDは
/// 匿名認証（[AuthService]）から取得する。
class FriendsNotifier extends StateNotifier<FriendsState> {
  final FriendService _service;

  FriendsNotifier(this._service) : super(const FriendsState());

  String? get _myUid => AuthService().currentUser?.uid;

  /// 自分の公開プロフィールを最新の状態で公開する（フレンド検索・ランキング用）。
  /// アプリ起動時やニックネーム・ポイント更新時に呼び出す。
  Future<void> syncMyPublicProfile({
    required String nickname,
    required String avatarEmoji,
    required int points,
  }) async {
    final uid = _myUid;
    if (uid == null) return;
    try {
      await _service.publishPublicProfile(
        uid: uid,
        nickname: nickname,
        avatarEmoji: avatarEmoji,
        points: points,
      );
    } catch (_) {
      // 公開プロフィールの同期に失敗しても学習機能自体には影響させない
    }
  }

  /// フレンド一覧を取得し直す。
  Future<void> loadFriends() async {
    final uid = _myUid;
    if (uid == null) {
      state = state.copyWith(error: 'ログインできていません', clearMessages: false);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final friends = await _service.fetchFriends(uid);
      state = state.copyWith(friends: friends, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'フレンド一覧の取得に失敗しました');
    }
  }

  /// 受信中のフレンド申請一覧を取得し直す。
  Future<void> loadReceivedRequests() async {
    final uid = _myUid;
    if (uid == null) return;
    try {
      final requests = await _service.fetchReceivedRequests(uid);
      state = state.copyWith(receivedRequests: requests);
    } catch (_) {
      // 一覧取得の失敗は致命的ではないため状態のみ据え置く
    }
  }

  /// ユーザーIDを指定してフレンド申請を送信する。
  /// 戻り値: 成功したら true。
  Future<bool> sendFriendRequestTo(
    String targetUid, {
    required String myNickname,
    required String myAvatarEmoji,
  }) async {
    final uid = _myUid;
    if (uid == null) {
      state = state.copyWith(error: 'ログインできていません');
      return false;
    }
    final target = targetUid.trim();
    if (target.isEmpty) {
      state = state.copyWith(error: 'ユーザーIDを入力してください');
      return false;
    }
    if (target == uid) {
      state = state.copyWith(error: '自分自身はフレンドに追加できません');
      return false;
    }
    if (state.friends.any((f) => f.uid == target)) {
      state = state.copyWith(error: '既にフレンドです');
      return false;
    }

    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final profile = await _service.findUserById(target);
      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'そのユーザーIDは見つかりませんでした',
        );
        return false;
      }
      await _service.sendFriendRequest(
        fromUserId: uid,
        fromNickname: myNickname,
        fromAvatarEmoji: myAvatarEmoji,
        toUserId: target,
      );
      state = state.copyWith(
        isLoading: false,
        infoMessage: '${profile.nickname} さんにフレンド申請を送りました！',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'フレンド申請の送信に失敗しました');
      return false;
    }
  }

  /// フレンド申請を承認する。
  Future<bool> acceptRequest(
    FriendRequestData request, {
    required String myNickname,
    required String myAvatarEmoji,
    required int myPoints,
  }) async {
    final uid = _myUid;
    if (uid == null) return false;
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _service.acceptFriendRequest(
        myUid: uid,
        myNickname: myNickname,
        myAvatarEmoji: myAvatarEmoji,
        myPoints: myPoints,
        request: request,
      );
      state = state.copyWith(
        receivedRequests:
            state.receivedRequests.where((r) => r.fromUserId != request.fromUserId).toList(),
        isLoading: false,
        infoMessage: '${request.fromNickname} さんとフレンドになりました！',
      );
      await loadFriends();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'フレンド申請の承認に失敗しました');
      return false;
    }
  }

  /// フレンド申請を拒否する。
  Future<bool> rejectRequest(FriendRequestData request) async {
    final uid = _myUid;
    if (uid == null) return false;
    try {
      await _service.rejectFriendRequest(myUid: uid, fromUserId: request.fromUserId);
      state = state.copyWith(
        receivedRequests:
            state.receivedRequests.where((r) => r.fromUserId != request.fromUserId).toList(),
        clearMessages: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'フレンド申請の拒否に失敗しました');
      return false;
    }
  }

  /// フレンドを削除する。
  Future<bool> removeFriend(String friendUid) async {
    final uid = _myUid;
    if (uid == null) return false;
    try {
      await _service.removeFriend(myUid: uid, friendUid: friendUid);
      state = state.copyWith(
        friends: state.friends.where((f) => f.uid != friendUid).toList(),
        clearMessages: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'フレンドの削除に失敗しました');
      return false;
    }
  }

  /// フレンドランキング表示用に、各フレンドの最新ポイントを取得し直す。
  /// 通信量を抑えるため、明示的に呼び出したときのみ実行する（ランキング画面表示時等）。
  Future<void> refreshFriendPoints() async {
    if (state.friends.isEmpty) return;
    try {
      final updated = <FriendData>[];
      for (final friend in state.friends) {
        final points = await _service.fetchLatestPoints(friend.uid);
        updated.add(
          points != null
              ? FriendData(
                  uid: friend.uid,
                  nickname: friend.nickname,
                  avatarEmoji: friend.avatarEmoji,
                  points: points,
                  addedAt: friend.addedAt,
                )
              : friend,
        );
      }
      state = state.copyWith(friends: updated);
    } catch (_) {
      // 更新できなくても既存のフレンド一覧は表示できるようにする
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final service = ref.watch(friendServiceProvider);
  return FriendsNotifier(service);
});

/// フレンド数（ホーム画面等でのバッジ表示用）
final friendCountProvider = Provider<int>((ref) {
  return ref.watch(friendsProvider).friends.length;
});

/// 受信中フレンド申請数（バッジ表示用）
final pendingFriendRequestCountProvider = Provider<int>((ref) {
  return ref.watch(friendsProvider).receivedRequests.length;
});

/// ポイント降順に並べたフレンドランキング用リスト
final friendRankingProvider = Provider<List<FriendData>>((ref) {
  final friends = [...ref.watch(friendsProvider).friends];
  friends.sort((a, b) => b.points.compareTo(a.points));
  return friends;
});
