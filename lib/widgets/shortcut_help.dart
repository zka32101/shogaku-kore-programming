import 'package:flutter/material.dart';

/// キーボードショートカット表示行
class ShortcutRow extends StatelessWidget {
  final String shortcut;
  final String desc;
  const ShortcutRow({super.key, required this.shortcut, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// キーボードショートカットヘルプダイアログを表示する
void showShortcutsHelpDialog(
  BuildContext context, {
  required List<(String, String)> shortcuts,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard, size: 20),
          SizedBox(width: 8),
          Text('キーボードショートカット', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: shortcuts
              .map((s) => ShortcutRow(shortcut: s.$1, desc: s.$2))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
