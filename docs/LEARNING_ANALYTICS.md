# 学習分析システム

## 概要

学習分析システムは、ユーザーの学習パターンと進捗を詳細に追跡・分析するゲーム化要素です。日単位、週単位、月単位での学習統計を自動的に記録し、視覚化します。学習者は自分の学習パターンを理解し、継続的な改善を目指せます。

## 主な機能

✅ **日単位の統計記録**: クイズ数、正答数、学習時間、正答率を自動記録  
✅ **カテゴリ別追跡**: プログラミング、数学、アルゴリズムなど5つのカテゴリで分類  
✅ **ストリーク追跡**: 連続学習日数と最長記録を自動計算  
✅ **週間・月間集計**: 複数期間での分析と傾向把握  
✅ **AI生成インサイト**: 学習パフォーマンスに基づいた自動的なアドバイス  
✅ **レポート生成**: 日/週/月単位での詳細レポート  
✅ **ローカル永続化**: 最新100日間のデータをSharedPreferencesに保存

## アーキテクチャ

### モデル

#### DailyLearningStats (日単位の統計)

```dart
class DailyLearningStats {
  final DateTime date;                    // 日付
  final int quizzesCompleted;             // 完了したクイズ数
  final int quizzesCorrect;               // 正解したクイズ数
  final int lessonsCompleted;             // 完了したレッスン数
  final Duration timeSpent;               // 学習時間
  final double accuracyPercentage;        // 正答率（0.0-100.0）
  final int xpGained;                     // 獲得XP
  final int coinsGained;                  // 獲得コイン
  final Map<LearningCategory, int> categoryStats; // カテゴリ別問題数
}
```

#### WeeklyLearningStats (週単位の統計)

```dart
class WeeklyLearningStats {
  final DateTime startDate;               // 週の開始日（月曜日）
  final List<DailyLearningStats> dailyStats; // 7日間のデータ
  
  // 計算プロパティ
  int get totalQuizzesCompleted;          // 週間の総問題数
  double get averageAccuracy;             // 週間の平均正答率
  Duration get totalTimeSpent;            // 週間の総学習時間
  int get daysLearned;                    // 学習した日数
  int get consecutiveDays;                // 連続学習日数
}
```

#### MonthlyLearningStats (月単位の統計)

```dart
class MonthlyLearningStats {
  final int year;
  final int month;
  final List<WeeklyLearningStats> weeklyStats;
  
  // 計算プロパティ
  int get totalQuizzesCompleted;          // 月間の総問題数
  double get averageAccuracy;             // 月間の平均正答率
  double get totalHoursSpent;             // 月間の総学習時間（時間単位）
  int get daysLearned;                    // 学習した日数
}
```

#### OverallLearningProgress (総合進捗)

```dart
class OverallLearningProgress {
  final int totalQuizzesCompleted;        // 累計クイズ数
  final int totalQuizzesCorrect;          // 累計正解数
  final Duration totalTimeSpent;          // 累計学習時間
  final double overallAccuracy;           // 全体的な正答率
  final int longestStreak;                // 最長連続学習日数
  final int currentStreak;                // 現在の連続学習日数
  final DateTime? lastStudyDate;          // 最後に学習した日
  final int totalDaysLearned;             // 学習した延べ日数
  final Map<LearningCategory, int> categoryStats; // カテゴリ別統計
}
```

#### LearningReport (学習レポート)

```dart
class LearningReport {
  final DateTime generatedAt;
  final AnalyticsTimeUnit timeUnit;       // 日/週/月/年
  final OverallLearningProgress progress;
  final List<DailyLearningStats>? dailyData;
  final WeeklyLearningStats? weeklyData;
  final MonthlyLearningStats? monthlyData;
  final String? insights;                 // AI生成のインサイト
}
```

### Enum定義

#### AnalyticsTimeUnit (分析時間単位)

```dart
enum AnalyticsTimeUnit {
  daily,      // 日単位
  weekly,     // 週単位
  monthly,    // 月単位
  yearly,     // 年単位
}
```

#### LearningCategory (学習カテゴリ)

```dart
enum LearningCategory {
  programming,   // プログラミング
  mathematics,   // 数学
  algorithms,    // アルゴリズム
  dataStructure, // データ構造
  other,         // その他
}
```

### 状態管理

#### LearningAnalyticsState

```dart
class LearningAnalyticsState {
  final List<DailyLearningStats> dailyStats; // 日単位の履歴
  final OverallLearningProgress progress;    // 総合進捗
  final DateTime? lastUpdatedAt;             // 最終更新時刻
  final int currentStreak;                   // 現在のストリーク
  final int longestStreak;                   // 最長ストリーク
}
```

#### LearningAnalyticsNotifier

ユーザーの学習分析データを管理します。

**主要メソッド:**

- `recordQuizCompletion()` - クイズ完了時に統計を更新
- `generateReport()` - 指定期間のレポートを生成
- `getStatsForDateRange()` - 指定日付範囲の統計を取得
- `getWeeklyStats()` - 週単位の統計を計算
- `getMonthlyStats()` - 月単位の統計を計算

### プロバイダ

```dart
// 学習分析状態プロバイダ
final learningAnalyticsProvider = 
  StateNotifierProvider<LearningAnalyticsNotifier, LearningAnalyticsState>(
    (ref) => LearningAnalyticsNotifier(),
  );

// 総合進捗プロバイダ
final learningProgressProvider = 
  FutureProvider<OverallLearningProgress>((ref) async { ... });

// 日単位レポートプロバイダ
final dailyReportProvider = 
  FutureProvider<LearningReport>((ref) async { ... });

// 週単位レポートプロバイダ
final weeklyReportProvider = 
  FutureProvider.family<LearningReport, DateTime>((ref, date) async { ... });

// 月単位レポートプロバイダ
final monthlyReportProvider = 
  FutureProvider.family<LearningReport, (int, int)>((ref, date) async { ... });
```

## UIコンポーネント

### LearningAnalyticsScreen

メインの学習分析表示画面

**表示内容:**
- 総合統計サマリー（累計クイズ数、平均正答率、ストリーク）
- 日/週/月タブで期間を切り替え
- グラフ表示（正答率の推移、学習時間の推移）
- カテゴリ別統計の円グラフ
- インサイト表示
- 詳細データテーブル

### StatisticsCard

統計情報を表示するカード

```dart
StatisticsCard(
  title: 'クイズ正答率',
  value: '85.5%',
  icon: Icons.trending_up,
  color: Colors.blue,
)
```

### StreakIndicator

ストリーク情報を表示

```dart
StreakIndicator(
  currentStreak: 7,
  longestStreak: 15,
  emoji: '🔥',
)
```

### CategoryChart

カテゴリ別の円グラフ表示

```dart
CategoryChart(
  categoryStats: {
    LearningCategory.programming: 50,
    LearningCategory.mathematics: 30,
    LearningCategory.algorithms: 20,
  },
)
```

### AccuracyChart

正答率の折れ線グラフ

```dart
AccuracyChart(
  dailyStats: dailyStats,
  timeUnit: AnalyticsTimeUnit.weekly,
)
```

## 使用方法

### 基本的な使用例

#### 1. クイズ完了時に統計を記録

```dart
@override
void onQuizComplete(int correctCount, int totalCount, Duration timeSpent) {
  final notifier = ref.read(learningAnalyticsProvider.notifier);
  
  notifier.recordQuizCompletion(
    correctCount: correctCount,
    totalCount: totalCount,
    timeSpent: timeSpent,
    category: LearningCategory.programming,
    xpGained: 50,
    coinsGained: 25,
  );
}
```

#### 2. 分析画面を表示

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LearningAnalyticsScreen()),
);
```

#### 3. レポートを取得して表示

```dart
class AnalyticsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportProvider(DateTime.now()));

    return reportAsync.when(
      data: (report) => Column(
        children: [
          Text('週間正答率: ${report.progress.overallAccuracy.toStringAsFixed(1)}%'),
          if (report.insights != null) Text('インサイト: ${report.insights}'),
        ],
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }
}
```

#### 4. ストリーク情報を表示

```dart
class HomeWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningAnalyticsProvider);

    return StreakIndicator(
      currentStreak: state.currentStreak,
      longestStreak: state.longestStreak,
      emoji: '🔥',
    );
  }
}
```

## データの流れ

1. **ユーザーがクイズを完了**
   - クイズスクリーンから `recordQuizCompletion()` を呼び出し
   - 正解数、時間、カテゴリが渡される

2. **LearningAnalyticsNotifier が統計を更新**
   - 今日のDailyLearningStatsを更新または作成
   - カテゴリ別統計を集計
   - ストリークを再計算
   - 総合進捗を更新

3. **SharedPreferences に永続化**
   - 日単位の統計を保存（最新100日）
   - ストリーク情報を保存
   - 最終更新時刻を記録

4. **UIが状態の変更を監視**
   - プロバイダを通じて最新の統計を取得
   - 画面が自動的に更新

## デフォルト設定

### ストリーク計算

- **現在のストリーク**: 今日から遡って、連続して学習した日数
- **最長ストリーク**: これまでの最高記録
- **リセット条件**: 1日学習しない（自動リセット）

### インサイト生成ロジック

| 条件 | インサイト |
|------|----------|
| 正答率 ≥ 90% かつ ストリーク ≥ 7日 | 素晴らしい成績です！🌟 |
| 正答率 ≥ 75% | 順調に進んでいます。📈 |
| ストリーク ≥ 7日 | 学習習慣が定着しています。💪 |
| 学習時間 ≥ 10時間 | 多くの学習時間を投資されています。⏱️ |

### データ保持期間

- **ローカル保存**: 最新100日間のDailyLearningStats
- **総合統計**: すべての期間の累計データを保持
- **キャッシュ**: FutureProviderで自動キャッシング

## テスト

### ユニットテスト

```bash
flutter test test/models/learning_analytics_test.dart
flutter test test/providers/learning_analytics_provider_test.dart
```

**テストのカバレッジ:**

- DailyLearningStats: 作成、日付判定、JSON変換
- WeeklyLearningStats: 集計計算、ストリーク計算
- MonthlyLearningStats: 月間集計、平均計算
- OverallLearningProgress: 累計計算、JSON変換
- LearningReport: レポート生成、インサイト
- LearningAnalyticsNotifier: 初期化、データ記録、レポート生成、永続化

## パフォーマンス最適化

- **遅延評価**: WeeklyLearningStats と MonthlyLearningStats は必要時に計算
- **効率的なキャッシング**: FutureProvider による自動キャッシング
- **限定的な履歴保存**: 最新100日のみメモリに保持
- **バッチ計算**: 複数のクイズを続けて実施しても単一の更新操作

## 統合例

### ホーム画面への統合

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningAnalyticsProvider);
    final report = ref.watch(dailyReportProvider);

    return Scaffold(
      body: Column(
        children: [
          StreakIndicator(
            currentStreak: state.currentStreak,
            longestStreak: state.longestStreak,
          ),
          report.when(
            data: (r) => Column(
              children: [
                Text('本日の正答率: ${r.progress.overallAccuracy.toStringAsFixed(1)}%'),
                if (r.insights != null) Text('💡 ${r.insights}'),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
```

### クイズ完了フロー への統合

```dart
class QuizResultScreen extends ConsumerWidget {
  final int correctCount;
  final int totalCount;
  final Duration timeSpent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(learningAnalyticsProvider.notifier);

    useEffect(() {
      notifier.recordQuizCompletion(
        correctCount: correctCount,
        totalCount: totalCount,
        timeSpent: timeSpent,
        category: LearningCategory.programming,
        xpGained: calculateXp(correctCount, totalCount),
        coinsGained: calculateCoins(correctCount, totalCount),
      );
      return null;
    }, []);

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text('正答率: ${(correctCount / totalCount * 100).toStringAsFixed(1)}%'),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('続ける'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Future Enhancement

1. **高度な分析**
   - 学習パターン認識（得意な時間帯の検出）
   - 予測分析（次のレベルまでの予想日数）
   - 弱点分析（カテゴリ別の詳細分析）

2. **ソーシャル機能**
   - 友人との統計比較
   - グローバルランキング
   - チャレンジイベント

3. **ゲーミフィケーション**
   - マイルストーン達成時のアニメーション
   - レアな統計達成時の特別報酬
   - ストリーク継続ボーナス

4. **エクスポート機能**
   - レポートのPDF出力
   - 保護者への報告書生成
   - データバックアップ

5. **AI分析の拡張**
   - 機械学習による個人用インサイト
   - 学習時間最適化の提案
   - 専門分野の自動検出

## 参考資料

- [Learning Analytics in Education](https://en.wikipedia.org/wiki/Learning_analytics)
- [Gamification Metrics](https://www.gamedeveloper.com/)
- [Flutter Charts Libraries](https://pub.dev/packages/fl_chart)
- [Riverpod State Management](https://riverpod.dev)
