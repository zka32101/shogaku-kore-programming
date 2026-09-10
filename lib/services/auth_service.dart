import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

const _localUserIdKey = 'local_user_id';

/// Firebase匿名認証サービス
///
/// 他の小学コレシリーズと同様、ログイン画面は持たずアプリ起動時に
/// 自動で匿名ログインを行う。Firebaseが使えない環境（未設定・オフライン等）
/// ではローカルに生成したIDにフォールバックする。
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

  /// 匿名ログイン
  ///
  /// 既にサインイン済みの場合はそのユーザーを返す。Firebase認証に
  /// 失敗した場合はローカルに生成したIDにフォールバックする。
  Future<AppUser> signInAnonymously() async {
    try {
      final current = _firebaseAuth.currentUser;
      if (current != null) {
        return AppUser.fromFirebaseUser(current);
      }

      final userCredential = await _firebaseAuth.signInAnonymously();
      final user = userCredential.user;
      if (user == null) {
        return await _signInWithLocalFallback();
      }
      return AppUser.fromFirebaseUser(user);
    } catch (_) {
      return await _signInWithLocalFallback();
    }
  }

  /// Firebase匿名認証が使えない場合のローカルIDフォールバック
  Future<AppUser> _signInWithLocalFallback() async {
    final prefs = await SharedPreferences.getInstance();
    var localId = prefs.getString(_localUserIdKey);
    if (localId == null) {
      localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_localUserIdKey, localId);
    }
    return AppUser.local(localId);
  }
}
