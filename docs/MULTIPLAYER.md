# マルチプレイヤーシステム

## 概要

マルチプレイヤーシステムは、子どもたちが他のプレイヤーと競い合ったり協力して学習するゲーム化要素です。友人管理、リアルタイムマッチング、ランキング、ライブ通知などを統合し、社会的な学習体験を実現します。協力と競争のバランスを取りながら、学習動機付けを高めます。

## 主な機能

✅ **マルチプレイヤーゲームモード**: 1対1対戦、チーム対戦、フリーフォーオール、協力プレイ  
✅ **フレンド管理**: フレンド追加、リクエスト、ブロック機能  
✅ **ライブマッチング**: リアルタイムマッチ作成、参加、進行状況同期  
✅ **スコアシステム**: 正答数、正答率、時間に基づく動的スコアリング  
✅ **リーダーボード**: グローバルランキングとフレンド間ランキング  
✅ **プロファイルシステム**: ユーザープロフィール、勝率、ストリーク、レベル  
✅ **ライブ通知**: マッチ招待、フレンドリクエスト、マッチ結果、ランキング変動  
✅ **マッチ履歴**: 過去のマッチ詳細とパフォーマンス分析

## アーキテクチャ

### モデル

#### MultiplayerUserProfile (マルチプレイヤーユーザープロファイル)

```dart
class MultiplayerUserProfile {
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final int level;
  final int totalXp;
  final double averageAccuracy;
  final int matchesWon;
  final int matchesPlayed;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final bool isOnline;
  final bool isBlocked;
}
```

**計算プロパティ:**
- `winRate` - 勝率（0.0-100.0）

#### Friend (フレンド関係)

```dart
class Friend {
  final String friendId;
  final String userId;
  final String friendUserId;
  final MultiplayerUserProfile friendProfile;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
}
```

**計算プロパティ:**
- `isConfirmed` - フレンドシップが確認済みか
- `isPending` - フレンドリクエストがペンディング中か

#### MatchResult (マッチ結果)

```dart
class MatchResult {
  final String matchId;
  final String playerId;
  final int score;
  final double accuracy;
  final int correctAnswers;
  final int totalQuestions;
  final int timeSpentSeconds;
  final int xpEarned;
  final int coinsEarned;
  final int ranking;
  final bool isWinner;
  final DateTime completedAt;
}
```

#### MultiplayerMatch (マルチプレイヤーマッチ)

```dart
class MultiplayerMatch {
  final String matchId;
  final String hostUserId;
  final List<String> playerUserIds;
  final MultiplayerGameMode gameMode;
  final MatchStatus status;
  final LearningCategory category;
  final int totalQuestions;
  final int questionIndex;
  final Map<String, int> playerScores;
  final Map<String, MatchResult>? results;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int timeoutSeconds;
}
```

**計算プロパティ:**
- `isActive` - マッチが進行中か
- `isCompleted` - マッチが完了したか
- `progressPercentage` - 進捗率（0.0-100.0）

#### LeaderboardEntry (リーダーボードエントリ)

```dart
class LeaderboardEntry {
  final int rank;
  final MultiplayerUserProfile userProfile;
  final int score;
  final double accuracy;
  final int matchesWon;
  final double winRate;
  final int currentStreak;
}
```

#### LiveNotification (ライブ通知)

```dart
class LiveNotification {
  final String notificationId;
  final String userId;
  final LiveNotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
}
```

### Enum定義

#### MultiplayerGameMode (マルチプレイヤーゲームモード)

```dart
enum MultiplayerGameMode {
  headToHead,     // 1対1対戦
  teamBattle,     // チーム対戦
  royalBattle,    // フリーフォーオール
  cooperative,    // 協力プレイ
  challengeMode,  // チャレンジモード
}
```

#### MatchStatus (マッチステータス)

```dart
enum MatchStatus {
  waitingForPlayers, // プレイヤー待機中
  inProgress,        // 進行中
  completed,         // 完了
  cancelled,         // キャンセル
  paused,            // 一時停止
}
```

#### FriendshipStatus (フレンドシップステータス)

```dart
enum FriendshipStatus {
  pending,   // ペンディング
  confirmed, // 確認済み
  blocked,   // ブロック
}
```

#### LiveNotificationType (ライブ通知タイプ)

```dart
enum LiveNotificationType {
  friendRequest,     // フレンドリクエスト
  friendAccepted,    // フレンド承認
  matchInvitation,   // マッチ招待
  matchStarting,     // マッチ開始
  opponentAction,    // 相手のアクション
  matchCompleted,    // マッチ完了
  friendOnline,      // フレンドがオンライン
  achievement,       // アチーブメント
  leaderboardChange, // ランキング変動
}
```

### 状態管理

#### MultiplayerState

```dart
class MultiplayerState {
  final MultiplayerUserProfile? currentUserProfile;
  final List<Friend> friendsList;
  final List<Friend> friendRequests;
  final MultiplayerMatch? activeMatch;
  final List<MultiplayerMatch> matchHistory;
  final List<LiveNotification> notifications;
  final List<LeaderboardEntry> globalLeaderboard;
  final List<LeaderboardEntry> friendsLeaderboard;
  final DateTime? lastUpdatedAt;
  final bool isLoading;
  final bool isSearching;
}
```

#### MultiplayerNotifier

ユーザープロファイル、マッチ、フレンド、通知を管理します。

**主要メソッド:**

- `initializeUserProfile()` - ユーザープロファイルを初期化
- `updateUserProfile()` - プロフィール情報を更新
- `sendFriendRequest()` - フレンドリクエストを送信
- `acceptFriendRequest()` - フレンドリクエストを承認
- `blockFriend()` - ユーザーをブロック
- `createMatch()` - 新しいマッチを作成
- `joinMatch()` - 既存のマッチに参加
- `startMatch()` - マッチを開始
- `updateScore()` - スコアを更新
- `completeMatch()` - マッチを完了
- `addNotification()` - ライブ通知を追加
- `markNotificationAsRead()` - 通知を既読にマーク
- `searchUsers()` - ユーザーを検索
- `generateGlobalLeaderboard()` - グローバルリーダーボードを生成
- `generateFriendsLeaderboard()` - フレンドリーダーボードを生成

### プロバイダ

```dart
// マルチプレイヤー状態プロバイダ
final multiplayerProvider =
  StateNotifierProvider<MultiplayerNotifier, MultiplayerState>(
    (ref) => MultiplayerNotifier(),
  );

// 現在のユーザープロファイルプロバイダ
final currentUserProfileProvider = 
  FutureProvider<MultiplayerUserProfile?>((ref) async { ... });

// フレンドリストプロバイダ
final friendsListProvider = 
  FutureProvider<List<Friend>>((ref) async { ... });

// フレンドリクエストプロバイダ
final friendRequestsProvider = 
  FutureProvider<List<Friend>>((ref) async { ... });

// アクティブマッチプロバイダ
final activeMatchProvider = 
  FutureProvider<MultiplayerMatch?>((ref) async { ... });

// マッチ履歴プロバイダ
final matchHistoryProvider = 
  FutureProvider<List<MultiplayerMatch>>((ref) async { ... });

// ライブ通知プロバイダ
final liveNotificationsProvider = 
  FutureProvider<List<LiveNotification>>((ref) async { ... });

// 未読通知数プロバイダ
final unreadNotificationsCountProvider = 
  FutureProvider<int>((ref) async { ... });

// グローバルリーダーボードプロバイダ
final globalLeaderboardProvider = 
  FutureProvider<List<LeaderboardEntry>>((ref) async { ... });

// フレンドリーダーボードプロバイダ
final friendsLeaderboardProvider = 
  FutureProvider<List<LeaderboardEntry>>((ref) async { ... });
```

## UIコンポーネント

### MultiplayerLobbyScreen

マルチプレイヤーロビー画面

**表示内容:**
- ユーザープロフィール（名前、レベル、プロフィール画像）
- フレンドリスト（オンライン状態、最後のアクティビティ）
- マッチ作成ボタン（ゲームモード選択）
- 利用可能なマッチのリスト
- グローバルランキングプレビュー
- ライブ通知ベル（未読数バッジ）

### MatchmakingScreen

マッチメイキング画面

**表示内容:**
- ゲームモード選択（1対1、チーム、フリーフォーオール）
- 学習カテゴリ選択
- 難易度レベル選択
- マッチングの進捗表示
- 推定待機時間
- キャンセルボタン

### LiveMatchScreen

ライブマッチ画面

**表示内容:**
- プレイヤー情報（名前、プロフィール画像、現在のスコア）
- 問題と回答選択肢
- タイマー（問題ごと、マッチ全体）
- リアルタイムスコア更新
- 他プレイヤーのアクション通知
- ポーズ/リタイア機能

### MatchResultScreen

マッチ結果画面

**表示内容:**
- 最終順位と順位変動
- スコア詳細（正解数、正答率、時間）
- 獲得XPとコイン
- 勝利エモーション/アニメーション
- マッチ統計（比較）
- 次のマッチへのボタン

### LeaderboardScreen

リーダーボード画面

**表示内容:**
- ランキング表示（順位、プレイヤー名、レベル、スコア、勝率）
- タブ（グローバル / フレンド / カテゴリ別）
- 自分のランキング強調表示
- プレイヤープロフィール表示（タップで詳細）
- フレンド追加ボタン

### FriendsScreen

フレンド管理画面

**表示内容:**
- フレンドリスト（オンライン状態、最後のアクティビティ）
- ペンディングフレンドリクエスト
- ユーザー検索機能
- フレンドプロフィール表示
- マッチ招待ボタン
- ブロック/削除機能

### NotificationsPanel

通知パネル

**表示内容:**
- リアルタイム通知リスト
- 通知タイプ別フィルタリング
- 既読/未読状態表示
- タップで関連スクリーンへ移動
- 既読にマークボタン

## 使用方法

### 基本的な使用例

#### 1. ユーザープロファイルを初期化

```dart
class MultiplayerSetupScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final notifier = ref.read(multiplayerProvider.notifier);
      notifier.initializeUserProfile('currentUserId');
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('Multiplayer Setup')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MultiplayerLobbyScreen()),
          ),
          child: const Text('Enter Multiplayer'),
        ),
      ),
    );
  }
}
```

#### 2. マッチを作成して参加

```dart
class CreateMatchDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Create Match'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<MultiplayerGameMode>(
            items: MultiplayerGameMode.values.map((mode) =>
              DropdownMenuItem(value: mode, child: Text(mode.name))
            ).toList(),
            onChanged: (mode) => selectedMode = mode,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final notifier = ref.read(multiplayerProvider.notifier);
            await notifier.createMatch(
              selectedMode!,
              LearningCategory.programming,
              20,
            );
            Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
```

#### 3. フレンドを追加

```dart
class UserSearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Users')),
      body: Column(
        children: [
          SearchBar(
            onSubmitted: (query) async {
              final notifier = ref.read(multiplayerProvider.notifier);
              final results = await notifier.searchUsers(query);
              showResults(results);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                return ListTile(
                  title: Text(user.displayName),
                  subtitle: Text('Level ${user.level}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final notifier = ref.read(multiplayerProvider.notifier);
                      await notifier.sendFriendRequest(user);
                    },
                    child: const Text('Add Friend'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 4. ライブマッチを進行

```dart
class LiveMatchWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(activeMatchProvider);

    return matchAsync.when(
      data: (match) {
        if (match == null) return const SizedBox.shrink();
        
        return Column(
          children: [
            Text('Question ${match.questionIndex} of ${match.totalQuestions}'),
            LinearProgressIndicator(
              value: match.progressPercentage / 100,
            ),
            // Display current players and scores
            for (final playerId in match.playerUserIds)
              Text('Score: ${match.playerScores[playerId]}'),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

#### 5. ライブ通知を表示

```dart
class NotificationPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(liveNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return notificationsAsync.when(
      data: (notifications) => Column(
        children: [
          Badge(
            label: Text(unreadCount.toString()),
            child: const Icon(Icons.notifications),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  title: Text(notif.title),
                  subtitle: Text(notif.message),
                  trailing: notif.isRead
                      ? null
                      : const Chip(label: Text('New')),
                  onTap: () async {
                    final notifier = ref.read(multiplayerProvider.notifier);
                    await notifier.markNotificationAsRead(notif.notificationId);
                  },
                );
              },
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
```

## データの流れ

1. **ユーザーがマッチを作成**
   - MultiplayerLobbyScreenからゲームモードを選択
   - createMatch()でマッチを初期化
   - ホストとして他のプレイヤーを待機

2. **他のプレイヤーが参加**
   - 利用可能なマッチリストから選択
   - joinMatch()で参加
   - プレイヤーリストに追加

3. **マッチが開始**
   - ホストがスタートボタンをクリック
   - ステータスがinProgressに変更
   - タイマーと最初の問題が表示される

4. **ゲーム進行中**
   - updateScore()でスコアを更新
   - questionIndexが進む
   - リアルタイムでスコア同期

5. **マッチが完了**
   - completeMatch()で結果を確定
   - プロファイルが更新（XP、勝率、ストリーク）
   - リーダーボード順位が更新
   - 通知が送信される

## デフォルト設定

### スコアリング

| 要因 | ボーナス |
|------|--------|
| 正解 | 基本点数 |
| 時間ボーナス | 短いほど多い |
| 連続正解 | 乗算ボーナス |
| 難易度 | 倍数適用 |

### 通知スケジュール

| イベント | 通知タイプ |
|---------|----------|
| フレンドリクエスト受信 | friendRequest |
| マッチ招待 | matchInvitation |
| マッチ開始 | matchStarting |
| マッチ完了 | matchCompleted |
| ランキング変動 | leaderboardChange |

### データ保持期間

- **マッチ履歴**: 最新100件
- **ライブ通知**: 最新100件
- **フレンドシップ**: 無制限（ブロック/削除まで）
- **プロファイル**: 永続（ユーザー削除まで）

## テスト

### ユニットテスト

```bash
flutter test test/models/multiplayer_test.dart
flutter test test/providers/multiplayer_provider_test.dart
```

**テストのカバレッジ:**

- MultiplayerUserProfile: 作成、勝率計算、JSON変換
- Friend: ステータス判定、JSON変換
- MatchResult: 作成、JSON変換
- MultiplayerMatch: 作成、進捗計算、JSON変換
- LeaderboardEntry: 作成、JSON変換
- LiveNotification: 作成、JSON変換
- MultiplayerNotifier: 初期化、マッチ管理、フレンド管理、通知管理、永続化

## パフォーマンス最適化

- **効率的なマッチメイキング**: ローカルマッチングアルゴリズム
- **リアルタイム同期**: SharedPreferencesによる即時同期
- **通知キャッシング**: FutureProvider自動キャッシング
- **限定的なデータ保持**: 履歴は最新100件のみ

## Future Enhancement

1. **ネットワーク統合**
   - Firebase Realtime Database でマッチデータ同期
   - Cloud Functions でマッチメイキングロジック
   - WebSocket でリアルタイム通知

2. **高度なマッチング**
   - ELOレーティングシステム
   - スキルベースのマッチング
   - 待機時間最適化アルゴリズム

3. **チーム機能**
   - ギルド/クラン作成
   - チームリーダーボード
   - リーグシステム

4. **ボイスチャット**
   - Agora またはTwilio統合
   - チーム内音声通信
   - 試合中のコミュニケーション

5. **高度な分析**
   - プレイヤースキル分析
   - メタゲーム分析
   - 戦略レコメンデーション

6. **esports対応**
   - トーナメント管理
   - ライブ配信統合
   - スペクテーターモード

## 参考資料

- [Multiplayer Game Design](https://www.gamedeveloper.com/)
- [Matchmaking Algorithms](https://en.wikipedia.org/wiki/Matchmaking_(video_games))
- [ELO Rating System](https://en.wikipedia.org/wiki/Elo_rating_system)
- [Real-time Collaboration](https://firebase.google.com/docs/firestore)
