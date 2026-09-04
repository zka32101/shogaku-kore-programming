# Firebase Configuration Setup

このドキュメントでは、小学コレプログラムの Firebase 設定を環境変数で管理する方法を説明します。

## Overview

Firebase 認証情報（APIキー、プロジェクトID等）は**ソースコードに平文で保存してはいけません**。このプロジェクトでは以下の方法で環境変数として管理しています：

- **ローカル開発**: `.env` ファイル
- **GitHub Actions CI/CD**: Repository Secrets

---

## Local Development Setup

### Step 1: .env ファイルを作成

```bash
cp .env.example .env
```

### Step 2: Firebase Console から認証情報を取得

1. [Firebase Console](https://console.firebase.google.com) にログイン
2. プロジェクト「petit-works-education」を開く
3. Project Settings > General タブから以下を確認：
   - **Project ID**: `petit-works-education`
   - **Web API Key**: `AIzaSy...` で始まる値
   - **Messaging Sender ID**: `492221061005`

4. Messaging > Cloud Messaging タブから：
   - **Sender ID**: Messaging Sender ID と同じ値

5. Storage タブから：
   - **Storage Bucket**: `petit-works-education.firebasestorage.app`

### Step 3: .env ファイルに入力

```env
# Firebase Console から取得した値を入力
FIREBASE_API_KEY=AIzaSy...（Web API Key）
FIREBASE_WEB_APP_ID=1:492221061005:web:xxx
FIREBASE_ANDROID_APP_ID=1:492221061005:android:xxx
FIREBASE_IOS_APP_ID=1:492221061005:ios:xxx
FIREBASE_MESSAGING_SENDER_ID=492221061005
FIREBASE_PROJECT_ID=petit-works-education
FIREBASE_STORAGE_BUCKET=petit-works-education.firebasestorage.app
FIREBASE_IOS_BUNDLE_ID=com.schoolcode.programming
```

### Step 4: .env ファイルが自動読み込みされることを確認

```bash
flutter run
# main.dart が flutter_dotenv を初期化していることを確認
```

---

## GitHub Actions CI/CD Setup

### Step 1: Repository Secrets を設定

GitHub リポジトリ設定から Secrets を追加：

1. Settings > Secrets and variables > Actions
2. 「New repository secret」をクリック
3. 以下の Secrets を追加：

| Secret Name | Value |
|---|---|
| `FIREBASE_API_KEY` | Firebase Console から取得 |
| `FIREBASE_WEB_APP_ID` | `1:492221061005:web:xxx` |
| `FIREBASE_ANDROID_APP_ID` | `1:492221061005:android:xxx` |
| `FIREBASE_IOS_APP_ID` | `1:492221061005:ios:xxx` |
| `FIREBASE_MESSAGING_SENDER_ID` | `492221061005` |
| `FIREBASE_PROJECT_ID` | `petit-works-education` |
| `FIREBASE_STORAGE_BUCKET` | `petit-works-education.firebasestorage.app` |
| `FIREBASE_IOS_BUNDLE_ID` | `com.schoolcode.programming` |

### Step 2: GitHub Actions ワークフローで環境変数を設定

`.github/workflows/build.yml` でビルド時に以下の方式で環境変数を注入：

**方式 A: 環境変数として直接渡す**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
      FIREBASE_PROJECT_ID: ${{ secrets.FIREBASE_PROJECT_ID }}
      # ... other variables
    steps:
      - uses: actions/checkout@v4
      - name: Build Release APK
        run: flutter build apk --release
```

**方式 B: Dart define フラグで渡す** (推奨)
```yaml
      - name: Build Release APK
        run: |
          flutter build apk --release \
            --dart-define=FIREBASE_API_KEY=${{ secrets.FIREBASE_API_KEY }} \
            --dart-define=FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}
```

### Step 3: Build Args から環境変数を読み込む (Optional)

`lib/main.dart` で以下のように Dart define を読み込むことも可能：

```dart
const apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
```

ただし、このプロジェクトでは `flutter_dotenv` を使用しているため、通常は不要です。

---

## Security Best Practices

✅ **DO:**
- .env ファイルを .gitignore に追加済み ✓
- 環境変数はコミット前に削除確認
- GitHub Actions Secrets を使用
- ローカル開発時のみ .env を使用

❌ **DON'T:**
- Firebase API キーをソースコードにハードコードしない
- .env ファイルをリポジトリにコミットしない
- Secrets をログ出力しない
- 共有マシンでの .env ファイル管理

---

## Troubleshooting

### エラー: "Missing environment variable: FIREBASE_API_KEY"

**原因**: flutter_dotenv が .env ファイルを見つけていない

**解決**:
```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
flutter run
```

### エラー: Firebase 初期化に失敗

**原因**: API キーが間違っているか、Firebase Console の設定ミス

**解決**:
1. Firebase Console で API キーを再確認
2. .env ファイルの値をコピペ確認
3. `flutter run` で詳細ログを確認

### エラー: GitHub Actions でビルド失敗

**原因**: Secrets が正しく設定されていない

**解決**:
1. Settings > Secrets の値が正しいか確認
2. ワークフロー YAML で `${{ secrets.XXX }}` が正しいか確認
3. `secrets.env` でローカルテスト

---

## References

- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [Flutter dotenv Package](https://pub.dev/packages/flutter_dotenv)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [OWASP: Secrets Management](https://owasp.org/www-community/vulnerabilities/Sensitive_Data_Exposure)
