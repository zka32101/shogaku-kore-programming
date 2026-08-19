import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/wrong_answers_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/time_attack_provider.dart';
import '../providers/daily_review_provider.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../services/haptic_service.dart';
import 'profile_screen.dart';
import 'paywall_screen.dart';
import 'parent_dashboard_screen.dart';
import 'flashcard_screen.dart' show kFlashcards;
import '../widgets/shortcut_help.dart';
import '../widgets/app_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyP) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyU) {
      _navigateToPaywall(context);
      return KeyEventResult.handled;
    }
    // Esc / Backspace → 戻る
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('P', 'プロフィール'),
        ('D', '保護者ダッシュボード'),
        ('U', 'プレミアムプランへ'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final progressNotifier = ref.read(progressProvider.notifier);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
      body: Column(
        children: [
          // ヘッダー
          _buildHeader(context, profile, progressNotifier),
          // 設定リスト
          Expanded(
            child: ListView(
              children: [
                // ─── アカウント ──────────────────────────────
                Column(
                  children: [
                    const _SectionHeader(title: 'アカウント'),
                    _ProfileTile(profile: profile),
                    const _Divider(),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),

                // ─── プレミアム ──────────────────────────────
                Column(
                  children: [
                    const _SectionHeader(title: 'プレミアム'),
                    _SettingsTile(
                      icon: '⭐',
                      iconBg: const Color(0xFFFFF8E1),
                      title: 'プレミアムプラン',
                      subtitle: '月額 ¥999 / 年額 ¥5,980 — 全ステージ解放',
                      onTap: () => _navigateToPaywall(context),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kPrimaryColor, kPrimaryDark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '登録する',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const _Divider(),
                  ],
                ).animate(delay: 60.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),

                // ─── 表示 ──────────────────────────────────
                Column(
                  children: [
                    const _SectionHeader(title: '表示'),
                    _ThemeModeTile(current: profile.themeMode),
                    _CodeFontSizeTile(current: profile.codeFontSize),
                    const _Divider(),
                  ],
                ).animate(delay: 120.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),

                // ─── 学習 ────────────────────────────────────
                Column(
                  children: [
                    const _SectionHeader(title: '学習'),
                    _DailyGoalTile(current: profile.dailyGoal),
                    _ReviewQuestionCountTile(current: profile.reviewQuestionCount),
                    _FlashcardSessionSizeTile(current: profile.flashcardSessionSize),
                    _FlashcardAutoFlipTile(current: profile.flashcardAutoFlipSecs),
                    _SwitchTile(
                      icon: '⚡',
                      iconBg: const Color(0xFFFFF3E0),
                      title: '正解後に自動で次へ進む',
                      subtitle: '正解すると1.2秒後に自動で次の問題へ',
                      value: profile.autoAdvanceEnabled,
                      onChanged: (v) {
                        ref.read(profileProvider.notifier).setAutoAdvanceEnabled(v);
                        HapticService.selectionClick();
                      },
                    ),
                    _SwitchTile(
                      icon: '⏱',
                      iconBg: const Color(0xFFE8F5E9),
                      title: 'クイズタイマー',
                      subtitle: 'オフにすると制限時間なしで挑戦できます',
                      value: profile.quizTimerEnabled,
                      onChanged: (v) {
                        ref.read(profileProvider.notifier).setQuizTimerEnabled(v);
                        HapticService.selectionClick();
                      },
                    ),
                    if (profile.quizTimerEnabled)
                      _QuizTimerSecondsTile(current: profile.quizTimerSeconds),
                    const _Divider(),
                  ],
                ).animate(delay: 150.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),

                // ─── サウンド・通知 ──────────────────────────
                Column(
                  children: [
                    const _SectionHeader(title: 'サウンド・通知'),
                    _SwitchTile(
                      icon: '🔊',
                      iconBg: const Color(0xFFE3F2FD),
                      title: '効果音',
                      subtitle: '正解・不正解などの音',
                      value: profile.soundEnabled,
                      onChanged: (v) {
                        ref.read(profileProvider.notifier).setSoundEnabled(v);
                        SoundService().setEnabled(v);
                        if (v) SoundService().playTap();
                      },
                    ),
                    _SwitchTile(
                      icon: '📳',
                      iconBg: const Color(0xFFE8EAF6),
                      title: 'バイブレーション',
                      subtitle: 'タップ・回答時の振動フィードバック',
                      value: profile.hapticsEnabled,
                      onChanged: (v) {
                        ref.read(profileProvider.notifier).setHapticsEnabled(v);
                        if (v) HapticService.selectionClick();
                      },
                    ),
                    _SwitchTile(
                      icon: '🔔',
                      iconBg: const Color(0xFFF3E5F5),
                      title: '学習リマインダー',
                      subtitle: '毎日の学習通知',
                      value: profile.notificationsEnabled,
                      onChanged: (v) async {
                        if (v) {
                          final granted = await NotificationService().requestPermission();
                          if (granted) {
                            ref.read(profileProvider.notifier).setNotificationsEnabled(true);
                            await NotificationService().scheduleDailyReminder(
                              hour: profile.reminderHour,
                              minute: profile.reminderMinute,
                              enabled: true,
                            );
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('通知の許可が必要です。端末の設定から許可してください。')),
                              );
                            }
                          }
                        } else {
                          ref.read(profileProvider.notifier).setNotificationsEnabled(false);
                          await NotificationService().cancelAll();
                        }
                      },
                    ),
                    if (profile.notificationsEnabled) ...[
                      _ReminderTimeTile(profile: profile),
                      _SwitchTile(
                        icon: '📊',
                        iconBg: const Color(0xFFE8F5E9),
                        title: '週次レポート',
                        subtitle: '毎週月曜朝8時に学習サマリーを通知',
                        value: profile.weeklyReportEnabled,
                        onChanged: (v) async {
                          ref.read(profileProvider.notifier).setWeeklyReportEnabled(v);
                          await NotificationService().scheduleWeeklyReport(
                            hour: 8,
                            minute: 0,
                            enabled: v,
                          );
                        },
                      ),
                      _SwitchTile(
                        icon: '🌙',
                        iconBg: const Color(0xFFEDE7F6),
                        title: '夕方ナッジ',
                        subtitle: '学習を忘れそうな夜に追加リマインダー',
                        value: profile.eveningNudgeEnabled,
                        onChanged: (v) async {
                          ref.read(profileProvider.notifier).setEveningNudgeEnabled(v);
                          await NotificationService().scheduleEveningNudge(
                            hour: profile.eveningNudgeHour,
                            minute: profile.eveningNudgeMinute,
                            enabled: v,
                          );
                        },
                      ),
                      if (profile.eveningNudgeEnabled)
                        _EveningNudgeTimeTile(profile: profile),
                      _SwitchTile(
                        icon: '🔥',
                        iconBg: const Color(0xFFFBE9E7),
                        title: '苦手問題リマインダー',
                        subtitle: '苦手問題がある日に毎日の通知時間と同じ時刻で追加通知',
                        value: profile.wrongAnswerReminderEnabled,
                        onChanged: (v) async {
                          ref.read(profileProvider.notifier).setWrongAnswerReminderEnabled(v);
                          final wrongCount = ref.read(wrongAnswersProvider).count;
                          await NotificationService().scheduleWrongAnswerReminder(
                            hour: profile.reminderHour,
                            minute: profile.reminderMinute,
                            wrongCount: wrongCount,
                            enabled: v,
                          );
                        },
                      ),
                      // テスト通知ボタン
                      _SettingsTile(
                        icon: '🔔',
                        iconBg: const Color(0xFFFFF8E1),
                        title: 'テスト通知を送る',
                        subtitle: '通知が届くか確認できます（5秒後）',
                        onTap: () async {
                          HapticService.lightImpact();
                          await NotificationService().sendTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔔 5秒後にテスト通知が届きます'),
                                duration: Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    const _Divider(),
                  ],
                ).animate(delay: 180.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),

                // ─── 保護者メニュー ──────────────────────────
                Column(
                  children: [
                    const _SectionHeader(title: '保護者メニュー'),
                    _SettingsTile(
                      icon: '👨‍👩‍👧',
                      iconBg: const Color(0xFFE8F5E9),
                      title: '保護者ダッシュボード',
                      subtitle: '学習進捗・ユニット別成績・アドバイス',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ParentDashboardScreen()),
                      ),
                    ),
                    const _Divider(),
                  ],
                ).animate(delay: 240.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),

                // ─── アプリについて ──────────────────────────
                Column(
                  children: [
                    const _SectionHeader(title: 'アプリについて'),
                    _SettingsTile(
                      icon: '📱',
                      title: 'バージョン',
                      subtitle: '1.0.0 (ビルド 1)',
                      onTap: null,
                    ),
                    _SettingsTile(
                      icon: '📋',
                      title: 'プライバシーポリシー',
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    _SettingsTile(
                      icon: '📄',
                      title: '利用規約',
                      onTap: () => _showTermsOfService(context),
                    ),
                    _SettingsTile(
                      icon: '💬',
                      title: 'お問い合わせ',
                      onTap: () => _showContact(context),
                    ),
                    const _Divider(),
                  ],
                ).animate(delay: 300.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),

                // ─── データ ─────────────────────────────────
                Column(
                  children: [
                    const _SectionHeader(title: 'データ'),
                    _SettingsTile(
                      icon: '📤',
                      iconBg: const Color(0xFFE3F2FD),
                      title: '学習データをエクスポート',
                      subtitle: 'クリップボードに進捗サマリーをコピー',
                      onTap: () {
                        final notifier = ref.read(progressProvider.notifier);
                        final p = ref.read(profileProvider);
                        final wrongCount = ref.read(wrongAnswersProvider).count;
                        final masteredCount = ref.read(flashcardProvider).masteredIds.length;
                        final taState = ref.read(timeAttackProvider);
                        final reviewStreak = ref.read(dailyReviewProvider).reviewStreak;
                        final now = DateTime.now();
                        final dateStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
                        final taLine = taState.playCount > 0
                            ? 'タイムアタック: ベスト ${taState.bestScore}pt (${taState.playCount}回プレイ)\n'
                            : '';
                        final reviewLine = reviewStreak > 0
                            ? '今日の復習: $reviewStreak 日連続\n'
                            : '';
                        final masteredLine = masteredCount > 0
                            ? 'フラッシュカード習得: $masteredCount / ${kFlashcards.length} 枚\n'
                            : '';
                        final wrongLine = wrongCount > 0
                            ? '苦手問題: $wrongCount 件\n'
                            : '';
                        final favCount = ref.read(favoritesProvider).count;
                        final favLine = favCount > 0
                            ? 'お気に入り: $favCount 件\n'
                            : '';
                        final totalSeconds = notifier.totalLearningSeconds;
                        final totalMinutes = totalSeconds ~/ 60;
                        final timeLine = totalSeconds > 0
                            ? '累計学習時間: ${totalMinutes >= 60 ? '${totalMinutes ~/ 60}時間${totalMinutes % 60}分' : '$totalMinutes分'}\n'
                            : '';
                        final text =
                            '【しょうがくプログラミング 学習記録】\n'
                            '日付: $dateStr\n'
                            'ニックネーム: ${p.nickname}\n'
                            'レベル: ${notifier.currentLevel}\n'
                            'クリア数: ${notifier.completedCount} / ${AppConstants.totalStages} ステージ\n'
                            '獲得ポイント: ${notifier.totalStarsEarned} pt\n'
                            '回答数: ${notifier.totalQuestionsAnswered} 問\n'
                            '$timeLine'
                            '連続学習: ${notifier.streakDays} 日（最長: ${notifier.longestStreak} 日）\n'
                            '$reviewLine'
                            '$wrongLine'
                            '$favLine'
                            '$masteredLine'
                            '$taLine'
                            '---\n'
                            'しょうがくプログラミングでコーディングを学習中！🔥';
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📋 学習データをクリップボードにコピーしました！'),
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: '📝',
                      title: '苦手問題リストをクリア',
                      subtitle: '苦手リストを全て削除（クイズ進捗は維持）',
                      textColor: Colors.orange.shade700,
                      onTap: () => _confirmWrongAnswersClear(context),
                    ),
                    _SettingsTile(
                      icon: '🃏',
                      title: 'フラッシュカード習得をリセット',
                      subtitle: '習得マーク・メモを削除（クイズ進捗は維持）',
                      textColor: Colors.orange,
                      onTap: () => _confirmFlashcardReset(context),
                    ),
                    _SettingsTile(
                      icon: '🗑️',
                      title: '学習データをリセット',
                      subtitle: '全ての進捗・ストリークを削除',
                      textColor: Colors.red,
                      onTap: () => _confirmReset(context),
                    ),
                  ],
                ).animate(delay: 360.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    ),   // closes Scaffold (child of Focus)
  );     // closes Focus return
  }

  Widget _buildHeader(
    BuildContext context,
    ProfileState profile,
    ProgressNotifier notifier,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryDark],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      child: Row(
        children: [
          // アバター
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  profile.avatarEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nickname,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Lv.${notifier.currentLevel} · ${notifier.completedCount} / ${AppConstants.totalStages} クリア · ⭐ ${notifier.totalStarsEarned} · 🔥 ${notifier.streakDays}日',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String title, List<_InfoSection> sections) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: sections.map((s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.heading != null) ...[
                      Text(
                        s.heading!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      s.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showInfoSheet(context, '📋 プライバシーポリシー', [
      _InfoSection(
        heading: '1. 収集する情報',
        body: '本アプリは、お子様の学習進捗（クリアしたステージ・獲得スター・連続学習日数）をお使いの端末内にのみ保存します。氏名・メールアドレス・位置情報などの個人情報は一切収集しません。',
      ),
      _InfoSection(
        heading: '2. データの利用目的',
        body: '保存されたデータは学習履歴の表示・バッジの付与・ランキング計算など、アプリ内機能の提供にのみ使用します。外部サーバーへの送信や第三者への提供は行いません。',
      ),
      _InfoSection(
        heading: '3. 子供のプライバシー保護',
        body: '本アプリは小学生を対象としています。13歳未満のお子様の個人情報を意図的に収集することはありません。保護者の方はいつでも設定画面からデータをリセットできます。',
      ),
      _InfoSection(
        heading: '4. データの保管',
        body: 'すべてのデータはお使いの端末内（SharedPreferences）に暗号化されて保存されます。アプリを削除すると全データが消去されます。',
      ),
      _InfoSection(
        heading: '5. お問い合わせ',
        body: 'プライバシーポリシーに関するご質問は、設定画面のお問い合わせよりご連絡ください。',
      ),
      _InfoSection(
        body: '最終更新日: 2025年1月',
      ),
    ]);
  }

  void _showTermsOfService(BuildContext context) {
    _showInfoSheet(context, '📄 利用規約', [
      _InfoSection(
        heading: '1. サービスの目的',
        body: '本アプリ「小学コレ！プログラミング」は、小学生がプログラミングの基礎を楽しく学ぶことを目的とした教育アプリです。',
      ),
      _InfoSection(
        heading: '2. 利用対象',
        body: '本アプリは主に小学生（6〜12歳）を対象としています。保護者の同意のもとでご利用ください。',
      ),
      _InfoSection(
        heading: '3. 課金について',
        body: 'アプリ内購入（プレミアムプラン）は保護者のクレジットカードでのお支払いとなります。課金前に内容をよくご確認ください。購入後のキャンセル・返金はApp Store / Google Playの規定に従います。',
      ),
      _InfoSection(
        heading: '4. 禁止事項',
        body: 'アプリのリバースエンジニアリング・不正アクセス・営利目的での無断使用を禁止します。',
      ),
      _InfoSection(
        heading: '5. 免責事項',
        body: '本アプリの利用により生じたいかなる損害についても、開発者は責任を負いません。また、コンテンツの正確性について最善を尽くしていますが、教育的完全性を保証するものではありません。',
      ),
      _InfoSection(
        heading: '6. 規約の変更',
        body: '本規約はアプリのアップデートに伴い変更される場合があります。重要な変更がある場合はアプリ内でお知らせします。',
      ),
      _InfoSection(
        body: '最終更新日: 2025年1月',
      ),
    ]);
  }

  void _showContact(BuildContext context) {
    _showInfoSheet(context, '💬 お問い合わせ', [
      _InfoSection(
        heading: 'バグ報告・機能リクエスト',
        body: 'アプリのバグや改善要望は、App Store / Google Playのレビュー欄、またはメール（support@petit-studio.jp）にてお知らせください。',
      ),
      _InfoSection(
        heading: '学習内容について',
        body: 'クイズの問題や解説の誤りを発見した場合は、ぜひご連絡ください。内容改善に役立てます。',
      ),
      _InfoSection(
        heading: '保護者の方へ',
        body: 'お子様の利用に関するご心配やご不明点がございましたら、お気軽にお問い合わせください。お子様が安全・安心に学習できる環境づくりを大切にしています。',
      ),
      _InfoSection(
        heading: '返信について',
        body: 'お問い合わせへの返信には数日いただく場合があります。あらかじめご了承ください。',
      ),
    ]);
  }

  Future<void> _confirmWrongAnswersClear(BuildContext context) async {
    final wrongCount = ref.read(wrongAnswersProvider).count;
    if (wrongCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📝 苦手リストは空です'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await AppDialog.danger(
      context,
      emoji: '📝',
      title: '苦手リストをクリアする？',
      message: '$wrongCount件の苦手問題を全て削除します。\nクイズの進捗は変わらないよ。',
      okLabel: 'クリアする',
    );
    if (!confirmed || !context.mounted) return;
    ref.read(wrongAnswersProvider.notifier).clearAll();
    ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
      const SnackBar(
        content: Text('📝 苦手リストをクリアしました'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmFlashcardReset(BuildContext context) async {
    final masteredCount = ref.read(flashcardProvider).masteredIds.length;
    if (masteredCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🃏 習得済みカードがありません'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await AppDialog.danger(
      context,
      emoji: '🃏',
      title: 'フラッシュカードをリセット？',
      message: '習得マーク（$masteredCount枚）とメモを全て削除します。\nクイズの進捗は変わらないよ。',
      okLabel: 'リセットする',
    );
    if (!confirmed || !context.mounted) return;
    ref.read(flashcardProvider.notifier).resetAll();
    ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
      const SnackBar(
        content: Text('🃏 フラッシュカードをリセットしました'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final passedGate = await _showParentalGate(context);
    if (!passedGate || !context.mounted) return;
    final confirmed = await AppDialog.danger(
      context,
      emoji: '⚠️',
      title: '全データを削除する？',
      message: '学習データ・ストリーク・スターが全て消えます。\nこの操作はもとに戻せません！',
      okLabel: '全て削除する',
    );
    if (!confirmed || !context.mounted) return;
    ref.read(progressProvider.notifier).resetAll();
    ref.read(flashcardProvider.notifier).resetAll();
    ref.read(wrongAnswersProvider.notifier).clearAll();
    ref.read(favoritesProvider.notifier).clearAll();
    ref.read(timeAttackProvider.notifier).resetAll();
    ref.read(dailyReviewProvider.notifier).resetAll();
    // 週次レポート送信済みフラグもリセット
    SharedPreferences.getInstance().then(
      (p) => p.remove('notif_weekly_report_sent_week'),
    );
    ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
      const SnackBar(
        content: Text('🗑️ 学習データをリセットしました'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// プレミアムプラン画面へ移動する前に、保護者ゲートを通す。
  /// ゲートを通過（正解）した場合のみ [PaywallScreen] へ遷移する。
  Future<void> _navigateToPaywall(BuildContext context) async {
    final passedGate = await _showParentalGate(context);
    if (!passedGate || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  /// 保護者ゲート: 簡単な足し算に正解した場合のみ true を返す。
  /// 子どもが誤って課金・データ全削除などの重要操作に進まないようにするための
  /// 軽量チェック。キャンセル・不正解の場合は false（何もしない）。
  Future<bool> _showParentalGate(BuildContext context) async {
    final random = math.Random();
    final a = 10 + random.nextInt(21); // 10〜30
    final b = 10 + random.nextInt(21); // 10〜30
    final correctAnswer = a + b;
    final controller = TextEditingController();
    bool showError = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🔒', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '保護者の方へ確認',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'これは大人の方が行う操作です。\n下の計算の答えを入力してください。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF666666)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$a + $b = ?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '答えを入力',
                        errorText: showError ? '答えが違います' : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) {
                        final input = int.tryParse(controller.text.trim());
                        if (input == correctAnswer) {
                          Navigator.pop(ctx, true);
                        } else {
                          setState(() => showError = true);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'やめる',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final input = int.tryParse(controller.text.trim());
                              if (input == correctAnswer) {
                                Navigator.pop(ctx, true);
                              } else {
                                setState(() => showError = true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'つぎへ',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    return result ?? false;
  }
}

// ─── 共通ウィジェット ──────────────────────────────────────────────────────────

class _ProfileTile extends ConsumerWidget {
  final ProfileState profile;
  const _ProfileTile({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
      title: Text(
        profile.nickname,
        style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
      ),
      subtitle: const Text(
        'ニックネーム・アバターを変更',
        style: TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: kTextSecondary),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String icon;
  final Color? iconBg;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    this.iconBg,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? (iconBg ?? kPrimaryColor).withValues(alpha: 0.15)
              : (iconBg ?? kPrimaryColor.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: kTextSecondary))
          : null,
      trailing: Switch(
        value: value,
        onChanged: (v) {
          HapticService.lightImpact();
          onChanged(v);
        },
        activeThumbColor: kPrimaryColor,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String icon;
  final Color? iconBg;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    this.iconBg,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? (iconBg ?? kPrimaryColor).withValues(alpha: 0.15)
              : (iconBg ?? kPrimaryColor.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor ?? context.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: kTextSecondary))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: kTextSecondary)
              : null),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: kTextSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}

class _ThemeModeTile extends ConsumerWidget {
  final String current;
  const _ThemeModeTile({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = [
      (AppThemeMode.system, 'システム', Icons.brightness_auto),
      (AppThemeMode.light, 'ライト', Icons.light_mode_outlined),
      (AppThemeMode.dark, 'ダーク', Icons.dark_mode_outlined),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF27AE60).withValues(alpha: 0.15)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🎨', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        'テーマ',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: const Text(
        '外観モードを選択',
        style: TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: SegmentedButton<String>(
        segments: options
            .map((o) => ButtonSegment<String>(
                  value: o.$1,
                  icon: Icon(o.$3, size: 16),
                  label: Text(o.$2, style: const TextStyle(fontSize: 11)),
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (s) {
          ref.read(profileProvider.notifier).setThemeMode(s.first);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 4)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _CodeFontSizeTile extends ConsumerWidget {
  final double current;
  const _CodeFontSizeTile({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 小=11, 中=13, 大=16
    final options = <(double, String)>[
      (11.0, '小'),
      (13.0, '中'),
      (16.0, '大'),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF2980B9).withValues(alpha: 0.15)
              : const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🔠', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        'コードの文字サイズ',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: const Text(
        'コードスニペットの表示サイズ',
        style: TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: SegmentedButton<double>(
        segments: options
            .map((o) => ButtonSegment<double>(
                  value: o.$1,
                  label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (s) {
          HapticService.selectionClick();
          ref.read(profileProvider.notifier).setCodeFontSize(s.first);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 8)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _ReminderTimeTile extends ConsumerWidget {
  final ProfileState profile;
  const _ReminderTimeTile({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = profile.reminderHour;
    final minute = profile.reminderMinute;
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF9B59B6).withValues(alpha: 0.15)
              : const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            const Center(child: Text('⏰', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        '通知時刻',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: Text(
        '毎日 $timeStr に通知',
        style: const TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: Text(
        timeStr,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          helpText: '通知する時刻を選んでください',
        );
        if (picked != null) {
          ref.read(profileProvider.notifier).setReminderTime(
                picked.hour,
                picked.minute,
              );
          if (profile.notificationsEnabled) {
            await NotificationService().scheduleDailyReminder(
              hour: picked.hour,
              minute: picked.minute,
              enabled: true,
            );
            if (profile.wrongAnswerReminderEnabled) {
              final wrongCount = ref.read(wrongAnswersProvider).count;
              await NotificationService().scheduleWrongAnswerReminder(
                hour: picked.hour,
                minute: picked.minute,
                wrongCount: wrongCount,
                enabled: true,
              );
            }
          }
        }
      },
    );
  }
}

class _EveningNudgeTimeTile extends ConsumerWidget {
  final ProfileState profile;
  const _EveningNudgeTimeTile({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = profile.eveningNudgeHour;
    final minute = profile.eveningNudgeMinute;
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF9B59B6).withValues(alpha: 0.15)
              : const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🌙', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        'ナッジ時刻',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: Text(
        '毎日 $timeStr に通知',
        style: const TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: Text(
        timeStr,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          helpText: 'ナッジ通知の時刻を選んでください',
        );
        if (picked != null) {
          ref.read(profileProvider.notifier).setEveningNudgeTime(
                picked.hour,
                picked.minute,
              );
          if (profile.eveningNudgeEnabled) {
            await NotificationService().scheduleEveningNudge(
              hour: picked.hour,
              minute: picked.minute,
              enabled: true,
            );
          }
        }
      },
    );
  }
}

class _InfoSection {
  final String? heading;
  final String body;
  const _InfoSection({this.heading, required this.body});
}

class _ReviewQuestionCountTile extends ConsumerWidget {
  final int current;
  const _ReviewQuestionCountTile({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const counts = [3, 5, 10];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF1A3A2A)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('📖', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        '今日の復習の問題数',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: Text(
        '1回の復習セッションで $current 問出題',
        style: const TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: SegmentedButton<int>(
        segments: counts
            .map((c) => ButtonSegment<int>(
                  value: c,
                  label: Text('$c', style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (s) {
          HapticService.lightImpact();
          ref.read(profileProvider.notifier).setReviewQuestionCount(s.first);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 6)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _FlashcardSessionSizeTile extends ConsumerWidget {
  final int current;
  const _FlashcardSessionSizeTile({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const sizes = [5, 10, 15, 20];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF1A2A3A)
              : const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🃏', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        'カードセッション枚数',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: Text(
        '1回のセッションで $current 枚出題',
        style: const TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: SegmentedButton<int>(
        segments: sizes
            .map((s) => ButtonSegment<int>(
                  value: s,
                  label: Text('$s', style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (s) {
          HapticService.lightImpact();
          ref.read(profileProvider.notifier).setFlashcardSessionSize(s.first);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 6)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _FlashcardAutoFlipTile extends ConsumerWidget {
  final int current;
  const _FlashcardAutoFlipTile({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const options = [3, 5, 10];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF2A1A3A)
              : const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('⏱', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        '自動めくり間隔',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: Text(
        '$current秒後に自動でカードを裏返す',
        style: const TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: SegmentedButton<int>(
        segments: options
            .map((s) => ButtonSegment<int>(
                  value: s,
                  label: Text('$s秒', style: const TextStyle(fontSize: 12)),
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (s) {
          HapticService.lightImpact();
          ref.read(profileProvider.notifier).setFlashcardAutoFlipSecs(s.first);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 4)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _DailyGoalTile extends ConsumerWidget {
  final int current;
  const _DailyGoalTile({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const goals = [1, 3, 5];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? kPrimaryColor.withValues(alpha: 0.15)
              : kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🎯', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        '1日の目標ステージ数',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: Text(
        '1日に $current ステージのクリアを目指す',
        style: const TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: SegmentedButton<int>(
        segments: goals
            .map((g) => ButtonSegment<int>(
                  value: g,
                  label: Text('$g', style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (s) {
          HapticService.lightImpact();
          ref.read(profileProvider.notifier).setDailyGoal(s.first);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 6)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _QuizTimerSecondsTile extends ConsumerWidget {
  final int current;
  const _QuizTimerSecondsTile({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const options = [30, 45, 60, 90];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF1A2A1A)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('⏳', style: TextStyle(fontSize: 18))),
      ),
      title: Text(
        '1問あたりの制限時間',
        style: TextStyle(fontWeight: FontWeight.w500, color: context.textPrimary),
      ),
      subtitle: Text(
        '$current秒で回答しよう',
        style: const TextStyle(fontSize: 12, color: kTextSecondary),
      ),
      trailing: SegmentedButton<int>(
        segments: options
            .map((s) => ButtonSegment<int>(
                  value: s,
                  label: Text('$s秒', style: const TextStyle(fontSize: 11)),
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (s) {
          HapticService.lightImpact();
          ref.read(profileProvider.notifier).setQuizTimerSeconds(s.first);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 3)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
