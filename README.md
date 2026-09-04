# 小学コレ！プログラミング 🧩

<div align="center">

**コード探険 — ブロックからPythonへの段階学習アプリ**

小学4〜5年生向けのプログラミング学習アプリ。  
ブロック型ビジュアルプログラミングからPythonへ段階的に学べます。

[![GitHub stars](https://img.shields.io/github/stars/zka32101/shogaku-kore-programming?style=social)](https://github.com/zka32101/shogaku-kore-programming)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.13+-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

</div>

---

## 📱 このアプリについて

### 🎯 何ができるの？

「小学コレ！プログラミング」は、プログラミングの基本を楽しく学べるアプリです。

**レベル1️⃣（初級）- ビジュアルプログラミング**
- 色とりどりの「ブロック」を組み立てる感覚でプログラミング
- ドラッグ&ドロップでコードを作成
- 自分のコードがすぐに画面で動く！

**レベル2️⃣（中級）- Pythonクイズ**
- 実際のプログラミング言語「Python」のコードを読む
- 「このコード、何が出力される？」を 4 択で回答
- 楽しみながら実践的なスキルを習得

**レベル3️⃣（上級）- Python応用**
- 文字列操作やファイル読み込みなど、より高度な内容
- プレミアム会員向けの特別なチャレンジ

---

## 🚀 今すぐ始める（5 分で起動）

### **前提条件**
- Flutter 3.13 以上がインストールされていること
- iOS 14+ または Android 10+ のデバイス

### **クイックスタート**

```bash
# 1. リポジトリをクローン
git clone https://github.com/zka32101/shogaku-kore-programming.git
cd shogaku-kore-programming

# 2. 依存関係をインストール
flutter pub get

# 3. アプリを実行
flutter run

# iOS を指定して実行する場合
flutter run -d iPhone
```

**詳細なセットアップは [GETTING_STARTED.md](docs/GETTING_STARTED.md) をご覧ください。**

---

## 🎓 学習ロードマップ

### 📚 12 のステージで段階的に学習

```
【初級】 Stage 1-5 （ブロックプログラミング）
├─ Stage 1: 直線を描こう
├─ Stage 2: 右に曲がろう
├─ Stage 3: 四角を描こう
├─ Stage 4: 迷路を解こう①
└─ Stage 5: 条件を使おう

【中級】 Stage 6-10 （Pythonクイズ）
├─ Stage 6: はじめてのprint
├─ Stage 7: forループ入門
├─ Stage 8: if文で分岐
├─ Stage 9: リストを使おう
└─ Stage 10: 関数を作ろう

【上級】 Stage 11-12 （Python応用）※プレミアム
├─ Stage 11: 文字列を操作しよう
└─ Stage 12: ファイルを読もう
```

**全ステージ無料でプレイ可能！** 🎉  
プレミアム会員になると、さらに多くのチャレンジが解放されます。

---

## 📸 スクリーンショット

| ホーム画面 | ビジュアルエディタ | Pythonクイズ | 実績 |
|----------|----------------|-----------|------|
| 進捗確認 | ブロック組立 | コード読解 | バッジ表示 |
| 🎮 | 🎨 | 💡 | 🏆 |

*画像はサンプルです。実際のアプリをダウンロードしてお試しください。*

---

## ✨ 主な機能

### 🎮 ビジュアルプログラミング
- ドラッグ&ドロップでコードを組立
- リアルタイムで実行結果を確認
- エラーメッセージで学習をサポート

### 📖 Pythonクイズ
- 実際のコードを読んで出力を予測
- 複数選択肢から正解を選択
- 解説付きで知識を深化

### 🏆 進捗管理
- バッジ・スターシステムで達成感を演出
- 学習進捗をリアルタイム表示
- 「今日のチャレンジ」で毎日の学習をサポート

### 🎵 ゲーミフィケーション
- キャラクター育成システム
- レベルアップでアンロック機能
- ランキング機能で友達と競争

---

## 💰 価格

| プラン | 価格 | 対象ステージ |
|--------|------|-----------|
| **無料** | 0 円 | Stage 1-10 |
| **プレミアム** | ¥999/月 または ¥5,980/年 | Stage 1-12 + 追加チャレンジ |

**初月 7 日間は無料でプレミアムをお試しできます！** 🎁

---

## 🛠️ 技術スタック

### フロントエンド
| 項目 | 技術 |
|-----|------|
| フレームワーク | **Flutter 3.13+** |
| UI デザイン | Material Design 3 |
| 状態管理 | Riverpod 2.4+ |
| ローカルストレージ | SharedPreferences |

### バックエンド・サービス
| 項目 | 技術 |
|-----|------|
| 認証 | Firebase Authentication |
| ファイル保存 | Firebase Cloud Storage |
| リアルタイムDB | Firestore |
| 通知 | Firebase Cloud Messaging |

### 環境
| 項目 | バージョン |
|-----|----------|
| iOS | 14.0+ |
| Android | 10.0+ |
| Dart SDK | 3.11.5+ |

---

## 📁 プロジェクト構成

```
lib/
├── main.dart                    # アプリのエントリーポイント
│
├── config/
│   ├── theme.dart               # カラー定義・テーマ（#1ABC9C）
│   └── constants.dart           # アプリ内定数
│
├── models/
│   ├── challenge.dart           # チャレンジデータモデル
│   ├── block_model.dart         # ブロックデータモデル
│   └── user.dart                # ユーザー情報
│
├── providers/
│   ├── challenges_provider.dart  # ステージ・チャレンジデータ管理
│   ├── progress_provider.dart    # 学習進捗管理
│   ├── editor_provider.dart      # エディタ状態管理
│   └── auth_provider.dart        # 認証状態管理
│
├── screens/
│   ├── home_screen.dart          # ホーム画面
│   ├── stage_list_screen.dart    # ステージ一覧
│   ├── editor_screen.dart        # ビジュアルエディタ
│   ├── quiz_screen.dart          # Pythonクイズ
│   ├── achievements_screen.dart  # 実績画面
│   ├── character_screen.dart     # キャラクター画面
│   └── settings_screen.dart      # 設定画面
│
├── widgets/
│   ├── block_widget.dart         # ブロックUIコンポーネント
│   ├── quiz_card.dart            # クイズカード
│   └── badge_display.dart        # バッジ表示
│
└── utils/
    ├── validators.dart           # 入力検証
    ├── formatters.dart           # フォーマット処理
    └── helpers.dart              # ヘルパー関数
```

---

## 🔒 セキュリティ・プライバシー

### 🔐 セキュリティ対策
- ✅ Firebase認証で安全なログイン
- ✅ APIキーは環境変数管理（平文保存なし）
- ✅ App Transport Security (ATS) で通信暗号化
- ✅ Keychain でトークン安全保存

### 🛡️ プライバシー対応
- ✅ App Store PrivacyInfo.xcprivacy 対応
- ✅ ユーザーデータを最小限に管理
- ✅ プッシュ通知は明示的な許可後のみ
- ✅ OWASP MASVS L1 準拠

**詳細は [プライバシーポリシー](docs/PRIVACY.md) をご覧ください。**

---

## 🔧 開発者向け情報

### セットアップ

```bash
# 環境変数を設定
cp .env.example .env

# Firebase 認証情報を入力
# （詳細は docs/FIREBASE_SETUP.md）

# 依存関係をインストール
flutter pub get

# コード解析を実行
flutter analyze

# テストを実行
flutter test
```

### iOS ビルド

```bash
# iOS の依存関係をインストール
cd ios
pod install
cd ..

# iOS でデバッグ実行
flutter run -d iPhone

# iOS リリースビルド
flutter build ios --release
```

**詳細は [開発者ガイド](docs/DEVELOPMENT.md) をご覧ください。**

---

## 📚 ドキュメント

| ドキュメント | 対象者 | 内容 |
|----------|--------|------|
| [GETTING_STARTED.md](docs/GETTING_STARTED.md) | ユーザー | 5分クイックスタート |
| [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) | 開発者 | Firebase 設定ガイド |
| [DEVELOPMENT.md](docs/DEVELOPMENT.md) | 開発者 | 開発環境セットアップ |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 貢献者 | 貢献ガイド |
| [PRIVACY.md](docs/PRIVACY.md) | ユーザー | プライバシーポリシー |

---

## 🐛 トラブルシューティング

### よくある問題と解決方法

**Q: `flutter run` が失敗する**
```
A: 以下を試してください
   1. flutter clean
   2. flutter pub get
   3. flutter run
```

**Q: iOS ビルドが失敗する**
```
A: 以下を実行してください
   1. cd ios
   2. pod install
   3. cd ..
   4. flutter build ios --release
```

**Q: Firebase 接続エラー**
```
A: 以下を確認してください
   1. .env ファイルが存在するか
   2. Firebase 認証情報が正しいか
   3. インターネット接続の確認
```

詳細は [FAQ](docs/FAQ.md) をご覧ください。

---

## 🤝 貢献方法

バグ報告や機能提案は大歓迎です！

1. **Issue を作成** → バグや機能リクエスト
2. **Fork して機能ブランチを作成** → 改善を実装
3. **Pull Request を作成** → レビューを待つ

詳細は [CONTRIBUTING.md](CONTRIBUTING.md) をご覧ください。

---

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルをご覧ください。

---

## 📞 サポート

問題が発生した場合：
- **バグ報告**: [GitHub Issues](https://github.com/zka32101/shogaku-kore-programming/issues)
- **質問**: [Discussions](https://github.com/zka32101/shogaku-kore-programming/discussions)

---

<div align="center">

**楽しくプログラミングを学ぼう！** 🚀

Made with ❤️ for Japanese elementary school students

</div>
