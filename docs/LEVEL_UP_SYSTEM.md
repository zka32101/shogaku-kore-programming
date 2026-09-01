# レベルアップシステム

## 概要

レベルアップシステムは、ユーザーの学習進捗を視覚的に示すゲーム化要素です。ユーザーが学習を進めると経験値（XP）を獲得し、一定のXPに達するとレベルアップします。レベルが上がるとコインやXPなどの報酬が得られます。

## レベルの構成

### レベル数
- **最大レベル**: 50
- **最小レベル**: 1

### レベルの段階

1. **初心者（Beginner）**: レベル1-10
   - 基礎を学ぶステージ
   - エモジ: 🌱
   - 報酬：少額のコインとXP

2. **中級者（Intermediate）**: レベル11-25
   - スキルを向上させるステージ
   - エモジ: 🌿
   - 報酬：中程度のコインとXP

3. **上級者（Advanced）**: レベル26-40
   - 複雑な概念をマスターするステージ
   - エモジ: 🌳
   - 報酬：高額のコインとXP

4. **エキスパート（Expert）**: レベル41-50
   - プログラミングマスターのステージ
   - エモジ: 🏆
   - 報酬：最高額のコインとXP

## アーキテクチャ

### モデル

#### Level (lib/models/level.dart)

```dart
class Level {
  final int levelNumber;                // レベル番号（1-50）
  final String title;                   // レベルの名前
  final String description;             // レベルの説明
  final int requiredXp;                 // このレベルに到達するまでの累積XP
  final int rewardCoins;                // レベルアップ時の報酬コイン
  final int rewardXp;                   // ボーナスXP
  final String? rewardBadgeId;          // 報酬バッジID
  final LevelTier tier;                 // 難易度ランク
  final String emoji;                   // レベルのエモジ
}
```

#### UserLevelProgress

```dart
class UserLevelProgress {
  final Level level;                    // 現在のレベル
  final int currentXp;                  // 現在のレベル内での経験値
  final int totalXpEarned;              // 累積経験値
  final double progress;                // 次のレベルまでの進捗率（0.0-100.0）
  final DateTime? levelUpAt;            // レベルアップ日時
  
  int get remainingXp;                  // 次のレベルまでの必要XP
  bool get canLevelUp;                  // レベルアップ可能か判定
}
```

#### LevelUpEvent

```dart
class LevelUpEvent {
  final int oldLevel;                   // 前のレベル
  final int newLevel;                   // 新しいレベル
  final Level levelData;                // レベル情報
  final DateTime timestamp;             // レベルアップ日時
  final int coinsReward;                // コイン報酬
  final int xpBonus;                    // XPボーナス
}
```

### 状態管理

#### LevelState (lib/providers/level_provider.dart)

```dart
class LevelState {
  final int currentLevel;                // 現在のレベル（1-50）
  final int totalXpEarned;               // 累積経験値
  final DateTime? lastLevelUpDate;       // 最後にレベルアップした日時
  final List<int> milestoneReached;      // 達成したマイルストーン（10, 25, 40, 50）
  final LevelUpEvent? lastLevelUpEvent;  // 最後のレベルアップイベント
}
```

#### LevelNotifier

ユーザーのレベル進捗を管理します。

**主要メソッド:**

- `addExperience(int xpAmount)` - 経験値を追加し、レベルアップを検出
- `getLevelProgress()` - 現在のレベル進捗情報を取得
- `getXpToNextLevel()` - 次のレベルまでの必要XPを取得
- `getMilestoneStatus()` - マイルストーン達成状況を取得
- `canLevelUp()` - レベルアップ可能か判定
- `getStats()` - レベル統計情報を取得

### プロバイダ

```dart
// レベル状態プロバイダ
final levelProvider = StateNotifierProvider<LevelNotifier, LevelState>(
  (ref) => LevelNotifier(),
);

// レベル進捗情報プロバイダ
final levelProgressProvider = FutureProvider<UserLevelProgress>((ref) async { ... });

// 次のレベルまでのXPプロバイダ
final xpToNextLevelProvider = FutureProvider<int>((ref) async { ... });

// マイルストーン状態プロバイダ
final milestonesProvider = FutureProvider<Map<int, bool>>((ref) async { ... });

// レベル統計情報プロバイダ
final levelStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async { ... });
```

## UIコンポーネント

### LevelProgressWidget (lib/widgets/level_progress_widget.dart)

レベル進捗を表示するウィジェット。

```dart
LevelProgressWidget(
  progress: levelProgress,
  onTap: () { ... },
)
```

**表示内容:**
- レベル番号とタイトル
- エモジアイコン
- レベル内での経験値進捗バー
- 説明テキスト

### LevelBadgeWidget

小型のレベルバッジ（円形）。

```dart
LevelBadgeWidget(
  levelNumber: 10,
  size: 48,
)
```

### LevelHeaderWidget

ヘッダーに表示する小型レベル情報。

```dart
LevelHeaderWidget(
  currentLevel: currentLevel,
  totalXp: totalXp,
  onTap: () { ... },
)
```

### LevelUpNotification (lib/widgets/level_up_notification.dart)

レベルアップ時のアニメーション付き通知。スケールとスライドのアニメーションで表示され、3秒後に自動で閉じます。

```dart
LevelUpNotification(
  levelUpEvent: levelUpEvent,
  onDismiss: () { ... },
)
```

### LevelUpBanner

バナー形式のレベルアップ通知（スナックバー等で使用）。

### LevelsScreen (lib/screens/levels_screen.dart)

レベル進捗の総合表示画面。

**機能:**
- 現在のレベル情報表示
- マイルストーン達成状況表示
- すべての50レベルをグリッド表示
- レベルタップで詳細情報を表示
- ロック/達成状況を視覚的に表示

## 使用方法

### 基本的な使用例

#### 1. レベル画面を表示

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LevelsScreen()),
);
```

#### 2. 経験値を追加（クイズ完了時など）

```dart
@override
void onQuizComplete(int xpGained) async {
  final notifier = ref.read(levelProvider.notifier);
  
  // 経験値を追加
  final levelUpEvents = await notifier.addExperience(xpGained);
  
  // レベルアップ時は通知を表示
  if (levelUpEvents.isNotEmpty) {
    showDialog(
      context: context,
      builder: (context) => LevelUpNotification(
        levelUpEvent: levelUpEvents.first,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}
```

#### 3. レベル進捗を監視

```dart
class LevelProgressWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(levelProgressProvider);

    return progressAsync.when(
      data: (progress) => Text(
        'Level ${progress.level.levelNumber}: ${progress.currentXp}/${progress.remainingXp + progress.currentXp} XP',
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }
}
```

#### 4. ヘッダーにレベル情報を表示

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final levelState = ref.watch(levelProvider);

  return AppBar(
    title: const Text('ホーム'),
    actions: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: LevelHeaderWidget(
          currentLevel: levelState.currentLevel,
          totalXp: levelState.totalXpEarned,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LevelsScreen()),
          ),
        ),
      ),
    ],
  );
}
```

## デフォルトレベル設定

### 経験値要件

レベルの経験値要件は指数関数的に成長します：

- **レベル1**: 100 XP
- **レベル2**: 115 XP (1.15倍)
- **レベル3**: 132 XP (1.15倍)
- ...
- **レベル50**: 約50,000 XP

### 報酬

各レベルアップ時に獲得：

| レベル | コイン | XP | 報酬バッジ |
|--------|--------|-----|----------|
| 1-10 | 50-150 | 25-75 | - |
| 10 | 200 | 100 | beginner_master |
| 11-25 | 100-375 | 50-150 | - |
| 25 | 475 | 200 | intermediate_master |
| 26-40 | 200-700 | 100-300 | - |
| 40 | 950 | 400 | advanced_master |
| 41-50 | 500-1,000 | 250-500 | - |
| 50 | 1,500 | 750 | ultimate_master |

## データ永続化

### SharedPreferences キー

| キー | 説明 | 型 |
|-----|------|-----|
| `user_level` | 現在のレベル | `int` |
| `user_total_xp` | 累積経験値 | `int` |
| `last_level_up_date` | 最後にレベルアップした日時 | `String` (ISO8601) |
| `milestones_reached` | 達成したマイルストーン | `List<String>` |

### 初期化フロー

1. アプリ起動時、LevelNotifier が初期化される
2. SharedPreferencesからレベル情報を復元
3. ない場合はレベル1、0 XPで初期化
4. SharedPreferencesに保存

## テスト

### ユニットテスト

```bash
flutter test test/models/level_test.dart
flutter test test/providers/level_provider_test.dart
```

**テストのカバレッジ:**

- Level モデル：作成、JSON シリアライゼーション、同値判定
- UserLevelProgress：進捗計算、完了判定
- LevelUpEvent：イベント作成と情報保持
- DefaultLevels：50レベルの生成、難易度増加確認
- LevelNotifier：状態管理、経験値追加、レベルアップ検出、マイルストーン追跡
- プロバイダ：初期化、レベル進捗取得

## マイルストーン

レベル10, 25, 40, 50到達時に特別なバッジが報酬として付与されます：

- **Beginner Master** (Lv10): 初心者マスター
- **Intermediate Master** (Lv25): 中級者マスター
- **Advanced Master** (Lv40): 上級者マスター
- **Ultimate Master** (Lv50): 究極のマスター

## パフォーマンス

- レベル情報はローカルに保存（ネットワーク遅延なし）
- 50レベルは静的に定義（計算不要）
- FutureProvider による効率的なキャッシング
- レベルアップ検出は常にO(n)（最大50）

## 統合例

### ホーム画面への統合

```dart
// lib/screens/home_screen.dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelState = ref.watch(levelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: LevelHeaderWidget(
              currentLevel: levelState.currentLevel,
              totalXp: levelState.totalXpEarned,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LevelsScreen()),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... 他のウィジェット ...
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: ref.watch(levelProgressProvider).when(
                data: (progress) => LevelProgressWidget(progress: progress),
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('エラー: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### クイズ完了時の統合

```dart
@override
void onQuizComplete(int xpGained) async {
  final levelNotifier = ref.read(levelProvider.notifier);
  
  // 経験値を追加してレベルアップを検出
  final levelUpEvents = await levelNotifier.addExperience(xpGained);
  
  // レベルアップがあれば通知を表示
  if (levelUpEvents.isNotEmpty) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpNotification(
        levelUpEvent: levelUpEvents.last,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}
```

## Future Enhancement

1. **レベルアップアニメーション**
   - ボス戦のようなレベルアップ演出
   - パーティクルエフェクト

2. **レベルボーナス**
   - 連続レベルアップボーナス
   - マイルストーン達成ボーナス

3. **レベル報酬の多様化**
   - 特殊アイテムのアンロック
   - キャラクター解放
   - スキンアンロック

4. **レベルシステムの拡張**
   - カテゴリ別レベル（プログラミング、数学など）
   - チャレンジレベル

5. **ソーシャル機能**
   - フレンドとのレベル比較
   - グローバルランキング

## 参考資料

- [Gamification Design Patterns](https://en.wikipedia.org/wiki/Gamification)
- [Experience and Leveling Systems in Games](https://www.gamedeveloper.com/)
- [Flutter Riverpod](https://riverpod.dev)
- [Flutter SharedPreferences](https://pub.dev/packages/shared_preferences)
