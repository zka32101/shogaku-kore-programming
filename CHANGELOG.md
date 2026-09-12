# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-09-12

### 📱 Phase 4.23 ローカル通知・リマインダーシステム統合

#### 新機能
- **ローカル通知・リマインダー** 🔔
  - ReminderService による毎日のリマインダー機能
  - NotificationBadge ウィジェット（未読通知数表示）
  - Firebase Cloud Messaging 連携
  - 学習リマインダー・週次ボーナス通知

- **shared_core 統一ゲーミフィケーション** 🎮
  - 全7アプリでバッジシステム統一（60+個の共通バッジ）
  - キャラクターシステム統一（16体キャラクター）
  - マルチアプリランキング・フレンド機能対応
  - 週次ボーナスシステム（7日連続達成で500コイン）
  - グローバルランキング機能（複数タブ表示対応）

#### 改善
- 通知システムの安定化・最適化
- shared_core との依存関係統合
- 全ブランチでのテスト検証完了

### 既知の問題
- なし

## [0.1.0] - 2026-09-01

### 初期リリース
- 基本的なプログラミング学習クイズ機能
- ビジュアルプログラミングエディタ
- ゲーミフィケーション統合
- RevenueCat サブスク対応
- AdMob 広告システム統合
