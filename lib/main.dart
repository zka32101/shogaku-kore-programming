import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/profile_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/wrong_answers_provider.dart';
import 'services/haptic_service.dart';
import 'services/sound_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/stage_list_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization will happen after UI is rendered (see _ShogakuKoreProgrammingAppState)
  // This reduces app startup time by ~600ms

  runApp(
    const ProviderScope(
      child: ShogakuKoreProgrammingApp(),
    ),
  );
}

class ShogakuKoreProgrammingApp extends ConsumerStatefulWidget {
  const ShogakuKoreProgrammingApp({super.key});

  @override
  ConsumerState<ShogakuKoreProgrammingApp> createState() =>
      _ShogakuKoreProgrammingAppState();
}

class _ShogakuKoreProgrammingAppState
    extends ConsumerState<ShogakuKoreProgrammingApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Firebase after UI is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (_) {
        // Firebase initialization failed, continue anyway
      }
    });

    // サウンドと通知の有効状態を設定に同期
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = ref.read(profileProvider);
      SoundService().setEnabled(profile.soundEnabled);
      HapticService.setEnabled(profile.hapticsEnabled);
      // 通知プラグインはウィジェットテスト等、プラットフォームチャンネルが
      // 用意されていない環境では初期化されておらず例外を投げるため、
      // アプリ本体（学習機能）をクラッシュさせないよう全体をガードする。
      try {
        // 通知の初期スケジュール
        final notif = NotificationService();
        await notif.scheduleDailyReminder(
          hour: profile.reminderHour,
          minute: profile.reminderMinute,
          enabled: profile.notificationsEnabled,
        );
        await notif.scheduleWeeklyReport(
          hour: 8,
          minute: 0,
          enabled: profile.notificationsEnabled && profile.weeklyReportEnabled,
        );
        await notif.scheduleEveningNudge(
          hour: profile.eveningNudgeHour,
          minute: profile.eveningNudgeMinute,
          enabled: profile.notificationsEnabled && profile.eveningNudgeEnabled,
        );
        // ストリークアラート（午後15時以降＆今日未クリア＆2日以上継続中）
        if (profile.notificationsEnabled) {
          final progressNotifier = ref.read(progressProvider.notifier);
          final streakDays = progressNotifier.streakDays;
          final todayCleared = progressNotifier.todayClearedCount;
          if (streakDays >= 2 && todayCleared == 0 && DateTime.now().hour >= 15) {
            await notif.sendStreakAlert(streakDays);
          }
        }
        // 週次レポート即時通知（週初め初回起動時に1回だけ送信）
        if (profile.notificationsEnabled && profile.weeklyReportEnabled) {
          final progressNotifier = ref.read(progressProvider.notifier);
          final now = DateTime.now();
          final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));
          final weekKey =
              '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
          final prefs = await SharedPreferences.getInstance();
          final lastSentWeek =
              prefs.getString('notif_weekly_report_sent_week') ?? '';
          if (lastSentWeek != weekKey) {
            await prefs.setString('notif_weekly_report_sent_week', weekKey);
            final weeklyCleared = progressNotifier.weeklyActivity().last;
            final totalStars = progressNotifier.totalStarsEarned;
            final streakDays = progressNotifier.streakDays;
            await notif.sendWeeklyReportNow(
              weeklyCleared: weeklyCleared,
              totalStars: totalStars,
              streakDays: streakDays,
            );
          }
        }
      } catch (_) {
        // 通知プラグイン未初期化環境（テスト等）では黙って諦める。
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // プロフィール変化を監視して SoundService / NotificationService に反映
    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (prev?.soundEnabled != next.soundEnabled) {
        SoundService().setEnabled(next.soundEnabled);
      }
      if (prev?.hapticsEnabled != next.hapticsEnabled) {
        HapticService.setEnabled(next.hapticsEnabled);
      }
      // デイリーリマインダー
      // .catchError: 通知プラグイン未初期化環境でも fire-and-forget の
      // 例外でアプリをクラッシュさせないためのガード（main.dart:58 の
      // try/catch と同じ理由）。
      if (prev?.notificationsEnabled != next.notificationsEnabled ||
          prev?.reminderHour != next.reminderHour ||
          prev?.reminderMinute != next.reminderMinute) {
        NotificationService().scheduleDailyReminder(
          hour: next.reminderHour,
          minute: next.reminderMinute,
          enabled: next.notificationsEnabled,
        ).catchError((_) {});
      }
      // 週次レポート（毎週月曜 08:00）
      if (prev?.notificationsEnabled != next.notificationsEnabled ||
          prev?.weeklyReportEnabled != next.weeklyReportEnabled) {
        NotificationService().scheduleWeeklyReport(
          hour: 8,
          minute: 0,
          enabled: next.notificationsEnabled && next.weeklyReportEnabled,
        ).catchError((_) {});
      }
      // 夕方ナッジ
      if (prev?.notificationsEnabled != next.notificationsEnabled ||
          prev?.eveningNudgeEnabled != next.eveningNudgeEnabled ||
          prev?.eveningNudgeHour != next.eveningNudgeHour ||
          prev?.eveningNudgeMinute != next.eveningNudgeMinute) {
        NotificationService().scheduleEveningNudge(
          hour: next.eveningNudgeHour,
          minute: next.eveningNudgeMinute,
          enabled: next.notificationsEnabled && next.eveningNudgeEnabled,
        ).catchError((_) {});
      }
    });

    final profile = ref.watch(profileProvider);
    final themeMode = switch (profile.themeMode) {
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: AppConstants.appName,
      theme: appTheme,
      darkTheme: darkAppTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class MainNavigator extends ConsumerStatefulWidget {
  const MainNavigator({super.key});

  @override
  ConsumerState<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends ConsumerState<MainNavigator> {
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  final List<Widget> _screens = const [
    HomeScreen(),
    StageListScreen(),
    AchievementsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab) {
      HapticService.selectionClick();
      if (HardwareKeyboard.instance.isShiftPressed) {
        // Shift+Tab → 前のタブ
        setState(() =>
            _selectedIndex = (_selectedIndex - 1 + _screens.length) % _screens.length);
      } else {
        // Tab → 次のタブ
        setState(() => _selectedIndex = (_selectedIndex + 1) % _screens.length);
      }
      return KeyEventResult.handled;
    }
    // Ctrl+1〜4 → タブ直接切り替え
    if (HardwareKeyboard.instance.isControlPressed) {
      final tabMap = {
        LogicalKeyboardKey.digit1: 0,
        LogicalKeyboardKey.digit2: 1,
        LogicalKeyboardKey.digit3: 2,
        LogicalKeyboardKey.digit4: 3,
      };
      final tabIdx = tabMap[key];
      if (tabIdx != null && tabIdx < _screens.length) {
        HapticService.selectionClick();
        setState(() => _selectedIndex = tabIdx);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final wrongCount = ref.watch(wrongAnswersProvider).count;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: Stack(
        children: _screens.asMap().entries.map((e) {
          final isSelected = e.key == _selectedIndex;
          return AnimatedOpacity(
            opacity: isSelected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: !isSelected,
              child: e.value,
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          HapticService.selectionClick();
          setState(() => _selectedIndex = index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Badge.count(
              count: wrongCount,
              isLabelVisible: wrongCount > 0,
              child: const Icon(Icons.lightbulb_outline),
            ),
            activeIcon: Badge.count(
              count: wrongCount,
              isLabelVisible: wrongCount > 0,
              child: const Icon(Icons.lightbulb),
            ),
            label: '学習',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: '実績',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    ),   // closes Scaffold
    );   // closes Focus
  }
}
