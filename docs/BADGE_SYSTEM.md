# バッジシステム

## 概要

バッジシステムは、ユーザーの学習進捗と成就を可視化し、継続的な学習を動機付けるためのガミフィケーション機能です。ユーザーが様々な目標を達成すると、異なる難易度のバッジをアンロックできます。

## バッジの種類

### バッジカテゴリ

1. **クイズ（Quiz）**: クイズに関連する達成
2. **進捗（Progress）**: 学習の進捗に関連する達成
3. **継続（Consistency）**: 学習の継続性に関連する達成
4. **習熟（Mastery）**: スキル習熟度に関連する達成
5. **ソーシャル（Social）**: ランキングやソーシャル機能に関連する達成
6. **スペシャル（Special）**: スペシャルなマイルストーン達成

### バッジ難易度

1. **ブロンズ（Bronze）**: 簡単 - 初心者向け
2. **シルバー（Silver）**: 普通 - 中級者向け
3. **ゴールド（Gold）**: 難しい - 上級者向け
4. **プラチナ（Platinum）**: 非常に難しい - マスター向け

## アーキテクチャ

### モデル

#### Badge (lib/models/badge.dart)

```dart
class Badge {
  final String id;                      // バッジの一意識別子
  final String name;                    // バッジ名
  final String description;             // バッジの説明
  final String emoji;                   // バッジのアイコン（絵文字）
  final BadgeCategory category;         // バッジのカテゴリ
  final BadgeDifficulty difficulty;     // バッジの難易度
  final int requiredValue;              // アンロックに必要な達成値
  final String? hint;                   // ユーザーへのヒント
  final DateTime? unlockedAt;           // アンロック日時
  
  bool get isUnlocked => unlockedAt != null;
  Badge copyWith({...});
  Map<String, dynamic> toJson();
  factory Badge.fromJson(Map<String, dynamic> json);
}

enum BadgeCategory { quiz, progress, consistency, mastery, social, special }
enum BadgeDifficulty { bronze, silver, gold, platinum }
```

#### BadgeProgress

```dart
class BadgeProgress {
  final Badge badge;
  final int currentValue;    // 現在の進捗値
  final double progress;     // 進捗率（0.0-1.0）
  
  int get remainingValue => (badge.requiredValue - currentValue).abs();
  bool get canUnlock => currentValue >= badge.requiredValue && !badge.isUnlocked;
}
```

### 状態管理

#### BadgeState (lib/providers/badge_provider.dart)

バッジシステムの状態を管理します。

```dart
class BadgeState {
  final List<Badge> badges;              // 全バッジのリスト
  final Map<String, int> badgeProgress;  // バッジIDごとの現在の進捗値
  final List<String> unlockedBadgeIds;   // アンロック済みバッジのID
  final DateTime? lastUpdatedAt;         // 最終更新日時
}
```

#### BadgeNotifier

バッジの状態を更新し、ロジックを処理します。

**主要メソッド:**

- `updateBadgeProgress(String badgeId, int newValue)` - バッジの進捗を更新
- `unlockBadge(String badgeId)` - バッジを直接アンロック（テスト用）
- `incrementQuizCorrectCount()` - クイズ正解数を増加
- `completeLesson()` - レッスン完了を記録
- `updateConsecutiveDays(int days)` - 連続学習日数を更新
- `updateStudyHours(int hours)` - 学習時間を更新
- `getBadgeProgressInfo(String badgeId)` - バッジの進捗情報を取得
- `getBadgesByCategory(BadgeCategory category)` - カテゴリ別バッジを取得
- `getUnlockedBadges()` - アンロック済みバッジを取得
- `getInProgressBadges()` - 進捗中のバッジを取得

### プロバイダ

```dart
// バッジ状態プロバイダ
final badgeProvider = StateNotifierProvider<BadgeNotifier, BadgeState>(
  (ref) => BadgeNotifier(),
);

// バッジの進捗情報を取得
final badgeProgressProvider = FutureProvider.family<BadgeProgressInfo, String>(
  (ref, badgeId) async { ... }
);

// カテゴリ別バッジを取得
final badgesByCategoryProvider = FutureProvider.family<
    List<BadgeProgressInfo>, BadgeCategory>((ref, category) async { ... });

// アンロック済みバッジを取得
final unlockedBadgesProvider = FutureProvider<List<BadgeProgressInfo>>(
  (ref) async { ... }
);

// 進捗中のバッジを取得
final inProgressBadgesProvider = FutureProvider<List<BadgeProgressInfo>>(
  (ref) async { ... }
);
```

## UI コンポーネント

### BadgeCard (lib/widgets/badge_card.dart)

単一のバッジを表示するカード。

```dart
BadgeCard(
  badgeInfo: badgeInfo,
  showProgress: true,  // 進捗バーを表示するか
  onTap: () { ... },   // タップ時のコールバック
)
```

**表示内容:**
- バッジの絵文字
- バッジ名
- 難易度バッジ
- 進捗バー（ロック中の場合のみ）
- アンロック状態

### BadgesList

複数のバッジをグリッド表示します。

```dart
BadgesList(
  badges: badgeList,
  showProgress: true,
  crossAxisCount: 2,
  padding: const EdgeInsets.all(16),
)
```

### BadgesScreen (lib/screens/badges_screen.dart)

バッジ一覧を表示するメイン画面。

**機能:**
- カテゴリ別のタブビュー
- バッジの詳細情報表示ダイアログ
- バッジ統計（取得済み / 全体）
- 進捗バーの表示

### BadgeUnlockNotification (lib/widgets/badge_unlock_notification.dart)

新しくアンロックされたバッジをアニメーション付きで通知します。

```dart
// 単一のバッジアンロックを表示
showBadgeUnlockNotification(
  context,
  badgeInfo,
  displayDuration: const Duration(seconds: 4),
);

// 複数のバッジアンロックを順序よく表示
showMultipleBadgeUnlockNotifications(
  context,
  badges,
  displayDuration: const Duration(seconds: 3),
  delayBetween: const Duration(milliseconds: 800),
);
```

## 使用方法

### 基本的な使用例

#### 1. バッジ一覧画面を表示

```dart
// アプリのナビゲーションに追加
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const BadgesScreen()),
);
```

#### 2. クイズ正解時にバッジを更新

```dart
@override
void didAnswerQuiz(bool isCorrect) async {
  final badgeNotifier = ref.read(badgeProvider.notifier);
  
  if (isCorrect) {
    await badgeNotifier.incrementQuizCorrectCount();
  }
}
```

#### 3. レッスン完了時

```dart
@override
void onLessonComplete() async {
  final badgeNotifier = ref.read(badgeProvider.notifier);
  await badgeNotifier.completeLesson();
}
```

#### 4. バッジ進捗を監視

```dart
class QuizProgressWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeState = ref.watch(badgeProvider);
    final unlockedBadges = ref.watch(unlockedBadgesProvider);

    return unlockedBadges.when(
      data: (unlocked) => Text('取得済みバッジ: ${unlocked.length}'),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }
}
```

### バッジアンロック時の通知

バッジがアンロックされたとき、自動的に通知を表示するロジックを実装します。

```dart
Future<void> updateBadgeProgress(String badgeId, int newValue) async {
  // ... 既存の更新ロジック ...
  
  // アンロック可能かチェック
  final badge = state.badges.firstWhere((b) => b.id == badgeId);
  if (newValue >= badge.requiredValue && 
      !state.unlockedBadgeIds.contains(badgeId)) {
    
    // アンロック
    await unlockBadge(badgeId);
    
    // コンテキストがある場合は通知を表示
    if (context != null && context.mounted) {
      final badgeInfo = getBadgeProgressInfo(badgeId);
      showBadgeUnlockNotification(context, badgeInfo);
    }
  }
}
```

## デフォルトバッジ

### クイズ系バッジ

| ID | 名前 | 説明 | 難易度 | 必要値 |
|-----|------|------|--------|-------|
| `quiz_starter` | クイズ始める | 初めてクイズに挑戦した | Bronze | 1 |
| `quiz_master_10` | クイズマスター Lv.1 | クイズを10問正解した | Silver | 10 |
| `quiz_master_50` | クイズマスター Lv.2 | クイズを50問正解した | Gold | 50 |
| `quiz_master_100` | クイズマスター Lv.3 | クイズを100問正解した | Platinum | 100 |

### 進捗系バッジ

| ID | 名前 | 説明 | 難易度 | 必要値 |
|-----|------|------|--------|-------|
| `lesson_complete_1` | レッスン完了 | レッスンを1つ完了した | Bronze | 1 |
| `lesson_complete_10` | レッスン達成者 | レッスンを10個完了した | Silver | 10 |

### 継続系バッジ

| ID | 名前 | 説明 | 難易度 | 必要値 |
|-----|------|------|--------|-------|
| `daily_1day` | 毎日挑戦 | 1日連続で学習した | Bronze | 1 |
| `daily_7day` | 1週間チャレンジ | 7日連続で学習した | Silver | 7 |

### 習熟系バッジ

| ID | 名前 | 説明 | 難易度 | 必要値 |
|-----|------|------|--------|-------|
| `accuracy_90` | 正確性マスター | クイズの正答率が90%以上 | Gold | 90 |

### ソーシャル系バッジ

| ID | 名前 | 説明 | 難易度 | 必要値 |
|-----|------|------|--------|-------|
| `ranking_top10` | ランキング入賞 | ランキングでトップ10に入った | Gold | 1 |

### スペシャル系バッジ

| ID | 名前 | 説明 | 難易度 | 必要値 |
|-----|------|------|--------|-------|
| `milestone_100hours` | 100時間マイルストーン | 学習時間が累計100時間に達した | Platinum | 100 |

## データ永続化

### SharedPreferences キー

| キー | 説明 | 型 |
|-----|------|-----|
| `badges` | 全バッジ（JSON文字列のリスト） | `List<String>` |
| `badge_progress` | バッジの進捗（JSON文字列のリスト） | `List<String>` |
| `unlocked_badges` | アンロック済みバッジID | `List<String>` |

### 初期化フロー

1. アプリ起動時に `BadgeNotifier` が初期化される
2. SharedPreferences から保存されたバッジを読み込む
3. 保存されたバッジが無い場合、デフォルトバッジを作成
4. 進捗とアンロック情報を復元

## テスト

### ユニットテスト

```bash
flutter test test/models/badge_test.dart
flutter test test/providers/badge_provider_test.dart
```

**テストのカバレッジ:**

- Badge モデル：JSON シリアライゼーション、equality、copyWith
- BadgeProgress：進捗計算、アンロック判定
- BadgeNotifier：状態更新、バッジアンロック、進捗追跡
- プロバイダ：初期化、カテゴリフィルタリング

## セキュリティと考慮事項

### データ整合性

- 進捗値は常に正の整数
- unlockedAt は一度設定されたら変更されない
- 進捗が必要値に達した時点で自動的にアンロック

### パフォーマンス

- バッジ情報はローカルに保存される（ネットワーク遅延なし）
- FutureProvider による効率的な状態キャッシング
- GridView のパフォーマンスは crossAxisCount で調整可能

### プライバシー

- バッジ情報はローカルデバイスのみに保存
- Firebase 同期の場合、ユーザーのみがアクセス可能

## 実装チェックリスト

- [x] Badge モデルを実装
- [x] BadgeNotifier を実装
- [x] BadgeCard UI を実装
- [x] BadgesScreen を実装
- [x] BadgeUnlockNotification を実装
- [x] ユニットテストを作成
- [ ] 設定画面にバッジセクションを統合
- [ ] ホーム画面に最近アンロックされたバッジを表示
- [ ] プッシュ通知統合（オプション）
- [ ] Firebase 連携

## 統合例

### ホーム画面への統合

```dart
// lib/screens/home_screen.dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedBadges = ref.watch(unlockedBadgesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... 他のウィジェット ...
            
            unlockedBadges.when(
              data: (badges) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最近アンロック: ${badges.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: badges.take(5).map((badge) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Text(
                                  badge.badge.emoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                Text(
                                  badge.badge.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Future Enhancement

1. **バッジシェア機能**
   - アンロックしたバッジをソーシャルメディアでシェア
   - バッジコレクションのスクリーンショット生成

2. **バッジチャレンジ**
   - 期間限定のチャレンジバッジ
   - 複数条件を満たす複合バッジ

3. **バッジコンボ**
   - 複数バッジの組み合わせで追加報酬
   - シーズナルバッジ

4. **バッジのカスタマイズ**
   - ユーザーが自分のバッジをカスタマイズ
   - バッジの並び順変更

5. **統計とトレンド**
   - バッジ取得率の統計
   - ユーザー間のバッジ比較（オプト・イン）

## 参考資料

- [Gamification](https://en.wikipedia.org/wiki/Gamification)
- [Badge (gamification)](https://en.wikipedia.org/wiki/Badge_(gamification))
- [Flutter Riverpod](https://riverpod.dev)
- [Flutter SharedPreferences](https://pub.dev/packages/shared_preferences)
