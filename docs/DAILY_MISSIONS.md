# 毎日ミッションシステム

## 概要

毎日ミッションシステムは、ユーザーに毎日異なる学習目標を提供し、継続的な学習を動機付けるためのシステムです。毎日新しいミッションが生成され、ユーザーが達成するとコインやXPなどの報酬を獲得できます。

## ミッションの種類

### ミッションタイプ

1. **クイズ（Quiz）**: クイズに関連する挑戦
2. **レッスン（Lesson）**: レッスン完了に関連する挑戦
3. **連続学習（Streak）**: 連続学習日数に関連する挑戦
4. **正答率（Accuracy）**: クイズの正答率に関連する挑戦
5. **学習時間（TimeSpent）**: 学習時間に関連する挑戦
6. **シェア（SocialShare）**: ソーシャルシェアに関連する挑戦

### ミッション難易度

1. **簡単（Easy）**: 初心者向け、達成しやすい
2. **普通（Normal）**: 標準難易度
3. **難しい（Hard）**: 挑戦的
4. **極難（Extreme）**: 非常に難しい

## アーキテクチャ

### モデル

#### DailyMission (lib/models/daily_mission.dart)

```dart
class DailyMission {
  final String id;                  // ミッションID
  final String title;               // ミッション名
  final String description;         // ミッション説明
  final String emoji;               // ミッションアイコン
  final MissionType type;           // ミッションタイプ
  final MissionDifficulty difficulty; // ミッション難易度
  final int targetValue;            // 目標値
  final int rewardCoins;            // 報酬コイン
  final int rewardXp;               // 報酬XP
  final String? rewardBadgeId;      // 報酬バッジID
  final DateTime? completedAt;      // 完了日時
  
  bool get isCompleted => completedAt != null;
}
```

#### DailyMissionProgress

```dart
class DailyMissionProgress {
  final DailyMission mission;
  final int currentValue;           // 現在の進捗値
  final double progress;            // 進捗率（0.0-100.0）
  
  int get remainingValue => ...;    // 残り値
  bool get canComplete => ...;      // 完了可能か判定
}
```

#### DailyMissionSet

```dart
class DailyMissionSet {
  final DateTime date;
  final List<DailyMission> missions;
  final int totalRewardCoins;
  final int totalRewardXp;
  
  int get completedCount => ...;    // 完了数
  double get completionRate => ...; // 完了率
  bool get isAllCompleted => ...;   // 全完了判定
  bool get isToday => ...;          // 今日のミッションか
}
```

### 状態管理

#### DailyMissionState (lib/providers/daily_mission_provider.dart)

毎日ミッションの状態を管理します。

```dart
class DailyMissionState {
  final DailyMissionSet? todayMissions;     // 本日のミッションセット
  final Map<String, int> missionProgress;   // ミッションID -> 進捗値
  final Map<String, DateTime> lastUpdated;  // ミッションID -> 最終更新
  final DateTime? lastGeneratedDate;        // ミッション生成日
}
```

#### DailyMissionNotifier

ミッションの状態を更新し、ロジックを処理します。

**主要メソッド:**

- `updateMissionProgress(String missionId, int newValue)` - ミッション進捗を更新
- `completeMission(String missionId)` - ミッションを完了
- `getMissionProgress(String missionId)` - ミッション進捗情報を取得
- `getIncompleteMissions()` - 未完了のミッション取得
- `getCompletedMissions()` - 完了したミッション取得

### プロバイダ

```dart
// ミッション状態プロバイダ
final dailyMissionProvider = StateNotifierProvider<DailyMissionNotifier, DailyMissionState>(
  (ref) => DailyMissionNotifier(),
);

// ミッション進捗情報を取得
final missionProgressProvider = FutureProvider.family<DailyMissionProgress, String>(
  (ref, missionId) async { ... }
);

// 未完了のミッションを取得
final incompleteMissionsProvider = FutureProvider<List<DailyMissionProgress>>(
  (ref) async { ... }
);

// 完了したミッションを取得
final completedMissionsProvider = FutureProvider<List<DailyMissionProgress>>(
  (ref) async { ... }
);
```

## UI コンポーネント

### DailyMissionCard (lib/widgets/daily_mission_card.dart)

単一のミッションを表示するカード。

```dart
DailyMissionCard(
  missionProgress: missionProgress,
  onComplete: () { ... },
  onTap: () { ... },
)
```

**表示内容:**
- ミッションの絵文字とタイトル
- ミッション説明
- 難易度バッジ
- 報酬（コイン、XP）
- 進捗バー
- 完了状態

### DailyMissionsList

複数のミッションをリスト表示します。

```dart
DailyMissionsList(
  missions: missionList,
  showCompleted: false,
  onMissionComplete: () { ... },
)
```

### DailyMissionsScreen (lib/screens/daily_missions_screen.dart)

毎日ミッション表示のメイン画面。

**機能:**
- 本日の進捗統計表示
- 未完了/完了ミッションの切り替え表示
- ミッション進捗の可視化
- 報酬情報の表示
- 全ミッション完了時のボーナス表示

## 使用方法

### 基本的な使用例

#### 1. ミッション画面を表示

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const DailyMissionsScreen()),
);
```

#### 2. ミッション進捗を更新（クイズ完了時など）

```dart
@override
void onQuizComplete() async {
  final notifier = ref.read(dailyMissionProvider.notifier);
  
  // クイズミッションの進捗を更新
  await notifier.updateMissionProgress('daily_quiz_5', 
    ref.read(dailyMissionProvider).missionProgress['daily_quiz_5']! + 1);
}
```

#### 3. ミッション進捗を監視

```dart
class DailyMissionsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incompleteMissions = ref.watch(incompleteMissionsProvider);

    return incompleteMissions.when(
      data: (missions) => Text('${missions.length}個のミッション残り'),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }
}
```

## デフォルトミッション

### 本日のデフォルトミッション（4個）

| ID | ミッション | タイプ | 難易度 | 目標値 | 報酬 |
|----|-----------|--------|--------|--------|------|
| `daily_quiz_5` | クイズに5回挑戦 | Quiz | 簡単 | 5 | 💰50 ⭐25 |
| `daily_correct_10` | 正解を10個獲得 | Accuracy | 普通 | 10 | 💰100 ⭐50 |
| `daily_lesson_1` | レッスンを1つ完了 | Lesson | 普通 | 1 | 💰75 ⭐40 |
| `daily_study_30min` | 30分学習 | TimeSpent | 難しい | 30 | 💰150 ⭐75 |

**本日の総報酬:** 💰375 ⭐190

## データ永続化

### SharedPreferences キー

| キー | 説明 | 型 |
|-----|------|-----|
| `daily_missions` | 本日のミッション（JSON） | `List<String>` |
| `mission_progress` | ミッション進捗（JSON） | `List<String>` |
| `last_generated_date` | ミッション生成日 | `String` |

### 初期化フロー

1. アプリ起動時、DailyMissionNotifier が初期化される
2. 保存された最後の生成日をチェック
3. 新しい日付の場合、新しいミッションセットを生成
4. SharedPreferences に保存

## テスト

### ユニットテスト

```bash
flutter test test/models/daily_mission_test.dart
flutter test test/providers/daily_mission_provider_test.dart
```

**テストのカバレッジ:**

- DailyMission モデル：JSON シリアライゼーション、equality
- DailyMissionProgress：進捗計算、完了判定
- DailyMissionNotifier：状態更新、ミッション生成、進捗追跡
- プロバイダ：初期化、フィルタリング

## セキュリティと考慮事項

### データ整合性

- 進捗値は常に非負の整数
- completedAt は一度設定されたら変更されない
- 進捗が目標値に達した時点で自動的に完了

### パフォーマンス

- ミッション情報はローカルに保存（ネットワーク遅延なし）
- FutureProvider による効率的なキャッシング
- 毎日自動的に新しいミッションに更新

### タイムゾーン処理

- 現在時刻は `DateTime.now()` を使用
- 日付変更は年月日で判定
- 複数タイムゾーンのサポート：各ユーザーのローカル時刻で日付判定

## 実装チェックリスト

- [x] DailyMission モデルを実装
- [x] DailyMissionNotifier を実装
- [x] DailyMissionCard UI を実装
- [x] DailyMissionsScreen を実装
- [x] ユニットテストを作成
- [ ] ホーム画面に最新ミッションを表示
- [ ] クイズ完了時にミッション進捗を更新
- [ ] ミッション完了時に報酬を付与
- [ ] ミッション完了通知を表示
- [ ] Firebase 連携

## 統合例

### ホーム画面への統合

```dart
// lib/screens/home_screen.dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incompleteMissions = ref.watch(incompleteMissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... 他のウィジェット ...
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: ListTile(
                  title: Text('本日のミッション'),
                  subtitle: incompleteMissions.when(
                    data: (missions) => Text('${missions.length}個'),
                    loading: () => const Text('読み込み中...'),
                    error: (_, __) => const Text('エラー'),
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DailyMissionsScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Future Enhancement

1. **ミッションのランダム化**
   - 複数のミッションプールから日々異なるミッションを選択
   - ユーザーの習熟度に基づいた難易度調整

2. **ウィークリーチャレンジ**
   - 1週間通して達成する特別なミッション
   - より大きな報酬

3. **ミッション連鎖**
   - 複数のミッションを組み合わせたボーナス報酬
   - 「3つのミッションを完了するとボーナス！」など

4. **フレンド競争**
   - フレンドとの毎日ミッション実績比較
   - リーダーボード表示

5. **カスタムミッション**
   - ユーザーが自分のミッションを作成
   - コミュニティミッション

## 参考資料

- [Gamification Design Patterns](https://en.wikipedia.org/wiki/Gamification)
- [Daily Quest Systems](https://www.gamedeveloper.com/business/the-psychology-of-daily-quests-in-games)
- [Flutter Riverpod](https://riverpod.dev)
- [Flutter SharedPreferences](https://pub.dev/packages/shared_preferences)
