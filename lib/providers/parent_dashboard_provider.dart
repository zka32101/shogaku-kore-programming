/// 保護者ダッシュボード状態管理プロバイダ
library parent_dashboard_provider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/parent_dashboard.dart';
import '../models/learning_analytics.dart';

/// 保護者ダッシュボード状態
class ParentDashboardState {
  final ParentDashboardData? dashboardData;
  final List<ParentAlert> alerts;
  final ParentNotificationSettings? notificationSettings;
  final List<LearningGoal> learningGoals;
  final DateTime? lastUpdatedAt;
  final bool isLoading;

  ParentDashboardState({
    this.dashboardData,
    this.alerts = const [],
    this.notificationSettings,
    this.learningGoals = const [],
    this.lastUpdatedAt,
    this.isLoading = false,
  });

  ParentDashboardState copyWith({
    ParentDashboardData? dashboardData,
    List<ParentAlert>? alerts,
    ParentNotificationSettings? notificationSettings,
    List<LearningGoal>? learningGoals,
    DateTime? lastUpdatedAt,
    bool? isLoading,
  }) {
    return ParentDashboardState(
      dashboardData: dashboardData ?? this.dashboardData,
      alerts: alerts ?? this.alerts,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      learningGoals: learningGoals ?? this.learningGoals,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 保護者ダッシュボード状態管理クラス
class ParentDashboardNotifier extends StateNotifier<ParentDashboardState> {
  ParentDashboardNotifier() : super(ParentDashboardState());

  /// ダッシュボードデータを更新（子どもの学習データから集計）
  Future<void> updateDashboardData(
    String childId,
    OverallLearningProgress learningProgress,
    List<String> earnedBadgeIds,
    int currentLevel,
    double levelProgress,
    int dailyMissionsCompleted,
    int dailyMissionsTotal,
  ) async {
    state = state.copyWith(isLoading: true);

    try {
      final weakAreas = _identifyWeakAreas(learningProgress);
      final recentTrends = _generateRecentTrends(learningProgress);
      final generalInsight = _generateGeneralInsight(
        learningProgress,
        weakAreas,
        currentLevel,
      );

      final childProfile = ChildProfile(
        childId: childId,
        childName: 'Student', // This would come from actual child data
        gradeLevel: 3, // Default, would be from actual data
        createdAt: DateTime.now(),
        isActive: true,
      );

      final dashboardData = ParentDashboardData(
        childProfile: childProfile,
        learningProgress: learningProgress,
        earnedBadgeIds: earnedBadgeIds,
        currentLevel: currentLevel,
        levelProgress: levelProgress,
        dailyMissionsCompleted: dailyMissionsCompleted,
        dailyMissionsTotal: dailyMissionsTotal,
        weakAreas: weakAreas,
        recentTrends: recentTrends,
        generalInsight: generalInsight,
        generatedAt: DateTime.now(),
      );

      state = state.copyWith(
        dashboardData: dashboardData,
        lastUpdatedAt: DateTime.now(),
        isLoading: false,
      );

      await _saveDashboardData(dashboardData);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// 弱点エリアを特定
  List<WeakArea> _identifyWeakAreas(OverallLearningProgress progress) {
    final weakAreas = <WeakArea>[];

    progress.categoryStats.forEach((category, count) {
      if (count == 0) return;

      // カテゴリ別の正答率を計算
      // 簡略版：全体正答率を使用
      final accuracy = progress.overallAccuracy;

      if (accuracy < 75.0) {
        weakAreas.add(WeakArea(
          category: category,
          accuracy: accuracy,
          attemptCount: count,
          recommendation: _getRecommendation(category, accuracy),
        ));
      }
    });

    // 正答率が低い順にソート
    weakAreas.sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return weakAreas.take(3).toList(); // 上位3つまで
  }

  /// 推奨メッセージを生成
  String _getRecommendation(LearningCategory category, double accuracy) {
    final categoryName = _getCategoryName(category);

    if (accuracy < 50.0) {
      return '$categoryNameは重点的に学習が必要です。基礎から復習することをお勧めします。';
    } else if (accuracy < 70.0) {
      return '$categoryNameをもっと練習すると、さらに得点が上がります。';
    } else {
      return '$categoryNameは順調に進んでいます。もう少しで完璧になりそうです。';
    }
  }

  /// カテゴリ名を取得
  String _getCategoryName(LearningCategory category) {
    switch (category) {
      case LearningCategory.programming:
        return 'プログラミング';
      case LearningCategory.mathematics:
        return '数学';
      case LearningCategory.algorithms:
        return 'アルゴリズム';
      case LearningCategory.dataStructure:
        return 'データ構造';
      case LearningCategory.other:
        return 'その他';
    }
  }

  /// 最近のトレンドを生成（過去14日間）
  List<LearningTimeTrend> _generateRecentTrends(
    OverallLearningProgress progress,
  ) {
    final trends = <LearningTimeTrend>[];
    final now = DateTime.now();

    // 実装例：14日間のダミートレンド
    // 実際にはローカルデータから取得する
    for (int i = 13; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      trends.add(LearningTimeTrend(
        date: date,
        timeSpent: Duration(minutes: 20 + (i % 40)),
        quizzesCompleted: 3 + (i % 7),
      ));
    }

    return trends;
  }

  /// 総合インサイトを生成
  String _generateGeneralInsight(
    OverallLearningProgress progress,
    List<WeakArea> weakAreas,
    int currentLevel,
  ) {
    if (progress.overallAccuracy >= 90.0 && progress.currentStreak >= 7) {
      return '素晴らしい成績です！🌟 このペースを続ければ、すぐに次のレベルに到達できます。';
    } else if (progress.overallAccuracy >= 80.0) {
      return '順調に進んでいます！📈 ${weakAreas.isNotEmpty ? 'ただし${weakAreas.first.category.name}をもう少し練習するとさらに良くなります。' : '引き続き頑張ってください。'}';
    } else if (progress.currentStreak >= 5) {
      return 'コンスタントに学習を継続できています。💪 もう少し難しい問題にチャレンジしてみてください。';
    } else {
      return '学習を始めた直後です。毎日少しずつ続けることが大切です。📚';
    }
  }

  /// 通知設定を更新
  Future<void> updateNotificationSettings(
    ParentNotificationSettings settings,
  ) async {
    state = state.copyWith(notificationSettings: settings);
    await _saveNotificationSettings(settings);
  }

  /// 学習目標を追加
  Future<void> addLearningGoal(
    String childId,
    String title,
    String description,
    LearningCategory category,
    double targetAccuracy,
    int targetQuizzesCount,
    DateTime deadline,
  ) async {
    final goal = LearningGoal(
      goalId: _generateId('goal'),
      childId: childId,
      title: title,
      description: description,
      category: category,
      targetAccuracy: targetAccuracy,
      targetQuizzesCount: targetQuizzesCount,
      deadline: deadline,
      createdAt: DateTime.now(),
    );

    final updatedGoals = [...state.learningGoals, goal];
    state = state.copyWith(learningGoals: updatedGoals);
    await _saveLearningGoals(updatedGoals);
  }

  /// 学習目標を完了
  Future<void> completeGoal(String goalId) async {
    final updatedGoals = state.learningGoals.map((goal) {
      if (goal.goalId == goalId) {
        return goal.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
      }
      return goal;
    }).toList();

    state = state.copyWith(learningGoals: updatedGoals);
    await _saveLearningGoals(updatedGoals);

    // 目標達成アラートを追加
    await addAlert(
      goal.childId,
      'goal達成',
      '${state.learningGoals.firstWhere((g) => g.goalId == goalId).title}を達成しました！',
      ParentAlertType.goalCompleted,
    );
  }

  /// アラートを追加
  Future<void> addAlert(
    String childId,
    String title,
    String message,
    ParentAlertType alertType,
  ) async {
    final alert = ParentAlert(
      alertId: _generateId('alert'),
      parentId: 'parent_id', // 実装時は実際の親IDを使用
      childId: childId,
      alertType: alertType,
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );

    final updatedAlerts = [alert, ...state.alerts];
    // 最新100件まで保持
    final limitedAlerts = updatedAlerts.take(100).toList();

    state = state.copyWith(alerts: limitedAlerts);
    await _saveAlerts(limitedAlerts);
  }

  /// アラートを既読にマーク
  Future<void> markAlertAsRead(String alertId) async {
    final updatedAlerts = state.alerts.map((alert) {
      if (alert.alertId == alertId) {
        return ParentAlert(
          alertId: alert.alertId,
          parentId: alert.parentId,
          childId: alert.childId,
          alertType: alert.alertType,
          title: alert.title,
          message: alert.message,
          createdAt: alert.createdAt,
          isRead: true,
          readAt: DateTime.now(),
          metadata: alert.metadata,
        );
      }
      return alert;
    }).toList();

    state = state.copyWith(alerts: updatedAlerts);
    await _saveAlerts(updatedAlerts);
  }

  /// ローカルに保存
  Future<void> _saveDashboardData(ParentDashboardData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'parent_dashboard_data',
        jsonEncode(data.toJson()),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 通知設定をローカルに保存
  Future<void> _saveNotificationSettings(
    ParentNotificationSettings settings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'parent_notification_settings',
        jsonEncode(settings.toJson()),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 学習目標をローカルに保存
  Future<void> _saveLearningGoals(List<LearningGoal> goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'parent_learning_goals',
        goals.map((g) => jsonEncode(g.toJson())).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// アラートをローカルに保存
  Future<void> _saveAlerts(List<ParentAlert> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'parent_alerts',
        alerts.map((a) => jsonEncode(a.toJson())).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ローカルデータを読み込み
  Future<void> loadLocalData(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ダッシュボードデータを読み込み
      final dashboardJson = prefs.getString('parent_dashboard_data');
      final dashboardData = dashboardJson != null
          ? ParentDashboardData.fromJson(jsonDecode(dashboardJson))
          : null;

      // 通知設定を読み込み
      final settingsJson = prefs.getString('parent_notification_settings');
      final notificationSettings = settingsJson != null
          ? ParentNotificationSettings.fromJson(jsonDecode(settingsJson))
          : null;

      // 学習目標を読み込み
      final goalsJson = prefs.getStringList('parent_learning_goals') ?? [];
      final learningGoals = goalsJson
          .map((g) => LearningGoal.fromJson(jsonDecode(g)))
          .toList();

      // アラートを読み込み
      final alertsJson = prefs.getStringList('parent_alerts') ?? [];
      final alerts =
          alertsJson.map((a) => ParentAlert.fromJson(jsonDecode(a))).toList();

      state = state.copyWith(
        dashboardData: dashboardData,
        notificationSettings: notificationSettings,
        learningGoals: learningGoals,
        alerts: alerts,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ユニークなIDを生成
  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return '${prefix}_${timestamp}_$random';
  }
}

/// 保護者ダッシュボード状態プロバイダ
final parentDashboardProvider =
    StateNotifierProvider<ParentDashboardNotifier, ParentDashboardState>(
  (ref) => ParentDashboardNotifier(),
);

/// 子どものダッシュボード概要プロバイダ
final childDashboardOverviewProvider = FutureProvider<ParentDashboardData?>(
  (ref) async {
    final state = ref.watch(parentDashboardProvider);
    return state.dashboardData;
  },
);

/// アラートリストプロバイダ
final parentAlertsProvider = FutureProvider<List<ParentAlert>>(
  (ref) async {
    final state = ref.watch(parentDashboardProvider);
    return state.alerts;
  },
);

/// 未読アラート数プロバイダ
final unreadAlertsCountProvider = FutureProvider<int>(
  (ref) async {
    final alerts = await ref.watch(parentAlertsProvider.future);
    return alerts.where((a) => !a.isRead).length;
  },
);

/// 学習目標リストプロバイダ
final learningGoalsProvider = FutureProvider<List<LearningGoal>>(
  (ref) async {
    final state = ref.watch(parentDashboardProvider);
    return state.learningGoals;
  },
);

/// 進行中の目標プロバイダ
final activeGoalsProvider = FutureProvider<List<LearningGoal>>(
  (ref) async {
    final goals = await ref.watch(learningGoalsProvider.future);
    return goals.where((g) => !g.isCompleted).toList();
  },
);

/// 通知設定プロバイダ
final notificationSettingsProvider = FutureProvider<ParentNotificationSettings?>(
  (ref) async {
    final state = ref.watch(parentDashboardProvider);
    return state.notificationSettings;
  },
);
