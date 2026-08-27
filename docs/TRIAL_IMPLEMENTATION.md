# トライアル・フリーミアムシステム実装ガイド

## 概要

このドキュメントは、小学コレプログラミングのトライアル・フリーミアムシステムの実装詳細を記述しています。

---

## ディレクトリ構成

```
lib/
├── models/
│   └── subscription.dart          # トライアル状態モデル
├── providers/
│   └── subscription_provider.dart  # Riverpod トライアル管理
├── services/
│   └── monetization_service.dart   # ビジネスロジック
└── screens/
    └── paywall/                    # 支払いゲート UI（今後追加）
        ├── premium_unlock_screen.dart
        └── trial_offer_screen.dart
```

---

## 主要コンポーネント

### 1. `SubscriptionState` モデル

チャレンジのアクセス状態を表す：

```dart
const subscription = SubscriptionState(
  trialStartDate: DateTime(2026, 8, 27),
  isTrialActive: true,
  trialDaysRemaining: 10,
  hasUsedTrial: true,
  isPremiumSubscriber: false,
  shouldShowAds: false,
);

// チェック
subscription.canAccessPremiumContent();  // true
subscription.getTrialProgress();         // 0.29 (약 4일 사용)
subscription.isTrialExpired();           // false
```

### 2. `SubscriptionNotifier` プロバイダー

トライアル状態を管理：

```dart
// Riverpod で使用
final subscription = ref.watch(subscriptionProvider);

// トライアル開始
ref.read(subscriptionProvider.notifier).startTrial();

// プレミアム購読設定（1ヶ月）
ref.read(subscriptionProvider.notifier).setPremiumSubscription(monthsDuration: 1);

// プレミアム購読キャンセル
ref.read(subscriptionProvider.notifier).cancelPremiumSubscription();
```

### 3. `MonetizationService` ビジネスロジック

チャレンジアクセス判定：

```dart
// チャレンジがアクセス可能か判定
bool canAccess = MonetizationService.canAccessChallenge(
  challenge,
  subscription,
);

// ロック理由を取得
String? lockReason = MonetizationService.getChallengeLockReason(
  challenge,
  subscription,
);
// → null: ロックされていない
// → "プレミアム機能です..." : トライアル未開始
// → "トライアル期間が終了..." : トライアル終了後

// 統計情報
final stats = MonetizationService.getStatistics(
  allChallenges,
  subscription,
);
print('${stats.free} 無料 / ${stats.total} 全体 '
      '(${stats.freePercentage.toStringAsFixed(1)}%)')
// → "12 無料 / 30 全体 (40.0%)

// UI メッセージ
String message = MonetizationService.getTrialMessage(subscription);
// → "🎉 14日間の無料トライアルをお試しください..."
```

---

## チャレンジアクセス制御の実装

### Stage 1: チャレンジをクリックしたとき

```dart
void _onChallengePressed(Challenge challenge, WidgetRef ref) {
  final subscription = ref.read(subscriptionProvider);

  // アクセス可能かチェック
  if (!MonetizationService.canAccessChallenge(challenge, subscription)) {
    _showUnlockDialog(challenge, subscription, ref);
    return;
  }

  // チャレンジ開始
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChallengeDetailScreen(challenge: challenge),
    ),
  );
}
```

### Stage 2: ロック解除ダイアログ

```dart
void _showUnlockDialog(
  Challenge challenge,
  SubscriptionState subscription,
  WidgetRef ref,
) {
  final lockReason = MonetizationService.getChallengeLockReason(
    challenge,
    subscription,
  );
  
  final cta = MonetizationService.getCallToAction(subscription);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('🔒 プレミアムコンテンツです'),
      content: Text(lockReason ?? ''),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            if (subscription.hasUsedTrial) {
              _showPremiumSubscriptionScreen();
            } else {
              _startTrialAndContinue(challenge, ref);
            }
          },
          child: Text(cta),
        ),
      ],
    ),
  );
}
```

### Stage 3: トライアル開始処理

```dart
Future<void> _startTrialAndContinue(
  Challenge challenge,
  WidgetRef ref,
) async {
  // トライアル開始
  await ref.read(subscriptionProvider.notifier).startTrial();

  // トライアル開始画面を表示
  if (mounted) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 トライアル開始！'),
        content: const Text(
          '14日間、すべてのプレミアムコンテンツが利用できます。'
          'さあ、チャレンジを始めましょう！',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // チャレンジ画面へ遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChallengeDetailScreen(challenge: challenge),
                ),
              );
            },
            child: const Text('チャレンジを開始'),
          ),
        ],
      ),
    );
  }
}
```

---

## UI コンポーネント：トライアルバナー

ホーム画面またはステージリスト画面にトライアルバナーを表示：

```dart
Widget _buildTrialBanner(SubscriptionState subscription) {
  if (!subscription.isTrialActive) {
    return const SizedBox.shrink();
  }

  final remaining = subscription.trialDaysRemaining;
  final progress = subscription.getTrialProgress();

  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade300, Colors.purple.shade300],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              '⏰ トライアル進行中',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '残り $remaining 日',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // プログレスバー
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'すべてのプレミアムコンテンツが利用可能です。期間内にたくさんチャレンジしましょう！',
          style: TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}
```

---

## 広告システム統合

### Google Mobile Ads 初期化

`main.dart` で初期化（今後実装予定）:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Google Mobile Ads 初期化
  await MobileAds.instance.initialize();

  // ...
}
```

### 広告表示判定

```dart
// Riverpod で使用
final shouldShowAds = ref.watch(shouldShowAdsProvider);

if (shouldShowAds) {
  // バナー広告表示
  // ...
}
```

---

## テストシナリオ

### テストケース 1: トライアル未開始ユーザー

```dart
test('ユーザーがトライアル開始前に有料コンテンツにアクセスできない', () {
  final sub = SubscriptionState();
  final challenge = Challenge(
    id: 'paid_challenge',
    isFree: false,
    // ...
  );

  expect(
    MonetizationService.canAccessChallenge(challenge, sub),
    false,
  );
  
  final reason = MonetizationService.getChallengeLockReason(challenge, sub);
  expect(reason, contains('無料トライアル'));
});
```

### テストケース 2: トライアル中のユーザー

```dart
test('トライアル中のユーザーはすべてのコンテンツにアクセス可能', () {
  final now = DateTime.now();
  final sub = SubscriptionState(
    trialStartDate: now,
    isTrialActive: true,
    trialDaysRemaining: 10,
    hasUsedTrial: true,
  );
  
  final paidChallenge = Challenge(
    id: 'paid_challenge',
    isFree: false,
    // ...
  );

  expect(
    MonetizationService.canAccessChallenge(paidChallenge, sub),
    true,
  );
});
```

### テストケース 3: トライアル終了後

```dart
test('トライアル終了後は有料コンテンツにアクセス不可', () {
  final pastDate = DateTime.now().subtract(const Duration(days: 15));
  final sub = SubscriptionState(
    trialStartDate: pastDate,
    isTrialActive: false,
    hasUsedTrial: true,
  );
  
  expect(sub.isTrialExpired(), true);
  expect(sub.shouldShowAds, true);
});
```

---

## 今後の拡張

### Phase 3: 広告システム（次予定）
- [ ] Google Mobile Ads SDK 統合
- [ ] バナー広告実装
- [ ] インタースティシャル広告実装
- [ ] リワード広告実装（ヒント獲得時など）

### Phase 4: アプリ内課金
- [ ] Apple In-App Purchase 実装
- [ ] Google Play Billing 実装
- [ ] 購読管理画面実装
- [ ] レシート検証

### Phase 5: 分析・最適化
- [ ] Firebase Analytics 統合
- [ ] コンバージョン跡付け
- [ ] A/B テスト実装
- [ ] リテンション分析

---

## トラブルシューティング

### Q: トライアルが表示されない
**A**: `SubscriptionNotifier` が正しく初期化されているか確認：
```dart
// main.dart で ProviderScope に必ず含める
ProviderScope(
  child: MyApp(),
);
```

### Q: 広告が表示されない
**A**: `shouldShowAdsProvider` の値を確認：
```dart
final shouldShow = ref.watch(shouldShowAdsProvider);
print('Show ads: $shouldShow'); // デバッグ出力
```

### Q: SharedPreferences に保存されない
**A**: パーミッションを確認（Android の場合）:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 参考ドキュメント

- [MONETIZATION.md](./MONETIZATION.md) - マネタイズ戦略
- [Riverpod Documentation](https://riverpod.dev)
- [Google Mobile Ads Documentation](https://developers.google.com/mobile-ads-sdk)
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

