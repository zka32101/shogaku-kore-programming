# 広告システム実装ガイド

## 概要

小学コレプログラミングの広告システムは **Google Mobile Ads** を使用して実装されています。

### 広告タイプ
1. **バナー広告** - 画面下部に常時表示（無料ユーザー向け）
2. **インタースティシャル広告** - チャレンジ完了時、ステージ移動時など
3. **リワード広告** - ヒント獲得時などにユーザーが視聴を選択

---

## ディレクトリ構成

```
lib/
├── services/
│   └── ad_service.dart               # Google Mobile Ads 管理
├── providers/
│   └── ad_provider.dart              # Riverpod プロバイダー
└── widgets/
    └── banner_ad_widget.dart         # バナー広告ウィジェット
```

---

## セットアップ手順

### Step 1: Google Mobile Ads SDK をインストール

`pubspec.yaml` に追加：

```yaml
dependencies:
  google_mobile_ads: ^6.0.0
```

### Step 2: 広告ユニット ID を取得

[Google AdMob](https://admob.google.com) から以下を取得：

- **バナー広告**: `ca-app-pub-3940256099942544/6300978111` (Android Demo)
- **インタースティシャル**: `ca-app-pub-3940256099942544/1033173712` (Android Demo)
- **リワード広告**: `ca-app-pub-3940256099942544/5224354917` (Android Demo)

### Step 3: main.dart で初期化

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'lib/services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Google Mobile Ads 初期化
  final adService = AdService();
  await adService.initialize();
  
  runApp(const MyApp());
}
```

### Step 4: AndroidManifest.xml を更新

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <!-- Google Mobile Ads 権限 -->
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

  <application>
    <!-- Google Mobile Ads Meta -->
    <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyyyyyy" />
  </application>
</manifest>
```

### Step 5: Info.plist を更新（iOS）

```xml
<!-- ios/Runner/Info.plist -->
<dict>
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyyyyyy</string>
</dict>
```

---

## 使用方法

### バナー広告の表示

**方法1: ウィジェットとして使用**

```dart
import 'lib/widgets/banner_ad_widget.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: MyContent()),
          const BottomBannerAdWidget(), // 画面下部にバナー広告
        ],
      ),
    );
  }
}
```

**方法2: ListView の末尾に追加**

```dart
ListView(
  children: [
    // ...コンテンツ...
    const BannerAdWidget(), // リスト末尾に広告
  ],
)
```

### インタースティシャル広告の表示

チャレンジ完了時に表示：

```dart
Future<void> _onChallengeCompleted(WidgetRef ref) async {
  final interstitialController = 
      ref.read(interstitialAdControllerProvider);
  
  // 広告を表示（事前に事前ロード推奨）
  await interstitialController.show(
    onAdDismissed: () {
      // 広告が閉じられた後の処理
      Navigator.pop(context);
    },
  );
}
```

事前ロード（バックグラウンド）：

```dart
// App 起動時
ref.read(interstitialAdControllerProvider).preload();

// または特定の画面遷移時
ref.read(interstitialAdControllerProvider).preload();
```

### リワード広告の表示

ユーザーがヒントを見る際：

```dart
Future<void> _showHintWithReward(WidgetRef ref) async {
  final rewardedController = ref.read(rewardedAdControllerProvider);
  
  // 広告を表示
  final earnedReward = await rewardedController.show(
    onUserEarnedReward: () {
      // ユーザーがリワードを獲得
      _giveHintToUser();
    },
    onAdDismissed: () {
      // 広告が閉じられた
    },
  );
  
  if (!earnedReward) {
    // 広告をスキップされた場合（プレミアム購読者は自動付与）
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ヒントを見る'),
        content: const Text('広告を最後まで視聴してください'),
      ),
    );
  }
}
```

---

## トライアル・購読との連携

### 広告表示ロジック

```dart
// 広告が表示されるかを判定
subscription.shouldShowAds

// トライアル中: false (広告なし)
// プレミアム購読中: false (広告なし)
// 無料ユーザー: true (広告表示)
```

### 実装例

```dart
final subscription = ref.watch(subscriptionProvider);

if (subscription.canAccessPremiumContent()) {
  // トライアル中またはプレミアム購読者
  // → 広告を表示しない
  return const SizedBox.shrink();
} else {
  // 無料ユーザー
  // → 広告を表示
  return const BottomBannerAdWidget();
}
```

---

## パフォーマンス最適化

### 広告のキャッシング

```dart
// 画面遷移前に次の広告をロード
final interstitialController = 
    ref.read(interstitialAdControllerProvider);
await interstitialController.preload();
```

### メモリ管理

```dart
// スクリーン終了時に広告をクリーンアップ
@override
void dispose() {
  AdService().dispose();
  super.dispose();
}
```

### ネットワーク節約

```dart
// 広告を高頻度で表示しない（最小間隔 60 秒推奨）
const minAdDisplayInterval = Duration(seconds: 60);
```

---

## テスト AD ユニット ID

開発・テスト時は以下のテスト ID を使用：

| タイプ | Android | iOS |
|--------|---------|-----|
| バナー | `ca-app-pub-3940256099942544/6300978111` | `ca-app-pub-3940256099942544/4469989529` |
| インタースティシャル | `ca-app-pub-3940256099942544/1033173712` | `ca-app-pub-3940256099942544/4411468910` |
| リワード | `ca-app-pub-3940256099942544/5224354917` | `ca-app-pub-3940256099942544/1712485313` |

**⚠️ 本番環境では実際の AdMob ユニット ID に置き換えてください。**

---

## AdMob 本番環境への移行

### 1. AdMob アカウント作成

https://admob.google.com で Google アカウントでログイン

### 2. アプリ登録

- App の作成
- Android/iOS アプリ登録
- 広告ユニット ID 取得

### 3. ユニット ID を更新

`lib/services/ad_service.dart` の以下を更新：

```dart
// テストから本番へ変更
// FROM: 'ca-app-pub-3940256099942544/6300978111'
// TO: 'ca-app-pub-XXXXXXX/YYYYYYYY'
```

### 4. アプリストアにサブミット

- Apple App Store
- Google Play Store

---

## ポリシー・ガイドライン

### Google Ads ポリシー

- ✅ 広告オプトアウト機能を提供
- ✅ 広告は適切な間隔で表示
- ✅ クリック詐欺防止
- ✅ データプライバシー準守

### 子ども向けアプリの注意点

このアプリは子ども向けのため：

- ❌ 個人情報に基づくターゲティング広告は不可
- ✅ 「Google Families」認定広告ネットワークを使用
- ✅ COPPA（児童オンラインプライバシー保護法）準守

---

## トラブルシューティング

### Q: 広告が表示されない

**A**: 以下をチェック：
1. テスト AD ユニット ID を使用しているか
2. インターネット接続が有効か
3. AdMob アカウントが有効か
4. アプリが AdMob に登録されているか

### Q: 広告のエラー

**A**: ログを確認：
```
I/Ads: Google Mobile Ads SDK version: 20.0.0
I/Ads: Use RequestConfiguration.Builder().setMaxAdContentRating() to set the max ad content rating.
```

### Q: リワード広告が作動しない

**A**: 以下をチェック：
1. `onUserEarnedReward` コールバックが実装されているか
2. 広告がロード済みか
3. 広告を最後まで視聴しているか

---

## 参考資料

- [Google Mobile Ads SDK ドキュメント](https://developers.google.com/mobile-ads-sdk)
- [Google AdMob 公式](https://admob.google.com)
- [COPPA - Children's Online Privacy Protection](https://www.ftc.gov/business-guidance/privacy-security/childrens-online-privacy-protection-rule-coppa)
- [Flutter Google Mobile Ads Plugin](https://pub.dev/packages/google_mobile_ads)

