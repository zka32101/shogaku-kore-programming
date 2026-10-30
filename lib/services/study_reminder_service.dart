import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart'
    show
        NotificationContext,
        NotificationPlanNotifier,
        NotificationTone,
        SmartReminderScheduler;
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// 学習リマインダー（ローカル通知）。shared_core の `SmartNotificationPlanner`
/// が決めた時刻・文面を予約する。通知プラグインは既存の [NotificationService]
/// のものを使い回す（二重 initialize しない）。
///
/// 学習のたびに予約し直す（毎回 cancel → 再予約）。予約するのは次の3件だけ:
/// - 翌日: 連続記録・復習の声かけ
/// - 3日後 / 7日後: 来なかったときの「おかえり」
class StudyReminderService {
  StudyReminderService._();
  static final StudyReminderService instance = StudyReminderService._();

  static const _enabledKey = 'app_reminder_enabled';
  static const _idNextDay = 7001;
  static const _idAfter3Days = 7002;
  static const _idAfter7Days = 7003;

  bool _permissionAsked = false;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// 保護者が ON/OFF する。OFF にすると予約済みの通知も消す。
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      await _requestPermission();
    } else {
      await cancelAll();
    }
  }

  Future<void> cancelAll() async {
    try {
      final service = NotificationService();
      await service.initialize();
      for (final id in [_idNextDay, _idAfter3Days, _idAfter7Days]) {
        await service.plugin.cancel(id);
      }
    } catch (e) {
      debugPrint('[Reminder] 取消をスキップ: $e');
    }
  }

  Future<void> _requestPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    try {
      await NotificationService().requestPermission();
    } catch (e) {
      debugPrint('[Reminder] 権限リクエストをスキップ: $e');
    }
  }

  /// 学習した直後に呼ぶ。[appNotificationsEnabled] は設定画面の
  /// 「学習リマインダー」（アプリ全体の通知スイッチ）の状態。OFF なら予約しない。
  Future<void> reschedule({
    required NotificationPlanNotifier plan,
    required bool appNotificationsEnabled,
    required int streak,
    required int dueReviewTomorrow,
    NotificationTone tone = NotificationTone.standard,
    DateTime? now,
  }) async {
    try {
      if (!appNotificationsEnabled || !await isEnabled()) {
        await cancelAll();
        return;
      }
      final service = NotificationService();
      await service.initialize();
      await _requestPermission();

      final base = now ?? DateTime.now();
      final scheduler = SmartReminderScheduler(service.plugin);

      Future<void> schedule(int id, int daysAway, NotificationContext ctx) =>
          scheduler.schedule(
            plan.planFor(ctx, tone: tone),
            notificationId: id,
            channelId: 'shogaku_kore_channel',
            channelName: '学習リマインダー',
            now: base.add(Duration(days: daysAway - 1)),
          );

      await schedule(
          _idNextDay,
          1,
          NotificationContext(
              currentStreak: streak,
              doneToday: true,
              dueReviewCount: dueReviewTomorrow));
      await schedule(_idAfter3Days, 3,
          const NotificationContext(daysAway: 3, doneToday: true));
      await schedule(_idAfter7Days, 7,
          const NotificationContext(daysAway: 7, doneToday: true));
    } catch (e) {
      debugPrint('[Reminder] 予約をスキップ: $e');
    }
  }
}
