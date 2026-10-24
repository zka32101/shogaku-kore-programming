import 'package:flutter/material.dart';

import '../config/theme.dart';

/// バグハンター用のコード表示。各行をタップして「バグのある行」を選ぶ。
///
/// 回答前は選んだ行を強調し、回答後は正解の行（🐛）と、まちがえて選んだ行を色で示す。
class BugHuntCodeView extends StatelessWidget {
  final List<String> lines;
  final int? selectedIndex;
  final bool answered;
  final int correctIndex;
  final ValueChanged<int> onSelect;

  const BugHuntCodeView({
    super.key,
    required this.lines,
    required this.selectedIndex,
    required this.answered,
    required this.correctIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: context.subCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) _line(context, i),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, int i) {
    final isSelected = selectedIndex == i;
    final isBug = answered && i == correctIndex;
    final isWrong = answered && isSelected && i != correctIndex;

    Color? bg;
    Color border = Colors.transparent;
    if (isBug) {
      bg = kPrimaryColor.withValues(alpha: 0.15);
      border = kPrimaryColor;
    } else if (isWrong) {
      bg = Colors.red.withValues(alpha: 0.12);
      border = Colors.red;
    } else if (isSelected) {
      bg = Colors.orange.withValues(alpha: 0.18);
      border = Colors.orange;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${i + 1}行目 ${lines[i]}',
      child: InkWell(
        key: Key('bugLine_$i'),
        onTap: answered ? null : () => onSelect(i),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${i + 1}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lines[i].isEmpty ? ' ' : lines[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: context.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              if (isBug) const Text('🐛', style: TextStyle(fontSize: 16)),
              if (isWrong) const Text('✖', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}
