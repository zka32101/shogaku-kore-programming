import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI レスポンスダイアログ - AIの回答を表示
class AIResponseDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final bool isLoading;
  final String? error;
  final VoidCallback? onDismiss;

  const AIResponseDialog({
    super.key,
    this.title,
    this.content,
    this.isLoading = false,
    this.error,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title != null
          ? Text(title!)
          : const Text('AI アシスタント'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('考え中...'),
              ] else if (error != null && error!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ] else if (content != null && content!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  content!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('まだ応答がありません'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

/// AI レスポンス用ボトムシート表示ウィジェット
void showAIResponseBottomSheet(
  BuildContext context, {
  required String title,
  required String? content,
  required bool isLoading,
  required String? error,
}) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Center(child: Text('考え中...')),
            ] else if (error != null && error.isNotEmpty) ...[
              Text(
                error,
                style: const TextStyle(color: Colors.red),
              ),
            ] else if (content != null && content.isNotEmpty) ...[
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ] else ...[
              const Text('まだ応答がありません'),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
