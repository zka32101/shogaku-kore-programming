# 開発者ガイド 👨‍💻

このプロジェクトに貢献したい開発者向けのガイドです。

---

## 📋 前提条件

- Flutter 3.13 以上
- Dart SDK 3.11.5 以上
- iOS: Xcode 14 以上（Mac）
- Android: Android Studio + Android SDK

---

## 🚀 開発環境セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/zka32101/shogaku-kore-programming.git
cd shogaku-kore-programming
```

### 2. 依存関係をインストール

```bash
flutter pub get
```

### 3. Firebase 設定

```bash
cp .env.example .env
# Firebase Console から値を取得して .env を編集
# 詳細は docs/FIREBASE_SETUP.md を参照
```

### 4. コード生成（Riverpod）

一部の機能は Riverpod の code generation が必要です：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📁 プロジェクト構成

```
lib/
├── main.dart                         # アプリ起動点
├── config/
│   ├── theme.dart                    # Material Design 3 テーマ
│   └── constants.dart                # アプリ全体の定数
├── models/
│   ├── challenge.dart                # チャレンジモデル
│   ├── block_model.dart              # ブロックモデル
│   ├── user.dart                     # ユーザーモデル
│   └── progress.dart                 # 学習進捗モデル
├── providers/
│   ├── challenges_provider.dart      # ステージデータ管理
│   ├── progress_provider.dart        # 進捗管理
│   ├── editor_provider.dart          # エディタ状態
│   └── auth_provider.dart            # 認証状態
├── screens/
│   ├── home_screen.dart              # ホーム画面
│   ├── stage_list_screen.dart        # ステージ一覧
│   ├── editor_screen.dart            # ビジュアルエディタ
│   ├── quiz_screen.dart              # Pythonクイズ
│   ├── achievements_screen.dart      # 実績
│   ├── character_screen.dart         # キャラクター
│   └── settings_screen.dart          # 設定
├── widgets/
│   ├── block_widget.dart             # ブロックUI
│   ├── quiz_card.dart                # クイズカード
│   └── custom_widgets.dart           # その他カスタムウィジェット
└── utils/
    ├── validators.dart               # 入力検証
    ├── formatters.dart               # フォーマット処理
    └── helpers.dart                  # ヘルパー関数
```

---

## 💻 開発ワークフロー

### ステップ 1: 新規ブランチを作成

```bash
git checkout -b feature/my-feature
# または
git checkout -b fix/my-bug-fix
```

### ステップ 2: コードを編集

エディタ（VS Code、IntelliJ IDEA など）でコードを編集します。

### ステップ 3: ホットリロードで確認

```bash
flutter run
# ターミナルで 'r' キーを押す（ホットリロード）
# または 'R' キー（ホット再起動）
```

### ステップ 4: コード解析と整形

```bash
# 静的解析を実行
flutter analyze

# コード整形を実行
dart format lib/
```

### ステップ 5: テストを実行

```bash
flutter test
```

### ステップ 6: コミット

```bash
git add .
git commit -m "feat: 新機能の説明"
# または
git commit -m "fix: バグ修正の説明"
```

### ステップ 7: Push と PR

```bash
git push origin feature/my-feature
# GitHub UI から Pull Request を作成
```

---

## 🎨 コード規約

### ファイル命名規則

- **スクリーンファイル**: `*_screen.dart`
  ```dart
  lib/screens/home_screen.dart
  lib/screens/stage_list_screen.dart
  ```

- **プロバイダーファイル**: `*_provider.dart`
  ```dart
  lib/providers/progress_provider.dart
  lib/providers/auth_provider.dart
  ```

- **モデルファイル**: `*_model.dart` または `*.dart`
  ```dart
  lib/models/challenge.dart
  lib/models/block_model.dart
  ```

### クラス命名規則

- **ウィジェット**: PascalCase で終わりに Widget
  ```dart
  class HomeScreen extends StatelessWidget { }
  class BlockWidget extends StatefulWidget { }
  ```

- **モデル**: PascalCase
  ```dart
  class Challenge { }
  class BlockModel { }
  ```

- **定数**: camelCase または UPPER_SNAKE_CASE
  ```dart
  const double defaultPadding = 16.0;
  const String APP_NAME = 'shogaku_kore_programming';
  ```

### コメント規約

```dart
/// 公開 API のドキュメントコメント
/// 
/// 説明をここに記述
/// 
/// Example:
/// ```dart
/// myFunction();
/// ```
void myPublicFunction() { }

// 実装上の注釈
// TODO: 将来的に実装する機能
// FIXME: バグがある部分
// NOTE: 重要な注記
void myPrivateFunction() { }
```

---

## 🧪 テストの書き方

### ユニットテスト

```dart
// test/models/challenge_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/challenge.dart';

void main() {
  group('Challenge Model', () {
    test('Challenge is created correctly', () {
      final challenge = Challenge(
        id: '1',
        title: 'Test',
        description: 'Test description',
      );
      
      expect(challenge.id, equals('1'));
      expect(challenge.title, equals('Test'));
    });
  });
}
```

### ウィジェットテスト

```dart
// test/screens/home_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen displays correctly', (tester) async {
    await tester.pumpWidget(MyApp());
    
    expect(find.text('Home'), findsOneWidget);
  });
}
```

### テスト実行

```bash
# すべてのテストを実行
flutter test

# 特定のテストファイルを実行
flutter test test/models/challenge_test.dart

# カバレッジを表示
flutter test --coverage
```

---

## 🔐 セキュリティ考慮事項

### Firebase 認証情報

- ✅ `.env` ファイルを使用
- ✅ `.gitignore` に `.env` を追加
- ✅ GitHub Actions Secrets を設定

### API キー

- ✅ Platform-specific API キーを使用（iOS/Android 別）
- ✅ ハードコード禁止
- ✅ 環境変数として管理

### データ保存

- ✅ 機密トークン: Keychain（iOS）/ Keystore（Android）
- ✅ 一般データ: SharedPreferences
- ✅ 機密データベース: 暗号化 SQLite（必要な場合）

### 通信

- ✅ TLS 1.2 以上を使用
- ✅ Certificate Pinning を検討
- ✅ API レスポンスの検証

---

## 📊 ビルド

### iOS ビルド

```bash
# デバッグビルド
flutter build ios

# リリースビルド
flutter build ios --release

# App Store へのアップロード用
flutter build ios --release -t lib/main.dart
```

### Android ビルド

```bash
# デバッグビルド
flutter build apk

# リリースビルド
flutter build apk --release

# App Bundle（Google Play 推奨）
flutter build appbundle --release
```

---

## 🐛 デバッグ

### ホットリロード / ホット再起動

```bash
flutter run

# ターミナルで以下のキーを使用:
# r: ホットリロード（Fast refresh）
# R: ホット再起動（Full restart）
# h: ヘルプ表示
# q: 終了
```

### デバッグログを表示

```bash
flutter run -v  # 詳細ログ表示
```

### ブレークポイントデバッグ（VS Code）

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart"
    }
  ]
}
```

---

## 📦 パッケージ管理

### 新しいパッケージを追加

```bash
flutter pub add package_name

# または
flutter pub add package_name:version_number
```

### パッケージを更新

```bash
flutter pub upgrade

# 特定のパッケージを更新
flutter pub upgrade package_name
```

### パッケージを削除

```bash
flutter pub remove package_name
```

### 依存関係を確認

```bash
flutter pub deps
```

---

## 🚀 デプロイ

### iOS App Store へのアップロード

1. Xcode で signing を設定
2. ビルド番号を increment
3. `flutter build ios --release` で build
4. Transporter アプリで App Store に upload

### Google Play へのアップロード

1. Android Studio で signing を設定
2. バージョンコードを increment
3. `flutter build appbundle --release` で build
4. Google Play Console で upload

---

## 📞 サポート

開発中に問題が発生した場合：

1. **GitHub Issues** で既存の issue を検索
2. **FAQ** を確認（[docs/FAQ.md](FAQ.md)）
3. **新しい Issue** を作成（テンプレートに従う）

---

## 🤝 貢献ガイド

→ [CONTRIBUTING.md](../CONTRIBUTING.md) を参照してください

---

Happy Coding! 🎉
