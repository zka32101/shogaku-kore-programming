import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// ローカル通知サービス
/// - 毎日のリマインダー通知
/// - 週次レポート通知（毎月曜）
/// - ストリーク継続アラート
/// - 夜間ナッジ通知
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // 通知ID
  static const int _dailyReminderId       = 1;
  static const int _streakAlertId         = 2;
  static const int _weeklyReportId        = 3;
  static const int _eveningNudgeId        = 4;
  static const int _wrongAnswerReminderId = 5;

  // チャンネルID
  static const String _channelId   = 'shogaku_kore_channel';
  static const String _channelName = '学習リマインダー';

  // ────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // ────────── 毎日リマインダー ─────────────────────────────────────────────

  /// 毎日の学習リマインダーをスケジュール
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    await _plugin.cancel(_dailyReminderId);
    if (!enabled) return;

    await initialize();

    final scheduledTime = _nextOccurrence(hour, minute);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '📚 今日の学習はどうかな？',
      'コード探険でプログラミングを練習しよう！🔥',
      scheduledTime,
      _details(importance: Importance.defaultImportance),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ────────── 週次レポート（毎月曜朝） ─────────────────────────────────────

  /// 毎週月曜日の [hour]:[minute] に「今週もがんばろう！」通知
  Future<void> scheduleWeeklyReport({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    await _plugin.cancel(_weeklyReportId);
    if (!enabled) return;

    await initialize();

    // 次の月曜日を計算 (Dart DateTime は常にデバイスローカル時刻)
    final nowLocal = DateTime.now();
    final daysUntilMonday = (DateTime.monday - nowLocal.weekday + 7) % 7;
    var nextLocal = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day + daysUntilMonday,
      hour,
      minute,
    );
    if (nextLocal.isBefore(nowLocal)) {
      nextLocal = nextLocal.add(const Duration(days: 7));
    }
    final next = tz.TZDateTime.from(nextLocal, tz.UTC);

    await _plugin.zonedSchedule(
      _weeklyReportId,
      '📊 週次レポート',
      '今週もプログラミングをがんばろう！先週の成果を確認してみよう✨',
      next,
      _details(importance: Importance.defaultImportance),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ────────── 苦手問題リマインダー ─────────────────────────────────────────────

  /// 苦手問題が残っているときの復習リマインダー
  /// wrongCount が 0 の場合は通知をキャンセルするだけ。
  Future<void> scheduleWrongAnswerReminder({
    required int hour,
    required int minute,
    required int wrongCount,
    bool enabled = true,
  }) async {
    await _plugin.cancel(_wrongAnswerReminderId);
    if (!enabled || wrongCount <= 0) return;

    await initialize();

    final scheduledTime = _nextOccurrence(hour, minute);
    final body = wrongCount == 1
        ? '苦手問題が$wrongCount件あります。今日1問だけ練習してみよう！🔥'
        : '苦手問題が$wrongCount件残っています。少しずつ克服しよう！🎯';

    await _plugin.zonedSchedule(
      _wrongAnswerReminderId,
      '🔥 苦手問題を練習しよう！',
      body,
      scheduledTime,
      _details(importance: Importance.defaultImportance),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelWrongAnswerReminder() async =>
      _plugin.cancel(_wrongAnswerReminderId);

  // ────────── 夕方ナッジ ────────────────────────────────────────────────────

  /// 夕方の「まだ学習していません」ナッジ通知
  /// デイリーリマインダーとは別の時間帯（例: 20:00）に設定
  Future<void> scheduleEveningNudge({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    await _plugin.cancel(_eveningNudgeId);
    if (!enabled) return;

    await initialize();

    final scheduledTime = _nextOccurrence(hour, minute);

    await _plugin.zonedSchedule(
      _eveningNudgeId,
      '🌙 今日はもう学習した？',
      'ちょっとだけでOK！1ステージだけやってみよう🎮',
      scheduledTime,
      _details(importance: Importance.low),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ────────── 即時通知 ─────────────────────────────────────────────────────

  /// ストリーク継続アラート（ストリークが危ない時）
  Future<void> sendStreakAlert(int streakDays) async {
    await initialize();

    await _plugin.show(
      _streakAlertId,
      '🔥 ストリークが危ない！',
      '$streakDays日連続中！今日も学習してストリークを守ろう！',
      _details(importance: Importance.high),
    );
  }

  /// ストリーク達成おめでとう通知
  Future<void> sendStreakMilestone(int streakDays) async {
    await initialize();

    final emoji = streakDays >= 30 ? '👑' : streakDays >= 14 ? '💎' : streakDays >= 7 ? '🏆' : '🎉';
    await _plugin.show(
      _streakAlertId,
      '$emoji $streakDays日連続達成！',
      'すごい！$streakDays日連続で学習を続けています！この調子で！',
      _details(importance: Importance.high),
    );
  }

  /// 週次レポートを即時送信（週次サマリー表示用）
  Future<void> sendWeeklyReportNow({
    required int weeklyCleared,
    required int totalStars,
    required int streakDays,
  }) async {
    await initialize();

    final message = weeklyCleared > 0
        ? '今週 $weeklyCleared ステージクリア、$totalStars ポイント獲得！$streakDays日連続継続中🔥'
        : '今週はまだ学習していないよ。週末に少しだけチャレンジしてみよう！';

    await _plugin.show(
      _weeklyReportId,
      '📊 今週の学習レポート',
      message,
      _details(importance: Importance.defaultImportance),
    );
  }

  // ────────── キャンセル ────────────────────────────────────────────────────

  /// テスト通知（設定画面から送信する確認用）
  Future<void> sendTestNotification() async {
    await initialize();
    await Future.delayed(const Duration(seconds: 5));
    await _plugin.show(
      999,
      '🔔 テスト通知',
      'しょうがくプログラミングの通知が正常に届いています！',
      _details(importance: Importance.high),
    );
  }

  Future<void> cancelDailyReminder()  async => _plugin.cancel(_dailyReminderId);
  Future<void> cancelWeeklyReport()   async => _plugin.cancel(_weeklyReportId);
  Future<void> cancelEveningNudge()   async => _plugin.cancel(_eveningNudgeId);
  Future<void> cancelAll()            async => _plugin.cancelAll();

  // ────────── 権限リクエスト ─────────────────────────────────────────────────

  /// 通知権限をリクエスト (Android 13+)
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    // iOS: permission requested during initialize
    return true;
  }

  // ────────── ヘルパー ──────────────────────────────────────────────────────

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    // Use Dart's DateTime.now() which is always device-local time,
    // then convert to TZDateTime preserving the same instant (in UTC).
    // This avoids tz.local defaulting to UTC when setLocalLocation() is never called.
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return tz.TZDateTime.from(t, tz.UTC);
  }

  NotificationDetails _details({required Importance importance}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: importance,
        priority: importance == Importance.high ? Priority.high : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }
}
