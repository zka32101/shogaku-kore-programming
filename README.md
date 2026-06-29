# 小学コレ！プログラミング 🧩

**コード探険 — ブロックからPythonへの段階学習アプリ**

小学4〜5年生向けのプログラミング学習アプリ。ブロック型ビジュアルプログラミングからPythonへ段階的に学べる。

---

## 🎯 コンセプト

```
【レベル1】ビジュアルプログラミング（ブロック型）
 → 条件分岐・ループ・変数・関数の概念を楽しく学ぶ
 
【レベル2】Pythonクイズ
 → コードを読んで結果を予測・実際のPython文法を習得
```

---

## 📱 画面構成

| 画面 | 説明 |
|-----|------|
| **ホーム** | 進捗・今日のチャレンジ・ユニット一覧 |
| **ステージ一覧** | 初級/中級/上級タブ、ステージカード |
| **ビジュアルエディタ** | ブロックパレット + スクリプトリスト + 採点 |
| **Pythonクイズ** | コードを読んで4択回答・タイマー付き |
| **実績** | バッジ・スター・クリア数 |
| **設定** | プロフィール・プレミアム・リセット |

---

## 📚 カリキュラム（12ステージ）

### 初級 — ブロックプログラミング（Stage 1-5）無料
1. 直線を描こう（前に進む）
2. 右に曲がろう（回転）
3. 四角を描こう（繰り返し）
4. 迷路を解こう①（複合）
5. 条件を使おう（if分岐）

### 中級 — Pythonクイズ（Stage 6-10）無料
6. はじめてのprint
7. forループ入門
8. if文で分岐
9. リストを使おう
10. 関数を作ろう

### 上級 — Python応用（Stage 11-12）プレミアム
11. 文字列を操作しよう
12. ファイルを読もう

---

## 🛠️ 技術スタック

| 項目 | 選択 |
|-----|------|
| フレームワーク | Flutter 3.13+ |
| 状態管理 | Riverpod 2.4+ |
| ローカル保存 | SharedPreferences |
| デザイン | Material Design 3（テーマカラー #1ABC9C） |
| 対象OS | iOS 14+、Android 10+ |

---

## 🚀 実行方法

```bash
cd apps/shogaku-kore-programming
flutter pub get
flutter run
```

---

## 💰 マネタイズ

- Stage 1-10: **無料**
- Stage 11-30: **月額 ¥999 / 年額 ¥5,980**（プレミアム）
- 初月7日間無料トライアル

---

## 📂 ディレクトリ構成

```
lib/
├── main.dart              # エントリーポイント + ナビゲーター
├── config/
│   ├── theme.dart         # カラー定義・テーマ（#1ABC9C）
│   └── constants.dart     # 定数
├── models/
│   ├── challenge.dart     # Challenge・Question・UserProgress
│   └── block_model.dart   # Block・BlockCategory
├── providers/
│   ├── challenges_provider.dart  # 全ステージデータ
│   ├── progress_provider.dart    # 学習進捗（SharedPreferences）
│   └── editor_provider.dart      # ビジュアルエディタ状態
└── screens/
    ├── home_screen.dart          # ホーム画面
    ├── stage_list_screen.dart    # ステージ一覧
    ├── quiz_screen.dart          # Pythonクイズ
    ├── editor_screen.dart        # ビジュアルエディタ
    ├── achievements_screen.dart  # 実績
    └── settings_screen.dart      # 設定
```
