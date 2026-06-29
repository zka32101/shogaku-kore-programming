import 'package:flutter/material.dart';
import '../config/theme.dart';

/// アプリ全体で統一されたダイアログヘルパー。
///
/// 小学生向けUX:
/// - 大きな絵文字ヘッダー
/// - 角丸 24px
/// - やさしい日本語ボタンラベル
/// - 危険操作は赤ボタン
///
/// 使い方:
/// ```dart
/// final ok = await AppDialog.confirm(
///   context,
///   emoji: '⚠️',
///   title: 'やめる？',
///   message: '進捗は保存されません。',
///   okLabel: 'やめる',
///   danger: true,
/// );
/// ```
class AppDialog {
  AppDialog._();

  // ─── 確認ダイアログ ───────────────────────────────────────────

  /// 確認ダイアログを表示する。
  /// [danger] = true のとき OK ボタンを赤で表示。
  /// キャンセルで false、OK で true を返す。
  static Future<bool> confirm(
    BuildContext context, {
    required String emoji,
    required String title,
    required String message,
    String okLabel = 'はい',
    String cancelLabel = 'やめる',
    bool danger = false,
    Color? okColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AppDialogWidget(
        emoji: emoji,
        title: title,
        message: message,
        actions: [
          _DialogButton(
            label: cancelLabel,
            onTap: () => Navigator.pop(ctx, false),
            outlined: true,
          ),
          _DialogButton(
            label: okLabel,
            onTap: () => Navigator.pop(ctx, true),
            color: danger
                ? Colors.red
                : (okColor ?? kPrimaryColor),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── 情報ダイアログ ───────────────────────────────────────────

  /// 情報表示ダイアログ（OK ボタンのみ）。
  static Future<void> info(
    BuildContext context, {
    required String emoji,
    required String title,
    required String message,
    String okLabel = 'わかった！',
    Color? color,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AppDialogWidget(
        emoji: emoji,
        title: title,
        message: message,
        actions: [
          _DialogButton(
            label: okLabel,
            onTap: () => Navigator.pop(ctx),
            color: color ?? kPrimaryColor,
          ),
        ],
      ),
    );
  }

  // ─── 危険操作確認（2段階テキスト入力確認は省略し単純ダブルボタン）───

  /// 危険な操作（データリセット等）用の確認ダイアログ。
  /// 赤ボタン + 強調警告メッセージ付き。
  static Future<bool> danger(
    BuildContext context, {
    required String emoji,
    required String title,
    required String message,
    String okLabel = '削除する',
    String cancelLabel = 'やめる',
  }) {
    return confirm(
      context,
      emoji: emoji,
      title: title,
      message: message,
      okLabel: okLabel,
      cancelLabel: cancelLabel,
      danger: true,
    );
  }
}

// ─── 内部ウィジェット ─────────────────────────────────────────────

class _AppDialogWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final List<_DialogButton> actions;

  const _AppDialogWidget({
    required this.emoji,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 絵文字ヘッダー
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            // タイトル
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // メッセージ
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // ボタン行（1〜2個）
            if (actions.length == 1)
              SizedBox(
                width: double.infinity,
                child: _buildButton(actions.first),
              )
            else
              Row(
                children: <Widget>[
                  Expanded(child: _buildButton(actions[0])),
                  const SizedBox(width: 12),
                  Expanded(child: _buildButton(actions[1])),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(_DialogButton btn) {
    if (btn.outlined) {
      return OutlinedButton(
        onPressed: btn.onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          btn.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }
    return ElevatedButton(
      onPressed: btn.onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: btn.color ?? kPrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        btn.label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DialogButton {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool outlined;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.color,
    this.outlined = false,
  });
}
