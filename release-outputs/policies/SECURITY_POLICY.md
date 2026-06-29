# セキュリティポリシー / Security Policy
## 小学コレ！プログラミング

**最終更新日 / Last Updated**: 2026-06-08

---

## 1. データ保護 / Data Protection

- 学習データはすべて端末内の SharedPreferences に保存（暗号化プラットフォーム標準）
- TLS 1.2+ による通信暗号化（API通信時）
- プロダクションビルドでは機密データのログ出力なし

---

## 2. パーミッション / Permissions

| パーミッション | 用途 |
|--------------|------|
| INTERNET | AIコーチング API 通信 |
| RECEIVE_BOOT_COMPLETED | 学習リマインダー通知の再スケジュール |
| POST_NOTIFICATIONS | 学習リマインダー・週次レポート通知 |
| VIBRATE | ハプティクスフィードバック |

---

## 3. 使用するサードパーティサービス / Third-Party Services

| サービス | 用途 | ポリシー |
|---------|------|---------|
| Anthropic API | AIプログラミングコーチング | https://www.anthropic.com/privacy |
| Google Play Billing | プレミアムプラン課金 | Google のポリシーに準拠 |

---

## 4. APIキー管理 / API Key Management

- Anthropic API キーは `.env` ファイルで管理し、バージョン管理から除外
- リリースビルドではキーを難読化して組み込み
- キーは定期的にローテーション

---

## 5. 依存ライブラリ / Dependencies

- すべての依存パッケージを定期的に更新
- セキュリティ脆弱性は速やかに対応

---

## 6. セキュリティ報告 / Reporting

セキュリティ上の問題を発見された場合：

**Petit Studio**  
Email: zkaz83@gmail.com
