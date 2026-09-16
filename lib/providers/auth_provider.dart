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

/// 匿名ログイン操作（アプリ起動時に一度だけ呼び出す）
final signInAnonymouslyProvider = FutureProvider<AppUser>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.signInAnonymously();
});
