# 貢献ガイド 🤝

「小学コレ！プログラミング」へのご貢献ありがとうございます！

このプロジェクトをより良くするための貢献方法を説明します。

---

## 💡 貢献できる方法

### 🐛 バグ報告

バグを発見したら、以下の情報を含めて Issue を作成してください：

- **バグの説明**: 何が起こったのか
- **再現手順**: どうすれば再現できるのか
- **期待される動作**: 本来どうなるべきだったのか
- **実際の動作**: 実際に何が起こったのか
- **環境情報**:
  - Flutter バージョン
  - Dart バージョン
  - OS（iOS/Android）とバージョン

**Issue テンプレート:**
```
### バグの説明
[ここにバグの説明を記入]

### 再現手順
1. [ステップ 1]
2. [ステップ 2]
3. [ステップ 3]

### 期待される動作
[ここに期待される動作を記入]

### 実際の動作
[ここに実際の動作を記入]

### 環境情報
- Flutter: [バージョン]
- Dart: [バージョン]
- OS: iOS/Android [バージョン]
```

### 🚀 機能リクエスト

新しい機能を提案する場合：

- **機能説明**: 何をしたいのか
- **ユースケース**: なぜ必要なのか
- **追加による利点**: メリットは何か

**Feature Request テンプレート:**
```
### 機能の説明
[ここに機能の説明を記入]

### ユースケース
[ここにユースケースを記入]

### 追加による利点
[ここに利点を記入]
```

### 📝 ドキュメント改善

ドキュメントの誤字・脱字や、わかりにくい部分を見つけたら：

1. GitHub で直接編集（小規模な場合）
2. または Pull Request を作成

### 💻 コード貢献

新機能の実装やバグ修正は大歓迎です！

---

## 🚀 Pull Request フロー

### ステップ 1: Issue を作成・確認

大きな変更の場合は、まず Issue を作成して相談してください。

```
例: "Stage 11 用の新しい Python challenge を追加したいです"
```

### ステップ 2: Fork する

GitHub の右上の「Fork」ボタンをクリック

### ステップ 3: ブランチを作成

```bash
git checkout -b feature/my-awesome-feature
# または
git checkout -b fix/issue-number
```

**ブランチ命名規則:**
- `feature/`: 新機能
- `fix/`: バグ修正
- `docs/`: ドキュメント更新
- `refactor/`: コードの整理
- `test/`: テスト追加

### ステップ 4: コードを書く

```bash
# 開発環境をセットアップ
flutter pub get

# ホットリロードで確認
flutter run
```

### ステップ 5: テストを追加

```bash
# 既存テストを実行
flutter test

# 新しいテストを追加
# test/ ディレクトリに *_test.dart ファイルを作成
```

### ステップ 6: コミットする

```bash
git add .
git commit -m "feat: 新機能の説明"
```

**コミットメッセージのフォーマット:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**例:**
```
feat(editor): ブロックの複製機能を追加

ビジュアルエディタで選択したブロックを複製できるようにしました。
右クリックメニューから「複製」を選択すると、
選択したブロックの下に同じブロックが追加されます。

Closes #123
```

**Type:**
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント更新
- `style`: コード整形（機能変更なし）
- `refactor`: コード整理
- `test`: テスト追加
- `chore`: ビルド設定やパッケージ更新

### ステップ 7: Code Review 前にチェック

```bash
# コード解析
flutter analyze

# コード整形
dart format lib/

# テスト実行
flutter test

# ホットリロードで最終確認
flutter run
```

### ステップ 8: Push する

```bash
git push origin feature/my-awesome-feature
```

### ステップ 9: Pull Request を作成

GitHub で「Pull Request」をクリック

**PR テンプレート:**
```
## 📝 説明

[変更内容を簡潔に説明]

## 🎯 関連 Issue

Closes #[Issue番号]

## ✅ チェックリスト

- [ ] コード解析に通っている（`flutter analyze`）
- [ ] テストを追加/更新した
- [ ] ドキュメントを更新した
- [ ] コミットメッセージが明確である

## 📸 スクリーンショット（UI 変更の場合）

[ビフォー・アフターの画像]
```

### ステップ 10: レビューに対応

Review comments に返信して、必要な修正を行う

```bash
# 修正後、再度コミット
git add .
git commit -m "refactor: Review comment に対応"
git push origin feature/my-awesome-feature
```

### ステップ 11: Merge 完了！

Maintainer が Approve すると、自動的にマージされます。

---

## 📋 チェックリスト（PR 前に確認）

- [ ] 最新の `main` ブランチから新規ブランチを作成したか
- [ ] 機能やバグ修正がコミットされているか
- [ ] テストを追加したか（該当する場合）
- [ ] ドキュメントを更新したか（該当する場合）
- [ ] コード解析に通っているか（`flutter analyze`）
- [ ] テストに合格しているか（`flutter test`）
- [ ] コミットメッセージが明確か
- [ ] PR テンプレートを使用しているか

---

## 🎨 コード規約

詳細は [開発者ガイド](docs/DEVELOPMENT.md#-コード規約) をご覧ください。

### 簡単なポイント

```dart
// ✅ Good
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(child: const Text('Welcome')),
    );
  }
}

// ❌ Bad
class home_screen extends StatelessWidget {
  home_screen();
  
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Text('Welcome'),
    );
  }
}
```

---

## 🧪 テストの例

```dart
// test/models/challenge_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/challenge.dart';

void main() {
  group('Challenge Model Tests', () {
    test('Challenge は正しく作成される', () {
      final challenge = Challenge(
        id: '1',
        title: 'Test Challenge',
      );
      expect(challenge.id, equals('1'));
    });
  });
}
```

---

## 📚 参考資料

- [Flutter 公式ドキュメント](https://flutter.dev/docs)
- [Dart スタイルガイド](https://dart.dev/guides/language/effective-dart/style)
- [このプロジェクトの README](README.md)
- [開発者ガイド](docs/DEVELOPMENT.md)

---

## 🙏 貢献のお礼

すべての貢献者は以下で紹介されます：

- GitHub contributors ページ
- README の contributors セクション

---

## ❓ 質問がある場合

1. **[Discussions](https://github.com/zka32101/shogaku-kore-programming/discussions)** で質問
2. **Issue** で相談
3. または既存の **Issue/PR** にコメント

---

## 🙌 ご協力ありがとうございます！

皆さんの貢献により、「小学コレ！プログラミング」はより良くなります。

Happy Contributing! 🚀
