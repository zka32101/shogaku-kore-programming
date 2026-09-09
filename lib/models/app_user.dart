import 'package:firebase_auth/firebase_auth.dart';

/// ユーザー情報モデル（匿名認証ユーザー）
class AppUser {
  final String uid;
  final String displayName;
  final bool isAnonymous;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.isAnonymous,
    required this.createdAt,
  });

  /// Firebase User オブジェクトから AppUser を作成
  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      displayName: user.displayName ?? 'ゲスト',
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  /// Firebase認証が使えない環境向けのローカルフォールバックユーザー
  factory AppUser.local(String localId) {
    return AppUser(
      uid: localId,
      displayName: 'ゲスト',
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
  }

  /// AppUser をコピーして新しいインスタンスを作成（不変性の保証）
  AppUser copyWith({
    String? uid,
    String? displayName,
    bool? isAnonymous,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'AppUser(uid: $uid, displayName: $displayName, isAnonymous: $isAnonymous)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          displayName == other.displayName &&
          isAnonymous == other.isAnonymous &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      uid.hashCode ^
      displayName.hashCode ^
      isAnonymous.hashCode ^
      createdAt.hashCode;
}
