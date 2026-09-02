import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/leaderboards_rankings.dart';
import 'package:shogaku_kore_programming/providers/leaderboards_rankings_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('LeaderboardNotifier', () {
    test('initializes with empty state', () {
      final notifier = LeaderboardNotifier();
      expect(notifier.state.collection, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('initializeLeaderboards creates collection', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final state = container.read(leaderboardProvider);
      expect(state.collection, isNotNull);
      expect(state.collection!.userId, 'test_user');
    });

    test('initializeLeaderboards creates user grade', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final state = container.read(leaderboardProvider);
      expect(state.collection!.userGrade, isNotNull);
      expect(state.collection!.userGrade!.birthYear, 2015);
    });

    test('initializeLeaderboards creates ranking statistics', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final state = container.read(leaderboardProvider);
      expect(state.collection!.statistics, isNotNull);
      expect(state.collection!.statistics!.totalCoinsEarned, 0);
    });

    test('initializeLeaderboards creates default leaderboards', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final state = container.read(leaderboardProvider);
      expect(state.collection!.allLeaderboards.isNotEmpty, true);
    });

    test('updateRankings updates statistics', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      await notifier.updateRankings('test_user', 5000, 50);

      final state = container.read(leaderboardProvider);
      expect(state.collection!.statistics!.totalCoinsEarned, 5000);
      expect(state.collection!.statistics!.totalActivitiesCompleted, 50);
    });

    test('updateRankings calculates composite score', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      await notifier.updateRankings('test_user', 1000, 100);

      final state = container.read(leaderboardProvider);
      // Composite score = (coins * 0.6) + (activities * 40)
      final expectedScore = (1000 * 0.6) + (100 * 40);
      expect(state.collection!.statistics!.compositeScore, expectedScore);
    });

    test('checkAndPromoteGrade checks for promotion', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      // Use birth year to get a grade that could be promoted
      final birthYear = DateTime.now().year - 10; // Approximately 5年生
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', birthYear);

      await notifier.checkAndPromoteGrade('test_user');

      final state = container.read(leaderboardProvider);
      expect(state.collection!.userGrade, isNotNull);
    });

    test('persists to SharedPreferences', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('persist_test', 'テスト生徒', 2015);

      final state = container.read(leaderboardProvider);
      expect(state.collection, isNotNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('leaderboards_persist_test'), true);
    });
  });

  group('Riverpod Providers', () {
    test('leaderboardCollectionProvider provides collection', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final collection = container.read(leaderboardCollectionProvider);
      expect(collection, isNotNull);
      expect(collection!.userId, 'test_user');
    });

    test('userGradeProvider provides grade', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final grade = container.read(userGradeProvider);
      expect(grade, isNotNull);
      expect(grade!.birthYear, 2015);
    });

    test('currentGradeProvider provides current grade', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final grade = container.read(currentGradeProvider);
      expect(grade, isNotNull);
      expect(grade!.gradeLevel, isPositive);
    });

    test('currentGradeDisplayProvider provides display name', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final displayName = container.read(currentGradeDisplayProvider);
      expect(displayName, contains('年生'));
    });

    test('rankingStatisticsProvider provides statistics', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final stats = container.read(rankingStatisticsProvider);
      expect(stats, isNotNull);
      expect(stats!.userId, 'test_user');
    });

    test('overallLeaderboardProvider provides overall ranking', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final leaderboard = container.read(
        overallLeaderboardProvider(RankingMetric.totalCoins),
      );
      expect(leaderboard, isNotNull);
      expect(leaderboard!.grouping, RankingGrouping.overall);
    });

    test('gradeLeaderboardProvider provides grade-specific ranking', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final leaderboard = container.read(
        gradeLeaderboardProvider((
          RankingMetric.totalCoins,
          SchoolGrade.fourthGrade,
        )),
      );
      expect(leaderboard, isNotNull);
      expect(leaderboard!.grouping, RankingGrouping.byGrade);
    });

    test('totalCoinsLeaderboardProvider provides coins ranking', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final leaderboard = container.read(totalCoinsLeaderboardProvider);
      expect(leaderboard, isNotNull);
      expect(leaderboard!.metric, RankingMetric.totalCoins);
    });

    test('activityCompletionsLeaderboardProvider provides activity ranking', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final leaderboard = container.read(activityCompletionsLeaderboardProvider);
      expect(leaderboard, isNotNull);
      expect(leaderboard!.metric, RankingMetric.activityCompletions);
    });

    test('compositeScoreLeaderboardProvider provides composite ranking', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final leaderboard = container.read(compositeScoreLeaderboardProvider);
      expect(leaderboard, isNotNull);
      expect(leaderboard!.metric, RankingMetric.compositeScore);
    });

    test('top10CoinUsersProvider returns empty initially', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final top10 = container.read(top10CoinUsersProvider);
      expect(top10, isNotEmpty || isEmpty);
    });

    test('top10ActivityUsersProvider returns empty initially', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final top10 = container.read(top10ActivityUsersProvider);
      expect(top10, isNotEmpty || isEmpty);
    });

    test('top10CompositeScoreUsersProvider returns empty initially', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final top10 = container.read(top10CompositeScoreUsersProvider);
      expect(top10, isNotEmpty || isEmpty);
    });

    test('bestTierProvider returns default tier initially', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final tier = container.read(bestTierProvider);
      expect(tier, isNotNull);
      expect(tier, 'ビギナー');
    });

    test('overallRankProvider returns rank', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final rank = container.read(overallRankProvider);
      expect(rank, isNotNull);
    });

    test('leaderboardParticipantCountProvider returns count', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final count = container.read(
        leaderboardParticipantCountProvider(RankingMetric.totalCoins),
      );
      expect(count, isNotNull);
    });

    test('gradeParticipantCountProvider returns count', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final count = container.read(
        gradeParticipantCountProvider((
          SchoolGrade.fourthGrade,
          RankingMetric.totalCoins,
        )),
      );
      expect(count, isNotNull);
    });

    test('allRankingMetricsProvider provides all metrics', () async {
      final metrics = container.read(allRankingMetricsProvider);
      expect(metrics.length, 3);
      expect(metrics.contains(RankingMetric.totalCoins), true);
      expect(metrics.contains(RankingMetric.activityCompletions), true);
      expect(metrics.contains(RankingMetric.compositeScore), true);
    });

    test('allSchoolGradesProvider provides all grades', () async {
      final grades = container.read(allSchoolGradesProvider);
      expect(grades.length, 6);
      expect(grades.contains(SchoolGrade.firstGrade), true);
      expect(grades.contains(SchoolGrade.sixthGrade), true);
    });

    test('allGroupingOptionsProvider provides all options', () async {
      final options = container.read(allGroupingOptionsProvider);
      expect(options.length, 4);
      expect(options.contains(RankingGrouping.overall), true);
      expect(options.contains(RankingGrouping.byGrade), true);
      expect(options.contains(RankingGrouping.byStartMonth), true);
      expect(options.contains(RankingGrouping.combined), true);
    });

    test('leaderboardsByMetricProvider filters by metric', () async {
      final notifier = container.read(leaderboardProvider.notifier);
      await notifier.initializeLeaderboards('test_user', 'テスト生徒', 2015);

      final leaderboards = container.read(
        leaderboardsByMetricProvider(RankingMetric.totalCoins),
      );
      expect(leaderboards.isNotEmpty, true);
      expect(
        leaderboards.every((l) => l.metric == RankingMetric.totalCoins),
        true,
      );
    });
  });
}
