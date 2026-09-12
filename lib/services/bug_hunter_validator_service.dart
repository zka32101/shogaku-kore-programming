import 'package:flutter/foundation.dart';

/// バグハンターの回答判定と進捗管理
class BugHunterValidatorService {
  /// ユーザが選んだバグ行が正解か判定
  /// 完全一致をチェック（順序不問だが全て選ぶ必要あり）
  static bool validateBugFix({
    required List<int> selectedLines,
    required List<int> correctLines,
  }) {
    return setEquals(
      Set<int>.from(selectedLines),
      Set<int>.from(correctLines),
    );
  }

  /// 部分正解の進捗（「あと✕個」表示用）
  static int getRemainingBugCount({
    required List<int> selectedLines,
    required List<int> correctLines,
  }) {
    final found = selectedLines
        .where((line) => correctLines.contains(line))
        .length;
    return correctLines.length - found;
  }

  /// 選択したバグ数が正解数と一致するか（順序は問わない）
  static bool hasSelectedCorrectCount({
    required List<int> selectedLines,
    required int correctBugCount,
  }) {
    return selectedLines.length == correctBugCount;
  }

  /// 誤検出されたバグ行（正解ではないのに選ばれたもの）
  static List<int> getFalsePositiveBugs({
    required List<int> selectedLines,
    required List<int> correctLines,
  }) {
    return selectedLines
        .where((line) => !correctLines.contains(line))
        .toList();
  }

  /// 見逃されたバグ行
  static List<int> getMissedBugs({
    required List<int> selectedLines,
    required List<int> correctLines,
  }) {
    return correctLines
        .where((line) => !selectedLines.contains(line))
        .toList();
  }

  /// バグハンター版の難度レベル判定
  /// 一発正解でボーナス★を追加
  static int calculateStarBonus({
    required bool isFirstAttempt,
    required bool isCompleteCorrect,
    required int bugCount,
  }) {
    if (isFirstAttempt && isCompleteCorrect && bugCount >= 2) {
      return 1; // ボーナス星
    }
    return 0;
  }

  /// フィードバックメッセージ生成
  static String generateFeedback({
    required bool isCorrect,
    required int selectedCount,
    required int correctCount,
    required List<int> falsePositives,
    required List<int> missed,
  }) {
    if (isCorrect) {
      if (selectedCount == 1) {
        return '✅ バグを正しく特定しました！';
      } else {
        return '✅ すべてのバグを見つけました！素晴らしい！';
      }
    }

    final buffer = StringBuffer();
    if (falsePositives.isNotEmpty) {
      buffer.write('⚠️ ${falsePositives.length}行は実はバグじゃないよ。');
    }
    if (missed.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('🔍 まだ${missed.length}個のバグが残っています。');
    }
    if (selectedCount == 0) {
      return '💭 どの行がバグか、タップして選んでみてください。';
    }

    return buffer.toString();
  }
}
