# クイックスタートガイド 🚀

**このガイドに従えば、5 分でアプリを起動できます。**

---

## ⏱️ 所要時間: 5 分

---

## 📋 前提条件

以下がインストールされていることを確認してください：

- **Flutter 3.13 以上**
  ```bash
  flutter --version
  ```

- **Dart SDK 3.11.5 以上**
  ```bash
  dart --version
  ```

- **iOS または Android デバイス/エミュレータ**

---

## 🎯 ステップ 1: リポジトリをクローン

```bash
git clone https://github.com/zka32101/shogaku-kore-programming.git
cd shogaku-kore-programming
```

---

## 📦 ステップ 2: 依存関係をインストール

```bash
flutter pub get
```

💡 **何が起こっているの？**
- Flutter が必要なパッケージをダウンロード
- iOS/Android ビルドファイルが準備される

---

## 🍎 ステップ 3a: iOS でテスト（Mac のみ）

```bash
# iOS の依存関係をインストール
cd ios
pod install
cd ..

# iPhone エミュレータで実行
flutter run -d iPhone

# または物理 iPhone で実行
flutter run
```

---

## 🤖 ステップ 3b: Android でテスト

```bash
# Android エミュレータを起動（Android Studio が必要）
emulator -avd <device_name>

# または物理 Android デバイスを USB 接続

# アプリを実行
flutter run
```

---

## ✅ 完了！

ターミナルに以下のメッセージが出れば成功です：

```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

スマートフォンに「小学コレ！プログラミング」が表示されます。 🎉

---

## 🆘 うまくいかない場合

### **エラー: `flutter: command not found`**

```bash
# Flutter がインストールされていません
# 公式ガイドに従いインストール:
# https://flutter.dev/docs/get-started/install
```

### **エラー: `Gradle build failed`（Android）**

```bash
flutter clean
flutter pub get
flutter run
```

### **エラー: `CocoaPods install failed`（iOS）**

```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run
```

### **エラー: `Firebase authentication error`**

以下を確認してください：
- インターネット接続の確認
- `.env` ファイルが存在するか
- Firebase 認証情報が正しいか

詳細は [FIREBASE_SETUP.md](FIREBASE_SETUP.md) をご覧ください。

---

## 📚 次のステップ

### 初回起動時

- ✅ アカウント作成（Firebase 認証）
- ✅ プロフィール設定
- ✅ Stage 1 のチュートリアルをプレイ

### 開発に参加したい場合

→ [開発者ガイド](DEVELOPMENT.md) をご覧ください

### バグを発見した場合

→ [GitHub Issues](https://github.com/zka32101/shogaku-kore-programming/issues) で報告してください

---

## 💡 よくある質問（FAQ）

### Q: 「iOS のみ」で開発したい

```bash
flutter run -d iPhone
```

### Q: 「Android のみ」で開発したい

```bash
flutter run -d android
```

### Q: Web でテストしたい

```bash
flutter run -d chrome
```

### Q: デバッグログを見たい

```bash
flutter run -v
```

### Q: ホットリロードはどうやるの？

実行中に `r` キーを押すと、コード変更がリアルタイム反映されます。

### Q: ホット再起動は？

実行中に `R` キーを押すと、アプリが再起動されます。

---

## 🎓 学習リソース

- [Flutter 公式ドキュメント](https://flutter.dev/docs)
- [Dart 言語ガイド](https://dart.dev/guides)
- [Riverpod 状態管理](https://riverpod.dev)

---

## 🎉 Happy Coding!

質問がある場合は [Discussions](https://github.com/zka32101/shogaku-kore-programming/discussions) で気軽に聞いてください。
