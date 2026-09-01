# ランキング プライバシー機能

## 概要

ランキング表示時にユーザーの個人情報を保護する機能です。デフォルトでは名前を非公表にし、ユーザーが公表を希望する場合のみ名前を表示します。

## 機能説明

### 1. デフォルト設定：名前非公表
- 初期状態では、全ユーザーのランキングに名前は表示されない
- 代わりに匿名 ID（例：`USER_001`）が表示される
- ユーザーは常に自分の順位を確認できる

### 2. 匿名 ID システム
- 各ユーザーに一意の 6 文字ランダム ID を割り当て
- 初回ログイン時に自動生成・保存
- ユーザーが自分のランキングを識別するために使用
- 他のユーザーには、別の匿名 ID が表示される

### 3. 名前公表オプション
- ユーザーが「名前を公表する」を有効にした場合
- そのユーザーのランキング上の表示がニックネームに変わる
- 設定は SharedPreferences に永続保存される

## アーキテクチャ

### モデル

#### RankEntry (lib/models/ranking_entry.dart)
```dart
class RankEntry {
  final int rank;
  final String name;
  final int points;
  final String icon;
  final bool isMe;
  final bool namePublic;  // 新規: このユーザーが名前公開を許可しているか
  
  // 表示用の名前を取得
  String getDisplayName({String? anonymousId}) { ... }
}
```

### プロバイダ

#### ProfileState (lib/providers/profile_provider.dart)
```dart
class ProfileState {
  // ... 既存フィールド ...
  final bool rankingNamePublic;    // ランキングで名前を公表するか
  final String anonymousId;        // 匿名 ID
}
```

#### RankingPrivacyProvider (lib/providers/ranking_privacy_provider.dart)
```dart
// ランキング表示用のプライバシー対応エントリを生成
final rankingPrivacyProvider = 
  FutureProvider.family<List<PrivacyAwareRankEntry>, List<RankEntry>>(...)

// ユーザーの名前公表設定を確認
final myRankingVisibilityProvider = FutureProvider<bool>(...)

// ユーザーの匿名 ID を取得
final myAnonymousIdProvider = FutureProvider<String>(...)
```

### UI コンポーネント

#### RankingPrivacySettings (lib/widgets/ranking_privacy_settings.dart)
設定画面で使用するプライバシー設定ウィジェット
- 匿名 ID の表示
- 名前公表トグル
- プライバシー説明とリアルタイム情報表示

## 使用方法

### 1. 設定画面への統合

```dart
// lib/screens/settings_screen.dart の該当部分に追加
SingleChildScrollView(
  child: Column(
    children: [
      // ... その他の設定 ...
      const RankingPrivacySettings(),
      // ... その他の設定 ...
    ],
  ),
)
```

### 2. ランキング表示への適用

```dart
// lib/screens/ranking_screen.dart 内

// プライバシー対応ランキングを取得
final privacyAwareRankings = await ref
  .read(rankingPrivacyProvider(rankEntries).future);

// 表示時に getDisplayName() を使用
Text(entry.getDisplayName(
  anonymousId: entry.isMe 
    ? profile.anonymousId 
    : 'USER_${entry.rank}',
))
```

### 3. ユーザーの名前公表設定を変更

```dart
// 名前公表設定を有効にする
await ref.read(profileProvider.notifier)
  .setRankingNamePublic(true);

// 名前公表設定を無効にする
await ref.read(profileProvider.notifier)
  .setRankingNamePublic(false);
```

## データ永続化

### SharedPreferences キー

| キー | 説明 | 型 |
|-----|------|-----|
| `profile_ranking_name_public` | 名前公表設定 | bool |
| `profile_anonymous_id` | 匿名 ID | String |

### 初期化フロー

1. アプリ起動時、ProfileNotifier が `_load()` を実行
2. `profile_anonymous_id` が存在しない場合、新規生成して保存
3. `profile_ranking_name_public` がない場合は、デフォルト `false`

## プライバシー表示の例

### シナリオ 1: 名前非公表（デフォルト）
```
ランキング - 週間
─────────────────────────
1. USER_001 🏆  4850 ⭐
2. USER_002 🥈  4200 ⭐
3. あなた 🥉    3780 ⭐
4. USER_004 🎯  3100
5. USER_005 ⭐  2850

あなたの匿名 ID: USER_003
```

### シナリオ 2: 名前公表（ユーザーが有効化）
```
ランキング - 週間
─────────────────────────
1. ユーザー_001 🏆  4850 ⭐
2. ユーザー_002 🥈  4200 ⭐
3. あなたの名前 🥉    3780 ⭐  ← 自分は常に実名表示
4. USER_004 🎯  3100
5. USER_005 ⭐  2850

あなたの匿名 ID: USER_003（参考用）
```

## セキュリティ考慮事項

1. **匿名 ID の一意性**
   - 現在の実装は 6 文字ランダム生成
   - 本番環境では、UUID やサーバー側で生成することを推奨

2. **データ漏洩**
   - 匿名 ID は SharedPreferences に保存（端末ローカル）
   - ネットワーク送信時は暗号化を推奨

3. **プロフィール情報の連携**
   - バックエンド（Firebase）と同期する場合
   - `namePublic` フラグをユーザードキュメントに追加
   - サーバー側でプライバシー設定を検証

## 実装チェックリスト

- [ ] ProfileState に `rankingNamePublic` と `anonymousId` を追加
- [ ] ProfileNotifier に `setRankingNamePublic()` メソッドを追加
- [ ] RankEntry モデルを lib/models に作成
- [ ] RankingPrivacyProvider を作成
- [ ] RankingPrivacySettings ウィジェットを作成
- [ ] 設定画面に RankingPrivacySettings を統合
- [ ] ランキング表示ロジックを更新
- [ ] テストケースを作成

## Future Enhancement

1. **ランキング共有機能**
   - 「順位をシェア」時に、匿名 ID を含めたリンク生成
   - 他のユーザーが匿名 ID からあなたを確認可能に

2. **フレンド機能**
   - 特定ユーザーのランキングを常に実名で表示
   - フレンドリスト管理

3. **プライバシーレベル**
   - 公表 / 非公表 の 2 段階から、さらに細分化
   - 例：全員に公表 / フレンドのみ / 非公表

4. **バックエンド連携**
   - Firebase Realtime Database にプライバシー設定を同期
   - 複数デバイス間での設定同期

## 参考資料

- [GDPR プライバシー設計](https://www.gdprinfo.eu/)
- [Flutter SharedPreferences](https://pub.dev/packages/shared_preferences)
- [Riverpod 状態管理](https://riverpod.dev)
