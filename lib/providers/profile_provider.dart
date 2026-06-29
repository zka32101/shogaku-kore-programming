import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';

/// テーマモード設定値
class AppThemeMode {
  static const String system = 'system';
  static const String light = 'light';
  static const String dark = 'dark';
}

class ProfileState {
  final String nickname;
  final String avatarEmoji;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool isOnboardingComplete;
  final int reminderHour;          // 0–23
  final int reminderMinute;        // 0–59
  final String themeMode;          // 'system' | 'light' | 'dark'
  final bool weeklyReportEnabled;  // 週次レポート通知
  final bool eveningNudgeEnabled;  // 夕方ナッジ通知
  final int eveningNudgeHour;      // 夕方通知時刻（時）
  final int eveningNudgeMinute;    // 夕方通知時刻（分）
  final int dailyGoal;             // 1日の目標ステージ数（1/3/5）
  final bool autoAdvanceEnabled;   // 正解後に自動で次の問題へ進む
  final double codeFontSize;       // コードスニペットのフォントサイズ（11/13/16）
  final bool hapticsEnabled;       // バイブレーション（振動フィードバック）
  final bool quizTimerEnabled;     // クイズの制限時間（60秒タイマー）を有効にする
  final int reviewQuestionCount;    // 今日の復習の問題数（3/5/10）
  final int flashcardSessionSize;    // フラッシュカード1回のセッション枚数（5/10/15/20）
  final int flashcardAutoFlipSecs;   // 自動めくり間隔（秒）（3/5/10）
  final int quizTimerSeconds;              // クイズ1問あたりの制限時間（秒）（30/45/60/90）
  final bool wrongAnswerReminderEnabled;   // 苦手問題リマインダー通知

  const ProfileState({
    this.nickname = 'たんけんか',
    this.avatarEmoji = '🧑‍💻',
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.isOnboardingComplete = false,
    this.reminderHour = 19,
    this.reminderMinute = 0,
    this.themeMode = AppThemeMode.system,
    this.weeklyReportEnabled = true,
    this.eveningNudgeEnabled = false,
    this.eveningNudgeHour = 20,
    this.eveningNudgeMinute = 0,
    this.dailyGoal = 3,
    this.autoAdvanceEnabled = false,
    this.codeFontSize = 13.0,
    this.hapticsEnabled = true,
    this.quizTimerEnabled = true,
    this.reviewQuestionCount = 5,
    this.flashcardSessionSize = 10,
    this.flashcardAutoFlipSecs = 5,
    this.quizTimerSeconds = 60,
    this.wrongAnswerReminderEnabled = false,
  });

  ProfileState copyWith({
    String? nickname,
    String? avatarEmoji,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? isOnboardingComplete,
    int? reminderHour,
    int? reminderMinute,
    String? themeMode,
    bool? weeklyReportEnabled,
    bool? eveningNudgeEnabled,
    int? eveningNudgeHour,
    int? eveningNudgeMinute,
    int? dailyGoal,
    bool? autoAdvanceEnabled,
    double? codeFontSize,
    bool? hapticsEnabled,
    bool? quizTimerEnabled,
    int? reviewQuestionCount,
    int? flashcardSessionSize,
    int? flashcardAutoFlipSecs,
    int? quizTimerSeconds,
    bool? wrongAnswerReminderEnabled,
  }) {
    return ProfileState(
      nickname: nickname ?? this.nickname,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      themeMode: themeMode ?? this.themeMode,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      eveningNudgeEnabled: eveningNudgeEnabled ?? this.eveningNudgeEnabled,
      eveningNudgeHour: eveningNudgeHour ?? this.eveningNudgeHour,
      eveningNudgeMinute: eveningNudgeMinute ?? this.eveningNudgeMinute,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      autoAdvanceEnabled: autoAdvanceEnabled ?? this.autoAdvanceEnabled,
      codeFontSize: codeFontSize ?? this.codeFontSize,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      quizTimerEnabled: quizTimerEnabled ?? this.quizTimerEnabled,
      reviewQuestionCount: reviewQuestionCount ?? this.reviewQuestionCount,
      flashcardSessionSize: flashcardSessionSize ?? this.flashcardSessionSize,
      flashcardAutoFlipSecs: flashcardAutoFlipSecs ?? this.flashcardAutoFlipSecs,
      quizTimerSeconds: quizTimerSeconds ?? this.quizTimerSeconds,
      wrongAnswerReminderEnabled: wrongAnswerReminderEnabled ?? this.wrongAnswerReminderEnabled,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState()) {
    _load();
  }

  static const _keyNickname        = 'profile_nickname';
  static const _keyAvatar          = 'profile_avatar';
  static const _keySound           = 'profile_sound';
  static const _keyNotif           = 'profile_notif';
  static const _keyOnboarded       = 'profile_onboarded';
  static const _keyReminderHour    = 'profile_reminder_hour';
  static const _keyReminderMinute  = 'profile_reminder_minute';
  static const _keyThemeMode       = 'profile_theme_mode';
  static const _keyWeeklyReport    = 'profile_weekly_report';
  static const _keyEveningNudge    = 'profile_evening_nudge';
  static const _keyEveningNudgeH   = 'profile_evening_nudge_hour';
  static const _keyEveningNudgeM   = 'profile_evening_nudge_minute';
  static const _keyDailyGoal       = 'profile_daily_goal';
  static const _keyAutoAdvance     = 'profile_auto_advance';
  static const _keyCodeFontSize    = 'profile_code_font_size';
  static const _keyHaptics              = 'profile_haptics';
  static const _keyQuizTimer            = 'profile_quiz_timer';
  static const _keyReviewQuestionCount  = 'profile_review_question_count';
  static const _keyFlashcardSessionSize   = 'profile_flashcard_session_size';
  static const _keyFlashcardAutoFlipSecs  = 'profile_flashcard_auto_flip_secs';
  static const _keyQuizTimerSeconds       = 'profile_quiz_timer_seconds';
  static const _keyWrongAnswerReminder    = 'profile_wrong_answer_reminder';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ProfileState(
      nickname: prefs.getString(_keyNickname) ?? 'たんけんか',
      avatarEmoji: prefs.getString(_keyAvatar) ?? '🧑‍💻',
      soundEnabled: prefs.getBool(_keySound) ?? true,
      notificationsEnabled: prefs.getBool(_keyNotif) ?? true,
      isOnboardingComplete: prefs.getBool(_keyOnboarded) ?? false,
      reminderHour: prefs.getInt(_keyReminderHour) ?? 19,
      reminderMinute: prefs.getInt(_keyReminderMinute) ?? 0,
      themeMode: prefs.getString(_keyThemeMode) ?? AppThemeMode.system,
      weeklyReportEnabled: prefs.getBool(_keyWeeklyReport) ?? true,
      eveningNudgeEnabled: prefs.getBool(_keyEveningNudge) ?? false,
      eveningNudgeHour: prefs.getInt(_keyEveningNudgeH) ?? 20,
      eveningNudgeMinute: prefs.getInt(_keyEveningNudgeM) ?? 0,
      dailyGoal: prefs.getInt(_keyDailyGoal) ?? 3,
      autoAdvanceEnabled: prefs.getBool(_keyAutoAdvance) ?? false,
      codeFontSize: prefs.getDouble(_keyCodeFontSize) ?? 13.0,
      hapticsEnabled: prefs.getBool(_keyHaptics) ?? true,
      quizTimerEnabled: prefs.getBool(_keyQuizTimer) ?? true,
      reviewQuestionCount: prefs.getInt(_keyReviewQuestionCount) ?? 5,
      flashcardSessionSize: prefs.getInt(_keyFlashcardSessionSize) ?? 10,
      flashcardAutoFlipSecs: prefs.getInt(_keyFlashcardAutoFlipSecs) ?? 5,
      quizTimerSeconds: prefs.getInt(_keyQuizTimerSeconds) ?? 60,
      wrongAnswerReminderEnabled: prefs.getBool(_keyWrongAnswerReminder) ?? false,
    );
    // HapticService に反映
    HapticService.setEnabled(state.hapticsEnabled);
  }

  Future<void> setNickname(String name) async {
    final trimmed = name.trim().isEmpty ? 'たんけんか' : name.trim();
    state = state.copyWith(nickname: trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, trimmed);
  }

  Future<void> setAvatar(String emoji) async {
    state = state.copyWith(avatarEmoji: emoji);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatar, emoji);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotif, enabled);
  }

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  Future<void> setWeeklyReportEnabled(bool enabled) async {
    state = state.copyWith(weeklyReportEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyReport, enabled);
  }

  Future<void> setEveningNudgeEnabled(bool enabled) async {
    state = state.copyWith(eveningNudgeEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEveningNudge, enabled);
  }

  Future<void> setEveningNudgeTime(int hour, int minute) async {
    state = state.copyWith(eveningNudgeHour: hour, eveningNudgeMinute: minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEveningNudgeH, hour);
    await prefs.setInt(_keyEveningNudgeM, minute);
  }

  Future<void> setDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyGoal, goal);
  }

  Future<void> setAutoAdvanceEnabled(bool enabled) async {
    state = state.copyWith(autoAdvanceEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoAdvance, enabled);
  }

  Future<void> setCodeFontSize(double size) async {
    state = state.copyWith(codeFontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyCodeFontSize, size);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = state.copyWith(hapticsEnabled: enabled);
    HapticService.setEnabled(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptics, enabled);
  }

  Future<void> setQuizTimerEnabled(bool enabled) async {
    state = state.copyWith(quizTimerEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyQuizTimer, enabled);
  }

  Future<void> setReviewQuestionCount(int count) async {
    state = state.copyWith(reviewQuestionCount: count);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReviewQuestionCount, count);
  }

  Future<void> setFlashcardSessionSize(int size) async {
    state = state.copyWith(flashcardSessionSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFlashcardSessionSize, size);
  }

  Future<void> setFlashcardAutoFlipSecs(int secs) async {
    state = state.copyWith(flashcardAutoFlipSecs: secs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFlashcardAutoFlipSecs, secs);
  }

  Future<void> setQuizTimerSeconds(int secs) async {
    state = state.copyWith(quizTimerSeconds: secs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyQuizTimerSeconds, secs);
  }

  Future<void> setWrongAnswerReminderEnabled(bool enabled) async {
    state = state.copyWith(wrongAnswerReminderEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWrongAnswerReminder, enabled);
  }

  Future<void> completeOnboarding({
    required String nickname,
    required String avatarEmoji,
  }) async {
    final trimmed = nickname.trim().isEmpty ? 'たんけんか' : nickname.trim();
    state = state.copyWith(
      nickname: trimmed,
      avatarEmoji: avatarEmoji,
      isOnboardingComplete: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, trimmed);
    await prefs.setString(_keyAvatar, avatarEmoji);
    await prefs.setBool(_keyOnboarded, true);
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
        (ref) => ProfileNotifier());
