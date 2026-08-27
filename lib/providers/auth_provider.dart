import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// 認証サービスプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// ユーザー認証状態プロバイダー（ストリーム）
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// 現在のユーザープロバイダー
final currentUserProvider = Provider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

/// 認証状態プロバイダー（ログイン状態）
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ─────────────────────────────────────────────────────────────
// 認証操作用ノーティファイアー
// ─────────────────────────────────────────────────────────────

/// サインアップ操作
final signUpProvider =
    FutureProvider.family<AppUser, SignUpParams>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  return authService.signUpWithEmail(
    email: params.email,
    password: params.password,
    displayName: params.displayName,
  );
});

/// サインイン操作
final signInProvider =
    FutureProvider.family<AppUser, SignInParams>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  return authService.signInWithEmail(
    email: params.email,
    password: params.password,
  );
});

/// パスワードリセット操作
final sendPasswordResetProvider =
    FutureProvider.family<void, String>((ref, email) async {
  final authService = ref.watch(authServiceProvider);
  return authService.sendPasswordResetEmail(email: email);
});

/// サインアウト操作
final signOutProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.signOut();
});

/// プロフィール更新操作
final updateProfileProvider =
    FutureProvider.family<void, UpdateProfileParams>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  return authService.updateProfile(
    displayName: params.displayName,
    photoUrl: params.photoUrl,
  );
});

/// アカウント削除操作
final deleteAccountProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.deleteAccount();
});

// ─────────────────────────────────────────────────────────────
// パラメータクラス
// ─────────────────────────────────────────────────────────────

/// サインアップ用パラメータ
class SignUpParams {
  final String email;
  final String password;
  final String? displayName;

  SignUpParams({
    required this.email,
    required this.password,
    this.displayName,
  });
}

/// サインイン用パラメータ
class SignInParams {
  final String email;
  final String password;

  SignInParams({
    required this.email,
    required this.password,
  });
}

/// プロフィール更新用パラメータ
class UpdateProfileParams {
  final String? displayName;
  final String? photoUrl;

  UpdateProfileParams({
    this.displayName,
    this.photoUrl,
  });
}
