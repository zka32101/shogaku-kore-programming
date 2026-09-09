import 'package:shared_core/shared_core.dart' show BaseScreenTimeNotifier;

/// 利用時間制限（スクリーンタイム管理）の本アプリ向け実装。
///
/// ロジック・永続化は [BaseScreenTimeNotifier] に集約されているため、
/// このアプリでは SharedPreferences のキープレフィックスのみを指定する。
///
/// `main.dart` の `ProviderScope` で
/// `screenTimeProvider.overrideWith(ScreenTimeNotifier.new)` として登録する
/// （`screenTimeProvider` 自体は shared_core 側のプレースホルダーをそのまま使う）。
class ScreenTimeNotifier extends BaseScreenTimeNotifier {
  @override
  String get storageKey => 'shogaku_programming_screen_time';
}
