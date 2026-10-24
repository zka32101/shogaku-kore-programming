import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show LessonMenuPage;

import '../data/explain_images.dart';
import '../data/lesson_data.dart';
import '../providers/lesson_provider.dart';

/// 「学ぶ」画面。shared_core の LessonMenuPage をラップし、
/// 表示時にこのアプリの解説記事一覧（kLessons）を読み込む。
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lessonProvider.notifier).load(kLessons);
    });
  }

  @override
  Widget build(BuildContext context) {
    final withImages = [
      for (final l in kLessons)
        if (explainImageForLesson(l.id) != null) l,
    ];
    return Column(
      children: [
        const Expanded(child: LessonMenuPage(lessons: kLessons)),
        if (withImages.isNotEmpty)
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: withImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final path = explainImageForLesson(withImages[i].id)!;
                    return GestureDetector(
                      key: ValueKey('explain_thumb_${withImages[i].id}'),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => Dialog(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              path,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          path,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
