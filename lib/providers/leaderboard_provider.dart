import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leaderboard.dart';
import '../models/learning_analytics.dart';
import '../models/multiplayer.dart';
import 'learning_analytics_provider.dart';
import 'multiplayer_provider.dart';

/// ランキング状態
class LeaderboardState {
  final LeaderboardData? leaderboardData;
  final UserRankingPosition? userRankingPosition;
  final Map<String, UserRankingPosition> userRankings; // userId -> position
  final List<RankingChangeNotification> notifications;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  LeaderboardState({
    this.leaderboardData,
    this.userRankingPosition,
    this.userRankings = const {},
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdatedAt,
  });

  LeaderboardState copyWith({
    LeaderboardData? leaderboardData,
    UserRankingPosition? userRankingPosition,
    Map<String, UserRankingPosition>? userRankings,
    List<RankingChangeNotification>? notifications,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) =>
      LeaderboardState(
        leaderboardData: leaderboardData ?? this.leaderboardData,
        userRankingPosition: userRankingPosition ?? this.userRankingPosition,
        userRankings: userRankings ?? this.userRankings,
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );

  Map<String, dynamic> toJson() => {
        'leaderboardData': leaderboardData?.toJson(),
        'userRankingPosition': userRankingPosition?.toJson(),
        'userRankings': userRankings.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        'notifications': notifications.map((e) => e.toJson()).toList(),
        'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      };

  factory LeaderboardState.fromJson(Map<String, dynamic> json) =>
      LeaderboardState(
        leaderboardData: json['leaderboardData'] != null
            ? LeaderboardData.fromJson(
                json['leaderboardData'] as Map<String, dynamic>)
            : null,
        userRankingPosition: json['userRankingPosition'] != null
            ? UserRankingPosition.fromJson(
                json['userRankingPosition'] as Map<String, dynamic>)
            : null,
        userRankings:
            ((json['userRankings'] as Map<String, dynamic>?) ?? {}).map(
          (k, v) => MapEntry(
            k,
            UserRankingPosition.fromJson(v as Map<String, dynamic>),
          ),
        ),
        notifications: ((json['notifications'] as List?) ?? [])
            .map((e) =>
                RankingChangeNotification.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastUpdatedAt: json['lastUpdatedAt'] != null
            ? DateTime.parse(json['lastUpdatedAt'] as String)
            : null,
      );
}

/// ランキング情報を管理するNotifier
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref ref;

  LeaderboardNotifier(this.ref) : super(LeaderboardState());

  String _generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// グローバルランキングを生成
  Future<LeaderboardData> generateGlobalLeaderboard({
    required LeaderboardTimeUnit timeUnit,
    int limit = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 学習分析データを取得
      final analyticsState = ref.read(learningAnalyticsProvider);

      // ランキングエントリを生成（実際のデータから）
      final entries = <GlobalLeaderboardEntry>[];

      // ダミーデータ生成（実装では実際のユーザーデータから生成）
      for (int i = 1; i <= limit; i++) {
        final level = 1 + (i ~/ 10);
        final totalXp = level * 1000;
        final matchesPlayed = Random().nextInt(50) + 5;
        final matchesWon = (matchesPlayed * (0.5 + Random().nextDouble() * 0.3)).toInt();

        entries.add(GlobalLeaderboardEntry(
          rank: i,
          userId: 'user-$i',
          username: 'user$i',
          displayName: 'ユーザー$i',
          profileImageUrl: null,
          level: level,
          totalXp: totalXp,
          averageAccuracy: 0.5 + Random().nextDouble() * 0.5,
          matchesWon: matchesWon,
          matchesPlayed: matchesPlayed,
          winRate: matchesPlayed > 0 ? matchesWon / matchesPlayed : 0.0,
          currentStreak: Random().nextInt(10),
          longestStreak: Random().nextInt(30),
          tier: GlobalLeaderboardEntry.calculateTier(i),
          lastUpdatedAt: DateTime.now(),
        ));
      }

      // カテゴリ別ランキングを生成
      final categoryRankings = <LearningCategory, List<CategoryLeaderboardEntry>>{};
      for (final category in LearningCategory.values) {
        final categoryEntries = <CategoryLeaderboardEntry>[];
        for (int i = 1; i <= 50; i++) {
          categoryEntries.add(CategoryLeaderboardEntry(
            rank: i,
            userId: 'user-${(i * 3) % 100}',
            username: 'user${(i * 3) % 100}',
            displayName: 'ユーザー${(i * 3) % 100}',
            category: category,
            accuracy: 0.5 + Random().nextDouble() * 0.5,
            quizzesCompleted: Random().nextInt(100) + 10,
            correctAnswers: Random().nextInt(80) + 5,
            lastUpdatedAt: DateTime.now(),
          ));
        }
        categoryRankings[category] = categoryEntries;
      }

      final leaderboardData = LeaderboardData(
        timeUnit: timeUnit,
        generatedAt: DateTime.now(),
        globalRankings: entries,
        categoryRankings: categoryRankings,
        recentChanges: [],
      );

      state = state.copyWith(
        leaderboardData: leaderboardData,
        lastUpdatedAt: DateTime.now(),
        isLoading: false,
      );

      await _persistLeaderboardData(leaderboardData);
      return leaderboardData;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// ユーザーのランキング位置を取得
  Future<UserRankingPosition> getUserRankingPosition(
    String userId, {
    required LeaderboardTimeUnit timeUnit,
  }) async {
    try {
      // ランキングデータから該当ユーザーを検索
      final leaderboard = state.leaderboardData ??
          await generateGlobalLeaderboard(timeUnit: timeUnit);

      final entry = leaderboard.globalRankings
          .firstWhere((e) => e.userId == userId, orElse: () => null as dynamic);

      if (entry == null) {
        throw Exception('User not found in rankings');
      }

      // カテゴリ別順位を取得
      final categoryRanks = <LearningCategory, int>{};
      for (final category in LearningCategory.values) {
        final categoryEntries =
            leaderboard.categoryRankings[category] ?? [];
        final categoryEntry = categoryEntries
            .firstWhere((e) => e.userId == userId, orElse: () => null as dynamic);
        if (categoryEntry != null) {
          categoryRanks[category] = categoryEntry.rank;
        }
      }

      // 以前のランク位置を取得
      final previousPosition =
          state.userRankings[userId] ?? UserRankingPosition(
        userId: userId,
        globalRank: entry.rank + 10,
        tier: GlobalLeaderboardEntry.calculateTier(entry.rank + 10),
        categoryRanks: categoryRanks,
        previousGlobalRank: entry.rank + 10,
        lastUpdatedAt: DateTime.now(),
      );

      final position = UserRankingPosition(
        userId: userId,
        globalRank: entry.rank,
        tier: entry.tier,
        categoryRanks: categoryRanks,
        previousGlobalRank: previousPosition.globalRank,
        lastUpdatedAt: DateTime.now(),
      );

      // ランク変動を検出して通知を生成
      if (position.globalRank != previousPosition.globalRank) {
        await _trackRankingChange(
          userId,
          previousPosition.globalRank,
          position.globalRank,
          previousPosition.tier,
          position.tier,
          timeUnit,
        );
      }

      state = state.copyWith(
        userRankingPosition: position,
        userRankings: {
          ...state.userRankings,
          userId: position,
        },
      );

      return position;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// ランキング変動を追跡
  Future<RankingChangeNotification> _trackRankingChange(
    String userId,
    int previousRank,
    int currentRank,
    RankingTier previousTier,
    RankingTier currentTier,
    LeaderboardTimeUnit timeUnit,
  ) async {
    final isPromotion = currentRank < previousRank;

    final notification = RankingChangeNotification(
      notificationId: _generateId('rank-change'),
      userId: userId,
      timeUnit: timeUnit,
      previousRank: previousRank,
      currentRank: currentRank,
      previousTier: previousTier,
      currentTier: currentTier,
      isPromotion: isPromotion,
      createdAt: DateTime.now(),
      isRead: false,
    );

    state = state.copyWith(
      notifications: [notification, ...state.notifications]
          .take(100)
          .toList(), // Keep last 100
    );

    await _persistNotifications();
    return notification;
  }

  /// ランキングページを取得（ページネーション対応）
  Future<List<GlobalLeaderboardEntry>> getLeaderboardPage({
    required int pageSize,
    required int pageIndex,
    LeaderboardRegion region = LeaderboardRegion.global,
  }) async {
    try {
      final leaderboard = state.leaderboardData ??
          await generateGlobalLeaderboard(timeUnit: LeaderboardTimeUnit.allTime);

      final entries = leaderboard.globalRankings;
      final startIndex = pageIndex * pageSize;
      final endIndex = (startIndex + pageSize)
          .clamp(0, entries.length)
          .toInt();

      if (startIndex >= entries.length) {
        return [];
      }

      return entries.sublist(startIndex, endIndex);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// ローカルランキングデータを読込
  Future<void> loadLocalLeaderboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('leaderboard_data');

      if (cached != null) {
        final Map<String, dynamic> json = _jsonDecode(cached);
        final leaderboardData = LeaderboardData.fromJson(json);
        state = state.copyWith(leaderboardData: leaderboardData);
      }

      // キャッシュされた通知を読込
      final cachedNotifications = prefs.getString('leaderboard_notifications');
      if (cachedNotifications != null) {
        final List<dynamic> json = _jsonDecode(cachedNotifications);
        final notifications = json
            .map((e) => RankingChangeNotification.fromJson(
                e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(notifications: notifications);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// ランキングデータを永続化
  Future<void> _persistLeaderboardData(LeaderboardData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _jsonEncode(data.toJson());
      await prefs.setString('leaderboard_data', json);
    } catch (e) {
      // Silently fail persistence
    }
  }

  /// 通知を永続化
  Future<void> _persistNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _jsonEncode(
        state.notifications.map((e) => e.toJson()).toList(),
      );
      await prefs.setString('leaderboard_notifications', json);
    } catch (e) {
      // Silently fail persistence
    }
  }

  /// 通知を既読にする
  Future<void> markNotificationAsRead(String notificationId) async {
    final updatedNotifications = state.notifications.map((n) {
      if (n.notificationId == notificationId) {
        return RankingChangeNotification(
          notificationId: n.notificationId,
          userId: n.userId,
          timeUnit: n.timeUnit,
          previousRank: n.previousRank,
          currentRank: n.currentRank,
          previousTier: n.previousTier,
          currentTier: n.currentTier,
          isPromotion: n.isPromotion,
          createdAt: n.createdAt,
          isRead: true,
        );
      }
      return n;
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
    await _persistNotifications();
  }

  /// 未読通知カウントを取得
  int getUnreadNotificationCount() =>
      state.notifications.where((n) => !n.isRead).length;

  // JSON serialization helpers
  dynamic _jsonDecode(String source) {
    // Simple JSON parsing - in production use json package
    try {
      if (source.startsWith('[')) {
        return _parseJsonArray(source);
      } else if (source.startsWith('{')) {
        return _parseJsonObject(source);
      }
    } catch (e) {
      // Fallback to empty structures
      return source.startsWith('[') ? [] : {};
    }
    return source.startsWith('[') ? [] : {};
  }

  String _jsonEncode(dynamic value) {
    // Simple JSON encoding - in production use json package
    if (value is String) return value;
    if (value is Map) {
      final entries = (value as Map).entries.map((e) {
        final key = '"${e.key}"';
        final val = _jsonEncode(e.value);
        return '$key:$val';
      }).join(',');
      return '{$entries}';
    }
    if (value is List) {
      final items = (value as List).map(_jsonEncode).join(',');
      return '[$items]';
    }
    if (value is num || value is bool) return value.toString();
    if (value is DateTime) return '"${value.toIso8601String()}"';
    if (value == null) return 'null';
    return '"$value"';
  }

  dynamic _parseJsonArray(String source) {
    // Minimal array parsing
    final trimmed = source.trim();
    if (trimmed == '[]') return [];

    // Remove outer brackets and parse objects
    final content = trimmed.substring(1, trimmed.length - 1).trim();
    if (content.isEmpty) return [];

    // Split by top-level commas (simplified)
    final items = <dynamic>[];
    var depth = 0;
    var current = '';

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '{' || char == '[') {
        depth++;
      } else if (char == '}' || char == ']') {
        depth--;
      } else if (char == ',' && depth == 0) {
        items.add(_parseJsonValue(current.trim()));
        current = '';
        continue;
      }
      current += char;
    }

    if (current.isNotEmpty) {
      items.add(_parseJsonValue(current.trim()));
    }

    return items;
  }

  dynamic _parseJsonObject(String source) {
    // Minimal object parsing
    final trimmed = source.trim();
    if (trimmed == '{}') return {};

    final result = <String, dynamic>{};
    final content = trimmed.substring(1, trimmed.length - 1).trim();
    if (content.isEmpty) return result;

    // Simple key-value parsing (very simplified)
    var depth = 0;
    var current = '';

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '{' || char == '[') {
        depth++;
      } else if (char == '}' || char == ']') {
        depth--;
      } else if (char == ',' && depth == 0) {
        final parts = current.trim().split(':');
        if (parts.length == 2) {
          final key = parts[0].trim().replaceAll('"', '');
          result[key] = _parseJsonValue(parts[1].trim());
        }
        current = '';
        continue;
      }
      current += char;
    }

    if (current.isNotEmpty) {
      final parts = current.trim().split(':');
      if (parts.length == 2) {
        final key = parts[0].trim().replaceAll('"', '');
        result[key] = _parseJsonValue(parts[1].trim());
      }
    }

    return result;
  }

  dynamic _parseJsonValue(String value) {
    final trimmed = value.trim();
    if (trimmed == 'null') return null;
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;
    if (trimmed.startsWith('"')) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    if (trimmed.startsWith('{')) {
      return _parseJsonObject(trimmed);
    }
    if (trimmed.startsWith('[')) {
      return _parseJsonArray(trimmed);
    }
    final parsedNum = num.tryParse(trimmed);
    if (parsedNum != null) return parsedNum;
    return trimmed;
  }
}

/// ランキング情報Provider
final leaderboardProvider =
    StateNotifierProvider.autoDispose<LeaderboardNotifier, LeaderboardState>(
  (ref) => LeaderboardNotifier(ref),
);

/// グローバルランキングProvider
final globalLeaderboardProvider =
    FutureProvider.autoDispose<LeaderboardData?>((ref) async {
  final leaderboard = ref.watch(leaderboardProvider);
  if (leaderboard.leaderboardData != null) {
    return leaderboard.leaderboardData;
  }

  final notifier = ref.read(leaderboardProvider.notifier);
  return await notifier.generateGlobalLeaderboard(
    timeUnit: LeaderboardTimeUnit.allTime,
  );
});

/// ユーザーランキング位置Provider (family)
final userRankingPositionProvider =
    FutureProvider.autoDispose.family<UserRankingPosition?, String>((ref, userId) async {
  final notifier = ref.watch(leaderboardProvider.notifier);
  try {
    return await notifier.getUserRankingPosition(
      userId,
      timeUnit: LeaderboardTimeUnit.allTime,
    );
  } catch (e) {
    return null;
  }
});

/// ランキング変動通知Provider
final rankingNotificationsProvider =
    Provider.autoDispose<List<RankingChangeNotification>>((ref) {
  return ref.watch(leaderboardProvider).notifications;
});

/// 未読通知カウントProvider
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifier = ref.watch(leaderboardProvider.notifier);
  return notifier.getUnreadNotificationCount();
});

/// ランキングページProvider (family)
final leaderboardPageProvider = FutureProvider.autoDispose
    .family<List<GlobalLeaderboardEntry>, ({int pageSize, int pageIndex})>(
  (ref, params) async {
    final notifier = ref.watch(leaderboardProvider.notifier);
    return await notifier.getLeaderboardPage(
      pageSize: params.pageSize,
      pageIndex: params.pageIndex,
    );
  },
);
