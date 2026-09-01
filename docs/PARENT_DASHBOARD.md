# 保護者ダッシュボードシステム

## 概要

保護者ダッシュボードは、保護者・監督者が子どもの学習進捗を総合的に監視・管理するゲーム化要素です。学習分析、達成度、弱点分析、アラート機能を統合し、子どもの学習習慣と成長を可視化します。保護者は子どもの学習パターンを理解し、適切なサポート・指導ができます。

## 主な機能

✅ **子どもプロファイル管理**: 複数の子どもの学習状況を一元管理  
✅ **学習進捗総覧**: リアルタイムの正答率、学習時間、ストリークを表示  
✅ **弱点分析**: カテゴリ別の低い精度エリアを特定し改善案を提供  
✅ **学習目標設定**: カテゴリ別・期限付きの目標管理と進捗追跡  
✅ **アラート機能**: 正答率低下、ストリーク途絶、目標達成時の通知  
✅ **通知設定**: 保護者向けの詳細な通知カスタマイズ  
✅ **学習トレンド**: 過去14日間の学習時間・問題数を可視化  
✅ **インサイト生成**: 子どもの学習パターンに基づいた自動アドバイス

## アーキテクチャ

### モデル

#### ChildProfile (子どもプロファイル)

```dart
class ChildProfile {
  final String childId;                    // 子どもID
  final String childName;                  // 子どもの名前
  final int gradeLevel;                    // 学年
  final DateTime createdAt;                // 登録日
  final String? profileImageUrl;           // プロフィール画像
  final DateTime? lastActiveAt;            // 最終アクティビティ時刻
  final bool isActive;                     // アクティブフラグ
}
```

#### WeakArea (弱点エリア)

```dart
class WeakArea {
  final LearningCategory category;         // カテゴリ
  final double accuracy;                   // 正答率（0.0-100.0）
  final int attemptCount;                  // 試みた回数
  final String recommendation;             // 改善案
}
```

#### LearningTimeTrend (学習時間トレンド)

```dart
class LearningTimeTrend {
  final DateTime date;                     // 日付
  final Duration timeSpent;                // 学習時間
  final int quizzesCompleted;              // 完了したクイズ数
}
```

#### ParentDashboardData (保護者ダッシュボード総合データ)

```dart
class ParentDashboardData {
  final ChildProfile childProfile;         // 子どもプロファイル
  final OverallLearningProgress learningProgress; // 学習進捗
  final List<String> earnedBadgeIds;       // 獲得バッジID
  final int currentLevel;                  // 現在のレベル
  final double levelProgress;              // レベル進捗（0.0-100.0）
  final int dailyMissionsCompleted;        // 本日の完了ミッション数
  final int dailyMissionsTotal;            // 本日の総ミッション数
  final List<WeakArea> weakAreas;          // 弱点エリア
  final List<LearningTimeTrend> recentTrends; // 過去14日間のトレンド
  final String? generalInsight;            // 総合インサイト
  final DateTime generatedAt;              // 生成時刻
}
```

#### ParentNotificationSettings (保護者通知設定)

```dart
class ParentNotificationSettings {
  final String parentId;
  final String childId;
  final bool dailyReportEnabled;           // 日報有効フラグ
  final bool weeklyReportEnabled;          // 週報有効フラグ
  final bool badgeAchievementNotification;  // バッジ達成通知
  final bool lowAccuracyAlert;             // 正答率低下アラート
  final double lowAccuracyThreshold;       // 正答率アラート閾値
  final bool streakBreakAlert;             // ストリーク途絶アラート
  final bool learningTimeAlert;            // 学習時間不足アラート
  final int minimumDailyMinutes;           // 1日の最小学習時間（分）
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### LearningGoal (学習目標)

```dart
class LearningGoal {
  final String goalId;
  final String childId;
  final String title;                      // 目標タイトル
  final String description;                // 目標説明
  final LearningCategory category;         // カテゴリ
  final double targetAccuracy;             // 目標正答率
  final int targetQuizzesCount;            // 目標問題数
  final DateTime deadline;                 // 期限
  final bool isCompleted;                  // 完了フラグ
  final DateTime createdAt;
  final DateTime? completedAt;             // 完了時刻
}
```

#### ParentAlert (保護者向けアラート)

```dart
class ParentAlert {
  final String alertId;
  final String parentId;
  final String childId;
  final ParentAlertType alertType;         // アラート種別
  final String title;                      // タイトル
  final String message;                    // メッセージ
  final DateTime createdAt;
  final bool isRead;                       // 既読フラグ
  final DateTime? readAt;                  // 既読時刻
  final Map<String, dynamic>? metadata;    // 追加情報
}
```

### Enum定義

#### ParentAlertType (保護者アラート種別)

```dart
enum ParentAlertType {
  lowAccuracy,      // 正答率低下
  streakBroken,     // ストリーク途絶
  goalCompleted,    // 目標達成
  badgeEarned,      // バッジ獲得
  noActivity,       // 学習なし
  levelUp,          // レベルアップ
  weeklyReport,     // 週間レポート
}
```

### 状態管理

#### ParentDashboardState

```dart
class ParentDashboardState {
  final ParentDashboardData? dashboardData;
  final List<ParentAlert> alerts;
  final ParentNotificationSettings? notificationSettings;
  final List<LearningGoal> learningGoals;
  final DateTime? lastUpdatedAt;
  final bool isLoading;
}
```

#### ParentDashboardNotifier

子どもの学習データを保護者用に集計・管理します。

**主要メソッド:**

- `updateDashboardData()` - ダッシュボードデータを更新（学習分析から集計）
- `addLearningGoal()` - 新しい学習目標を追加
- `completeGoal()` - 目標を完了マーク
- `addAlert()` - アラートを追加
- `markAlertAsRead()` - アラートを既読にマーク
- `updateNotificationSettings()` - 通知設定を更新
- `loadLocalData()` - ローカルストレージからデータ復元

### プロバイダ

```dart
// 保護者ダッシュボード状態プロバイダ
final parentDashboardProvider = 
  StateNotifierProvider<ParentDashboardNotifier, ParentDashboardState>(
    (ref) => ParentDashboardNotifier(),
  );

// 子どものダッシュボード概要プロバイダ
final childDashboardOverviewProvider = 
  FutureProvider<ParentDashboardData?>((ref) async { ... });

// アラートリストプロバイダ
final parentAlertsProvider = 
  FutureProvider<List<ParentAlert>>((ref) async { ... });

// 未読アラート数プロバイダ
final unreadAlertsCountProvider = 
  FutureProvider<int>((ref) async { ... });

// 学習目標リストプロバイダ
final learningGoalsProvider = 
  FutureProvider<List<LearningGoal>>((ref) async { ... });

// 進行中の目標プロバイダ
final activeGoalsProvider = 
  FutureProvider<List<LearningGoal>>((ref) async { ... });

// 通知設定プロバイダ
final notificationSettingsProvider = 
  FutureProvider<ParentNotificationSettings?>((ref) async { ... });
```

## UIコンポーネント

### ParentDashboardScreen

メインの保護者ダッシュボード画面

**表示内容:**
- 子どもプロファイル（プロフィール画像、名前、学年）
- 学習進捗サマリー（累計クイズ数、平均正答率、ストリーク）
- 本日のミッション進捗
- 現在のレベルと経験値進捗
- 弱点エリアと改善案
- アラート通知（未読件数バッジ付き）
- 学習トレンドグラフ（過去14日間）

### ChildProgressCard

子どもの総合進捗を表示

```dart
ChildProgressCard(
  childProfile: profile,
  totalQuizzes: 150,
  averageAccuracy: 85.5,
  currentStreak: 7,
  longestStreak: 12,
)
```

### WeakAreaCard

弱点エリアと改善案を表示

```dart
WeakAreaCard(
  weakAreas: [
    WeakArea(
      category: LearningCategory.mathematics,
      accuracy: 72.0,
      attemptCount: 20,
      recommendation: 'もっと練習が必要です',
    ),
  ],
)
```

### LearningGoalsWidget

学習目標の進捗を表示

```dart
LearningGoalsWidget(
  goals: [
    LearningGoal(
      title: 'マスター数学',
      description: '数学の問題を90%の精度で解く',
      category: LearningCategory.mathematics,
      targetAccuracy: 90.0,
      targetQuizzesCount: 100,
      deadline: deadline,
    ),
  ],
)
```

### TrendChart

学習時間と問題数の推移グラフ

```dart
TrendChart(
  trends: recentTrends,
  timeRange: TrendTimeRange.twoWeeks,
)
```

### AlertsPanel

アラートと通知をスクロール可能なパネルで表示

```dart
AlertsPanel(
  alerts: alerts,
  onAlertTap: (alert) => handleAlertTap(alert),
  onMarkAsRead: (alertId) => markAlertAsRead(alertId),
)
```

### NotificationSettingsScreen

通知設定画面

**設定項目:**
- 日報・週報の有効/無効
- アラート種別の有効/無効
- 正答率アラート閾値
- 最小学習時間設定

## 使用方法

### 基本的な使用例

#### 1. ダッシュボードを初期化・更新

```dart
@override
void initState() {
  super.initState();
  
  // 学習分析から集計したデータで更新
  final notifier = ref.read(parentDashboardProvider.notifier);
  final learningProgress = ref.watch(learningProgressProvider);
  
  learningProgress.when(
    data: (progress) {
      notifier.updateDashboardData(
        childId: 'child123',
        learningProgress: progress,
        earnedBadgeIds: earnedBadges,
        currentLevel: level,
        levelProgress: levelProg,
        dailyMissionsCompleted: missionsCompleted,
        dailyMissionsTotal: missionsTotal,
      );
    },
    loading: () => {},
    error: (err, stack) => {},
  );
}
```

#### 2. ダッシュボード画面を表示

```dart
class ParentDashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(childDashboardOverviewProvider);

    return dashboardAsync.when(
      data: (dashboard) {
        if (dashboard == null) {
          return const Scaffold(
            body: Center(child: Text('No data available')),
          );
        }
        
        return Scaffold(
          appBar: AppBar(title: const Text('Parent Dashboard')),
          body: ListView(
            children: [
              ChildProgressCard(
                childProfile: dashboard.childProfile,
                totalQuizzes: dashboard.totalQuizzes,
                averageAccuracy: dashboard.overallAccuracy,
                currentStreak: dashboard.learningStreak,
              ),
              WeakAreaCard(weakAreas: dashboard.weakAreas),
              TrendChart(trends: dashboard.recentTrends),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

#### 3. 学習目標を追加

```dart
class AddGoalDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Add Learning Goal'),
      content: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Goal Title'),
            controller: titleController,
          ),
          DropdownButton<LearningCategory>(
            items: LearningCategory.values.map((cat) => 
              DropdownMenuItem(value: cat, child: Text(cat.name))
            ).toList(),
            onChanged: (value) => selectedCategory = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final notifier = ref.read(parentDashboardProvider.notifier);
            await notifier.addLearningGoal(
              'child123',
              titleController.text,
              'Goal description',
              selectedCategory!,
              85.0,
              50,
              DateTime.now().add(const Duration(days: 30)),
            );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
```

#### 4. アラートを表示・管理

```dart
class AlertsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(parentAlertsProvider);
    final unreadCount = ref.watch(unreadAlertsCountProvider);

    return alertsAsync.when(
      data: (alerts) => ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return ListTile(
            title: Text(alert.title),
            subtitle: Text(alert.message),
            trailing: !alert.isRead
                ? const Chip(label: Text('New'))
                : null,
            onTap: () async {
              final notifier = ref.read(parentDashboardProvider.notifier);
              await notifier.markAlertAsRead(alert.alertId);
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
```

#### 5. 通知設定を更新

```dart
class NotificationSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return settingsAsync.when(
      data: (settings) => Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('Daily Report'),
              value: settings?.dailyReportEnabled ?? false,
              onChanged: (value) async {
                if (settings != null) {
                  final notifier = ref.read(parentDashboardProvider.notifier);
                  await notifier.updateNotificationSettings(
                    settings.copyWith(dailyReportEnabled: value),
                  );
                }
              },
            ),
            SwitchListTile(
              title: const Text('Low Accuracy Alert'),
              value: settings?.lowAccuracyAlert ?? false,
              onChanged: (value) async {
                if (settings != null) {
                  final notifier = ref.read(parentDashboardProvider.notifier);
                  await notifier.updateNotificationSettings(
                    settings.copyWith(lowAccuracyAlert: value),
                  );
                }
              },
            ),
          ],
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

## データの流れ

1. **子どもが学習を完了**
   - 学習分析システムが統計を更新
   - 獲得XP、バッジ、レベルが更新される

2. **保護者ダッシュボードを更新**
   - 学習分析データから集計
   - 弱点エリアを特定
   - トレンドデータを生成
   - 総合インサイトを生成

3. **SharedPreferences に永続化**
   - ダッシュボードデータを保存
   - アラート履歴を保存（最新100件）
   - 学習目標を保存
   - 通知設定を保存

4. **UIが状態の変更を監視**
   - プロバイダを通じてダッシュボード情報を取得
   - 画面が自動的に更新
   - アラートが表示される

## デフォルト設定

### アラート閾値

| 条件 | アラート | 説明 |
|------|---------|------|
| 正答率 < 70% | lowAccuracy | 正答率低下アラート |
| ストリーク = 0（前日と異なる） | streakBroken | ストリーク途絶 |
| 学習時間 < 30分（1日） | learningTimeAlert | 学習時間不足 |
| 新バッジ獲得 | badgeEarned | バッジ達成通知 |
| レベルアップ | levelUp | レベルアップ通知 |

### インサイト生成ロジック

| 条件 | インサイト |
|------|----------|
| 正答率 ≥ 90% かつ ストリーク ≥ 7日 | 素晴らしい成績です！🌟 |
| 正答率 ≥ 80% | 順調に進んでいます。📈 |
| ストリーク ≥ 5日 | コンスタントに学習を継続できています。💪 |
| その他 | 学習を始めた直後です。毎日少しずつ続けることが大切です。📚 |

### データ保持期間

- **アラート**: 最新100件を保持
- **ダッシュボードデータ**: 最新1件（上書き保存）
- **学習目標**: すべての目標を保持（完了分含む）
- **通知設定**: 最新の設定1件

## テスト

### ユニットテスト

```bash
flutter test test/models/parent_dashboard_test.dart
flutter test test/providers/parent_dashboard_provider_test.dart
```

**テストのカバレッジ:**

- ChildProfile: 作成、JSON変換
- WeakArea: 作成、JSON変換
- LearningTimeTrend: 作成、JSON変換
- ParentDashboardData: 作成、計算プロパティ、JSON変換
- ParentNotificationSettings: 作成、copyWith、JSON変換
- LearningGoal: 作成、isOverdue/daysRemaining、JSON変換
- ParentAlert: 作成、JSON変換
- ParentDashboardNotifier: 初期化、データ更新、目標管理、アラート管理、設定変更、永続化

## パフォーマンス最適化

- **遅延評価**: ダッシュボードデータは必要時に計算
- **効率的なキャッシング**: FutureProvider による自動キャッシング
- **限定的な履歴保存**: アラートは最新100件のみ保持
- **インクリメンタル更新**: 子どもの学習完了時のみ親ダッシュボードを更新

## 統合例

### 子どもの学習完了フローに統合

```dart
class QuizResultScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      // 学習分析に記録
      final analyticsNotifier = ref.read(learningAnalyticsProvider.notifier);
      analyticsNotifier.recordQuizCompletion(...);
      
      // 保護者ダッシュボードを更新
      final dashboardNotifier = ref.read(parentDashboardProvider.notifier);
      dashboardNotifier.updateDashboardData(
        childId,
        updatedProgress,
        earnedBadges,
        newLevel,
        levelProgress,
        missionsCompleted,
        missionsTotal,
      );
      
      return null;
    }, []);

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const Text('Quiz Completed!'),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### ホーム画面への統合

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider); // 親か子かを判定
    
    if (role == UserRole.parent) {
      // 親用: ダッシュボード表示
      return const ParentDashboardScreen();
    } else {
      // 子用: 学習画面表示
      return const ChildLearningScreen();
    }
  }
}
```

## Future Enhancement

1. **マルチ子ども管理**
   - 複数の子どもを登録・切り替え
   - 子ども間の比較分析（プライバシー保護）
   - ファミリーダッシュボード

2. **高度な分析**
   - 推奨学習時間の自動計算
   - 学習パターン（得意な時間帯）の検出
   - 予測分析（次のレベルまでの予想日数）

3. **保護者-子ども連携**
   - 目標達成時の保護者からのメッセージ
   - 親が設定した目標への進捗確認
   - リアルタイムチャット機能

4. **学校連携**
   - 教師へのレポート出力
   - 学校での進度との連携
   - 個別指導カリキュラムの自動生成

5. **AI分析の拡張**
   - 機械学習による個人の学習最適化提案
   - 親への子育てアドバイス
   - 将来の職業適性分析（学年が進むにつれて）

6. **保護者コミュニティ**
   - 保護者同士の情報共有（匿名）
   - ベストプラクティスの共有
   - 子ども向けチャレンジイベント

## 参考資料

- [Parental Involvement in Education](https://en.wikipedia.org/wiki/Parental_involvement)
- [Learning Analytics for Parents](https://www.edutopia.org/)
- [Child Development Milestones](https://www.cdc.gov/)
- [Gamification in Education](https://www.gamedeveloper.com/)
