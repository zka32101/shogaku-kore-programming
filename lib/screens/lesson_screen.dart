import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../data/lesson_data.dart';

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
    return const LessonMenuPage(lessons: kLessons);
  }
}
