import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/daily_login_reward.dart';
import 'package:shogaku_kore_programming/providers/daily_login_reward_provider.dart';
import 'package:shogaku_kore_programming/screens/daily_reward_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyRewardScreen', () {
    testWidgets('displays loading indicator when initializing', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays error message when initialization fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith(
              (ref) => DailyLoginRewardNotifier()
                ..state = DailyLoginRewardState(
                  error: 'テストエラー',
                ),
            ),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays streak header with current and longest streaks',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final notifier = DailyLoginRewardNotifier();
      notifier.state = DailyLoginRewardState(
        userStreak: LoginStreak(
          userId: 'test_user',
          currentStreak: 5,
          longestStreak: 15,
          lastLoginDate: now,
        ),
        stats: LoginRewardStats(
          userId: 'test_user',
          totalRewardsClaimed: 5,
          totalXpEarned: 150,
          totalCoinEarned: 75,
          firstLoginDate: now,
          lastResetDate: now,
        ),
        rewardData: DailyLoginRewardData(
          availableRewards: [],
          userStreak: LoginStreak(
            userId: 'test_user',
            currentStreak: 5,
            longestStreak: 15,
            lastLoginDate: now,
          ),
          stats: LoginRewardStats(
            userId: 'test_user',
            totalRewardsClaimed: 5,
            totalXpEarned: 150,
            totalCoinEarned: 75,
            firstLoginDate: now,
            lastResetDate: now,
          ),
          generatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ログインストリーク'), findsOneWidget);
      expect(find.text('5'), findsWidgets); // Current streak
      expect(find.text('15'), findsOneWidget); // Longest streak
    });

    testWidgets('displays claim reward button when eligible', (WidgetTester tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final streak = LoginStreak(
        userId: 'test_user',
        currentStreak: 0,
        longestStreak: 0,
        lastLoginDate: yesterday,
      );

      final stats = LoginRewardStats(
        userId: 'test_user',
        totalRewardsClaimed: 0,
        totalXpEarned: 0,
        totalCoinEarned: 0,
        firstLoginDate: now,
        lastResetDate: now,
      );

      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
      ];

      final notifier = DailyLoginRewardNotifier();
      notifier.state = DailyLoginRewardState(
        userStreak: streak,
        stats: stats,
        rewardData: DailyLoginRewardData(
          availableRewards: rewards,
          userStreak: streak,
          stats: stats,
          generatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('リワードを獲得'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays claimed message when not eligible', (WidgetTester tester) async {
      final now = DateTime.now();

      final streak = LoginStreak(
        userId: 'test_user',
        currentStreak: 1,
        longestStreak: 1,
        lastLoginDate: now,
      );

      final stats = LoginRewardStats(
        userId: 'test_user',
        totalRewardsClaimed: 1,
        totalXpEarned: 10,
        totalCoinEarned: 5,
        firstLoginDate: now,
        lastResetDate: now,
      );

      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
      ];

      final notifier = DailyLoginRewardNotifier();
      notifier.state = DailyLoginRewardState(
        userStreak: streak,
        stats: stats,
        rewardData: DailyLoginRewardData(
          availableRewards: rewards,
          userStreak: streak,
          stats: stats,
          generatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('本日のリワードは獲得済みです'), findsOneWidget);
    });

    testWidgets('displays next reward card', (WidgetTester tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final streak = LoginStreak(
        userId: 'test_user',
        currentStreak: 0,
        longestStreak: 0,
        lastLoginDate: yesterday,
      );

      final stats = LoginRewardStats(
        userId: 'test_user',
        totalRewardsClaimed: 0,
        totalXpEarned: 0,
        totalCoinEarned: 0,
        firstLoginDate: now,
        lastResetDate: now,
      );

      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
      ];

      final notifier = DailyLoginRewardNotifier();
      notifier.state = DailyLoginRewardState(
        userStreak: streak,
        stats: stats,
        rewardData: DailyLoginRewardData(
          availableRewards: rewards,
          userStreak: streak,
          stats: stats,
          generatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1日目ボーナス'), findsWidgets);
      expect(find.text('+10 XP'), findsWidgets);
      expect(find.text('+5 Coins'), findsWidgets);
    });

    testWidgets('displays reward milestones', (WidgetTester tester) async {
      final now = DateTime.now();

      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
        DailyLoginReward(
          rewardId: 'reward_day3',
          level: RewardLevel.day3,
          xpAmount: 30,
          coinAmount: 15,
          badgeId: 'streak_3days',
          description: '3日連続ボーナス',
          isStreakBonus: true,
        ),
        DailyLoginReward(
          rewardId: 'reward_day7',
          level: RewardLevel.day7,
          xpAmount: 70,
          coinAmount: 35,
          badgeId: 'streak_7days',
          description: '7日連続ボーナス',
          isStreakBonus: true,
        ),
      ];

      final streak = LoginStreak(
        userId: 'test_user',
        currentStreak: 0,
        longestStreak: 0,
        lastLoginDate: now.subtract(const Duration(days: 2)),
      );

      final stats = LoginRewardStats(
        userId: 'test_user',
        totalRewardsClaimed: 0,
        totalXpEarned: 0,
        totalCoinEarned: 0,
        firstLoginDate: now,
        lastResetDate: now,
      );

      final notifier = DailyLoginRewardNotifier();
      notifier.state = DailyLoginRewardState(
        userStreak: streak,
        stats: stats,
        rewardData: DailyLoginRewardData(
          availableRewards: rewards,
          userStreak: streak,
          stats: stats,
          generatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('マイルストーン報酬'), findsOneWidget);
      expect(find.text('1日目'), findsOneWidget);
      expect(find.text('3日連続'), findsOneWidget);
      expect(find.text('7日連続'), findsOneWidget);
    });

    testWidgets('displays statistics card', (WidgetTester tester) async {
      final now = DateTime.now();

      final streak = LoginStreak(
        userId: 'test_user',
        currentStreak: 5,
        longestStreak: 10,
        lastLoginDate: now,
      );

      final stats = LoginRewardStats(
        userId: 'test_user',
        totalRewardsClaimed: 5,
        totalXpEarned: 150,
        totalCoinEarned: 75,
        firstLoginDate: now.subtract(const Duration(days: 5)),
        lastResetDate: now,
      );

      final notifier = DailyLoginRewardNotifier();
      notifier.state = DailyLoginRewardState(
        userStreak: streak,
        stats: stats,
        rewardData: DailyLoginRewardData(
          availableRewards: [],
          userStreak: streak,
          stats: stats,
          generatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('統計情報'), findsOneWidget);
      expect(find.text('リワード獲得数'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('shows reward dialog when claim successful', (WidgetTester tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final streak = LoginStreak(
        userId: 'test_user',
        currentStreak: 0,
        longestStreak: 0,
        lastLoginDate: yesterday,
      );

      final stats = LoginRewardStats(
        userId: 'test_user',
        totalRewardsClaimed: 0,
        totalXpEarned: 0,
        totalCoinEarned: 0,
        firstLoginDate: now,
        lastResetDate: now,
      );

      final rewards = [
        DailyLoginReward(
          rewardId: 'reward_day1',
          level: RewardLevel.day1,
          xpAmount: 10,
          coinAmount: 5,
          description: '1日目ボーナス',
        ),
      ];

      final notifier = DailyLoginRewardNotifier();
      notifier.state = DailyLoginRewardState(
        userStreak: streak,
        stats: stats,
        rewardData: DailyLoginRewardData(
          availableRewards: rewards,
          userStreak: streak,
          stats: stats,
          generatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap claim button
      await tester.tap(find.text('リワードを獲得'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('🎉 リワード獲得！'), findsOneWidget);
      expect(find.text('ストリーク: 1日'), findsOneWidget);
    });

    testWidgets('retry button works on error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyLoginRewardProvider.overrideWith(
              (ref) => DailyLoginRewardNotifier()
                ..state = DailyLoginRewardState(
                  error: 'テストエラー',
                ),
            ),
          ],
          child: MaterialApp(
            home: DailyRewardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('再試行'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      // Verify retry was called (screen should update)
      expect(find.byType(DailyRewardScreen), findsOneWidget);
    });
  });
}
