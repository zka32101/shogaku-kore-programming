import 'package:flutter/material.dart';
import '../config/theme.dart';

/// バグハンター版コード表示ウィジェット
/// 各行をクリック可能にして、ユーザーがバグを選択
class BugHunterCodeDisplay extends StatefulWidget {
  final String buggyCode; // わざと壊されたコード
  final List<int> bugLineNumbers; // 正解のバグ行（0-indexed）
  final int bugCount; // ヒント用：バグの総数
  final Function(List<int>) onBugSelect; // ユーザーが選んだバグ行を報告
  final bool showHint; // ヒント「バグが◎個あるよ」を表示するか
  final String? feedbackMessage; // フィードバックメッセージ
  final bool revealed; // true になるまで正解/不正解の色分けは表示しない

  const BugHunterCodeDisplay({
    super.key,
    required this.buggyCode,
    required this.bugLineNumbers,
    required this.bugCount,
    required this.onBugSelect,
    this.showHint = true,
    this.feedbackMessage,
    this.revealed = false,
  });

  @override
  State<BugHunterCodeDisplay> createState() => _BugHunterCodeDisplayState();
}

class _BugHunterCodeDisplayState extends State<BugHunterCodeDisplay> {
  late List<int> _selectedLines; // ユーザーが選んだ行番号

  @override
  void initState() {
    super.initState();
    _selectedLines = [];
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.buggyCode.split('\n');
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヒント表示
        if (widget.showHint) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
              border: Border.all(color: kPrimaryColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  '💡',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'このコードにはバグが${widget.bugCount}個あります。'
                    'バグがある行をタップして選びましょう！',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // コード表示
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor, width: 1),
            borderRadius: BorderRadius.circular(8),
            color: context.subCardBg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < lines.length; i++)
                _buildCodeLine(
                  context: context,
                  lineNumber: i,
                  code: lines[i],
                  isSelected: _selectedLines.contains(i),
                  isBugLine: widget.bugLineNumbers.contains(i),
                ),
            ],
          ),
        ),

        // 選択状態表示
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
            border: Border.all(color: Colors.amber[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '選択中: ${_selectedLines.length}個 / ${widget.bugCount}個',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.amber[200] : Colors.amber[900],
                ),
              ),
              const SizedBox(width: 12),
              if (_selectedLines.length == widget.bugCount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '✓ 完成！',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // フィードバックメッセージ
        if (widget.feedbackMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
              border: Border.all(color: Colors.blue[300]!, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.feedbackMessage!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.blue[200] : Colors.blue[800],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCodeLine({
    required BuildContext context,
    required int lineNumber,
    required String code,
    required bool isSelected,
    required bool isBugLine,
  }) {
    // revealed になるまでは正解/不正解を出さず、選択中かどうかだけ見せる
    final isDark = context.isDark;
    final isCorrectSelected = widget.revealed && isSelected && isBugLine;
    final isIncorrectSelected = widget.revealed && isSelected && !isBugLine;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_selectedLines.contains(lineNumber)) {
              _selectedLines.remove(lineNumber);
            } else {
              _selectedLines.add(lineNumber);
            }
          });
          widget.onBugSelect(_selectedLines);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          color: isCorrectSelected
              ? Colors.green.withValues(alpha: isDark ? 0.25 : 0.15)
              : isIncorrectSelected
                  ? Colors.red.withValues(alpha: isDark ? 0.25 : 0.15)
                  : isSelected
                      ? kPrimaryColor.withValues(alpha: isDark ? 0.2 : 0.1)
                      : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 行番号
              SizedBox(
                width: 30,
                child: Text(
                  '${lineNumber + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              // チェックボックスのような表示
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : context.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: isSelected ? kPrimaryColor : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),

              const SizedBox(width: 8),

              // コード
              Expanded(
                child: Text(
                  code.isEmpty ? '(空行)' : code,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isIncorrectSelected
                        ? (isDark ? Colors.red[200] : Colors.red[700])
                        : context.textPrimary,
                    decoration: isCorrectSelected
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: Colors.green,
                    decorationThickness: 2,
                  ),
                ),
              ),

              // 正解マークまたはエラーマーク（revealed後のみ）
              if (isCorrectSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                )
              else if (isIncorrectSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
