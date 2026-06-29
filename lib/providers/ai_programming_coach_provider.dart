import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_programming_coach_service.dart';

class AIProgrammingCoachResponse {
  final String? content;
  final bool isLoading;
  final String? error;
  final DateTime? generatedAt;
  final String? coachType; // 'concept' | 'debug' | 'learning_path'

  const AIProgrammingCoachResponse({
    this.content,
    this.isLoading = false,
    this.error,
    this.generatedAt,
    this.coachType,
  });

  AIProgrammingCoachResponse copyWith({
    String? content,
    bool? isLoading,
    String? error,
    DateTime? generatedAt,
    String? coachType,
  }) {
    return AIProgrammingCoachResponse(
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      generatedAt: generatedAt ?? this.generatedAt,
      coachType: coachType ?? this.coachType,
    );
  }

  bool get isEmpty => content == null || content!.isEmpty;
  bool get hasError => error != null && error!.isNotEmpty;
}

class AIProgrammingCoachNotifier
    extends StateNotifier<AIProgrammingCoachResponse> {
  final AIProgrammingCoachService _service = AIProgrammingCoachService();

  AIProgrammingCoachNotifier() : super(const AIProgrammingCoachResponse());

  /// 概念説明を生成
  Future<void> explainConcept({
    required String conceptName,
    required String questionContext,
    required String difficulty,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final explanation = await _service.explainProgrammingConcept(
        conceptName: conceptName,
        questionContext: questionContext,
        difficulty: difficulty,
      );
      state = AIProgrammingCoachResponse(
        content: explanation,
        coachType: 'concept',
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'エラー: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// デバッグヒントを生成
  Future<void> getDebugHint({
    required String codeSnippet,
    required String expectedBehavior,
    required String actualBehavior,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final hint = await _service.getDebugHint(
        codeSnippet: codeSnippet,
        expectedBehavior: expectedBehavior,
        actualBehavior: actualBehavior,
      );
      state = AIProgrammingCoachResponse(
        content: hint,
        coachType: 'debug',
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'エラー: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// 次の学習パスを提案
  Future<void> getNextLearningPath({
    required int completedLevel,
    required List<String> masterTopics,
    required List<String> struggleTopics,
    required int totalScore,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = await _service.getNextLearningPath(
        completedLevel: completedLevel,
        masterTopics: masterTopics,
        struggleTopics: struggleTopics,
        totalScore: totalScore,
      );
      state = AIProgrammingCoachResponse(
        content: path,
        coachType: 'learning_path',
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'エラー: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  void clearResponse() {
    state = const AIProgrammingCoachResponse();
  }
}

final aiProgrammingCoachProvider = StateNotifierProvider<
    AIProgrammingCoachNotifier,
    AIProgrammingCoachResponse>(
  (ref) => AIProgrammingCoachNotifier(),
);
