import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

/// Firebase認証サービス
class AuthService {
  static final AuthService _instance = AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  /// 現在のユーザーを取得
  AppUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? AppUser.fromFirebaseUser(user) : null;
  }

  /// ユーザー認証状態のストリーム
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      return user != null ? AppUser.fromFirebaseUser(user) : null;
    });
  }

  /// メールアドレスとパスワードでサインアップ
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // displayName を設定
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      return AppUser.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// メールアドレスとパスワードでサインイン
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      return AppUser.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// パスワードリセットメールを送信
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// メールアドレスを更新
  Future<void> updateEmail({required String newEmail}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// プロフィール情報を更新
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      if (displayName != null || photoUrl != null) {
        await user.updateDisplayName(displayName ?? user.displayName);
        await user.updatePhotoURL(photoUrl ?? user.photoURL);
        await user.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// アカウント削除
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Firebase認証例外をハンドル
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'パスワードが弱いです。より強いパスワードを使用してください。';
      case 'email-already-in-use':
        return 'このメールアドレスは既に登録されています。';
      case 'invalid-email':
        return 'メールアドレスの形式が無効です。';
      case 'operation-not-allowed':
        return 'この操作は許可されていません。';
      case 'user-not-found':
        return 'ユーザーが見つかりません。';
      case 'wrong-password':
        return 'パスワードが間違っています。';
      case 'too-many-requests':
        return 'リクエストが多すぎます。後でもう一度お試しください。';
      case 'account-exists-with-different-credential':
        return 'このアカウントは異なる認証方法で既に存在します。';
      case 'invalid-credential':
        return '認証情報が無効です。';
      case 'user-disabled':
        return 'このユーザーアカウントは無効化されています。';
      default:
        return 'エラーが発生しました: ${e.message}';
    }
  }
}
