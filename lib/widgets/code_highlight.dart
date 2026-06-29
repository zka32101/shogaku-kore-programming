import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/profile_provider.dart';

/// Python コードスニペットをシンタックスハイライト付きで表示するウィジェット
/// ピンチでズームイン/アウト可能（minScale: 0.8, maxScale: 3.0）
/// フォントサイズはプロフィール設定（codeFontSize）に従う
/// showLineNumbers: true でガター付き行番号を表示
class CodeHighlightWidget extends ConsumerWidget {
  final String code;
  /// 明示的なフォントサイズ指定（null の場合は profileProvider から取得）
  final double? fontSize;
  final bool showLineNumbers;

  const CodeHighlightWidget({
    super.key,
    required this.code,
    this.fontSize,
    this.showLineNumbers = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final effectiveFontSize = fontSize ?? ref.watch(profileProvider).codeFontSize;

    // ダークモードでは atom-one-dark、ライトでは atom-one-light
    Map<String, TextStyle> theme;
    final Color gutterBg;
    final Color gutterFg;
    final Color gutterBorder;
    if (isDark) {
      theme = Map<String, TextStyle>.from(atomOneDarkTheme);
      theme['root'] = const TextStyle(
        backgroundColor: Color(0xFF1E1E2E),
        color: Color(0xFFCDD6F4),
      );
      gutterBg = const Color(0xFF181825);
      gutterFg = const Color(0xFF6C7086);
      gutterBorder = const Color(0xFF313244);
    } else {
      theme = Map<String, TextStyle>.from(atomOneLightTheme);
      theme['root'] = const TextStyle(
        backgroundColor: Color(0xFFF8F8FC),
        color: Color(0xFF383A42),
      );
      gutterBg = const Color(0xFFEEEEF4);
      gutterFg = const Color(0xFF9DA5B4);
      gutterBorder = const Color(0xFFDDDDE8);
    }

    final highlightView = HighlightView(
      code,
      language: 'python',
      theme: theme,
      padding: EdgeInsets.fromLTRB(
        showLineNumbers ? 10 : 14,
        14,
        14,
        14,
      ),
      textStyle: TextStyle(
        fontSize: effectiveFontSize,
        fontFamily: 'monospace',
        height: 1.6,
      ),
    );

    Widget content;
    if (showLineNumbers) {
      final lineCount = '\n'.allMatches(code).length + 1;
      final gutterWidth = lineCount >= 100
          ? 44.0
          : lineCount >= 10
              ? 36.0
              : 28.0;

      content = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 行番号ガター
              Container(
                width: gutterWidth,
                color: gutterBg,
                padding: EdgeInsets.only(top: 14, bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(lineCount, (i) {
                    return Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: effectiveFontSize,
                        fontFamily: 'monospace',
                        height: 1.6,
                        color: gutterFg,
                      ),
                    );
                  }),
                ),
              ),
              // ガターとコードの境界線
              Container(width: 1, color: gutterBorder),
              // シンタックスハイライトされたコード
              Expanded(child: highlightView),
            ],
          ),
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: highlightView,
      );
    }

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 3.0,
      constrained: true,
      child: content,
    );
  }
}
