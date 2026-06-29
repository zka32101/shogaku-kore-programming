import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// AI プログラミング習得コーチサービス
class AIProgrammingCoachService {
  static final AIProgrammingCoachService _instance =
      AIProgrammingCoachService._internal();

  factory AIProgrammingCoachService() {
    return _instance;
  }

  AIProgrammingCoachService._internal();

  final String _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  final String _apiUrl = 'https://api.anthropic.com/v1/messages';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// プログラミング問題の解説・ティップス
  Future<String> explainProgrammingConcept({
    required String conceptName,
    required String questionContext,
    required String difficulty, // '初級', '中級', '上級'
  }) async {
    if (!isConfigured) return 'API キーが設定されていません。';

    try {
      final prompt = '''プログラミング教育の専門家として、小学生向けに説明します。

**概念**: $conceptName
**レベル**: $difficulty
**問題**: $questionContext

1. 簡潔な説明（何なのか）
2. 実生活での例え
3. このレベルでのポイント
4. 次へのステップ

3-4文で、わかりやすく、最後に絵文字を付けてください。''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-haiku-20241022',
          'max_tokens': 300,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return (content[0]['text'] as String? ?? '').trim();
        }
      }

      return '説明の生成に失敗しました。';
    } catch (e) {
      return 'エラー: $e';
    }
  }

  /// バグ修正・デバッグのヒント
  Future<String> getDebugHint({
    required String codeSnippet,
    required String expectedBehavior,
    required String actualBehavior,
  }) async {
    if (!isConfigured) return 'API キーが設定されていません。';

    try {
      final prompt = '''プログラミングのバグ修正アドバイザーです。小学生向けに。

**コード:**
$codeSnippet

**期待される動き:** $expectedBehavior
**実際の動き:** $actualBehavior

3-4文で、何が問題で、どう直すかを日本語で説明してください。答え直接ではなくヒントで。最後に絵文字。''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-haiku-20241022',
          'max_tokens': 250,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return (content[0]['text'] as String? ?? '').trim();
        }
      }

      return 'ヒントの生成に失敗しました。';
    } catch (e) {
      return 'エラー: $e';
    }
  }

  /// 学習進捗に基づくニクスト学習推奨
  Future<String> getNextLearningPath({
    required int completedLevel,
    required List<String> masterTopics,
    required List<String> struggleTopics,
    required int totalScore,
  }) async {
    if (!isConfigured) return 'API キーが設定されていません。';

    try {
      final topics = masterTopics.join('、');
      final struggles = struggleTopics.join('、');

      final prompt = '''プログラミング学習パスの設計者です。小学生向けに。

**現在**: レベル$completedLevel
**得意**: $topics
**苦手**: $struggles
**スコア**: $totalScore点

次のステップを3-4文で提案してください：
1. 今すぐやること（得意を伸ばす）
2. 近い将来（苦手を克服）
3. 学習のコツ

小学生向け、実行可能、モチベーション高く。最後に絵文字。''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-haiku-20241022',
          'max_tokens': 280,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return (content[0]['text'] as String? ?? '').trim();
        }
      }

      return '学習パスの提案に失敗しました。';
    } catch (e) {
      return 'エラー: $e';
    }
  }

  /// 逆転モード：子どもの説明を評価
  Future<String> evaluateStudentExplanation({
    required String topic,
    required String studentExplanation,
    required String difficulty,
  }) async {
    if (!isConfigured) return 'API キーが設定されていません。';

    try {
      final prompt = '''プログラミング教育の評価者です。小学生の説明を評価します。

**テーマ**: $topic
**難易度**: $difficulty
**子どもの説明**: "$studentExplanation"

以下を含めて日本語で評価してください：
1. 説明が正しいか（○ならその理由、✗なら何が違うか）
2. いいところ（褒める）
3. 改善案（あれば）

2-3文で、小学生向けに励ましながら。最後に絵文字。''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-haiku-20241022',
          'max_tokens': 200,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return (content[0]['text'] as String? ?? '').trim();
        }
      }

      return '評価の生成に失敗しました。';
    } catch (e) {
      return 'エラー: $e';
    }
  }

  /// 日替わり詰め問生成
  Future<Map<String, dynamic>> generateDailyPuzzle({
    required String difficulty, // '初級', '中級', '上級'
    required int dayNumber,     // 日番号（日替わり性のシード）
  }) async {
    if (!isConfigured) {
      return {'error': 'API キーが設定されていません。'};
    }

    try {
      final prompt = '''プログラミング詰め将棋の出題者です。小学生向け。

難易度: $difficulty
日番号: $dayNumber

「最小手数でゴールに到達するコードを書く」という1問を、以下の形式で日本語で出してください：

**問題文:**
（何をするコードか、わかりやすく）

**初期コード:**
```
...（タブor行番号付きで）
```

**目標:**
（実行結果）

**制約:**
（最小手数など）

**ヒント:**
（1つ）

必ず JSON で以下構造で返してください：
{
  "title": "問題のタイトル",
  "description": "問題文",
  "initialCode": "初期コード",
  "goalBehavior": "目標結果",
  "constraint": "制約",
  "hint": "ヒント"
}''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-haiku-20241022',
          'max_tokens': 400,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['content'] as List?;
        if (content != null && content.isNotEmpty) {
          final text = (content[0]['text'] as String? ?? '').trim();
          try {
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
            if (jsonMatch != null) {
              return jsonDecode(jsonMatch.group(0)!);
            }
          } catch (_) {}
          return {'title': '詰め問', 'description': text};
        }
      }

      return {'error': '詰め問の生成に失敗しました。'};
    } catch (e) {
      return {'error': 'エラー: $e'};
    }
  }

  /// 週次レポート生成（保護者向け）
  Future<String> generateWeeklyReport({
    required String childName,
    required int completedThisWeek,
    required int totalCompleted,
    required List<String> strongTopics,
    required List<String> weakTopics,
    required int currentLevel,
    required int streakDays,
  }) async {
    if (!isConfigured) return 'API キーが設定されていません。';

    try {
      final strong = strongTopics.isNotEmpty ? strongTopics.join('、') : 'まだデータがありません';
      final weak = weakTopics.isNotEmpty ? weakTopics.join('、') : '特に課題はありません';

      final prompt = '''保護者向けの学習レポート手紙を作成してください。小学生の親が読むことを想定します。

**お子さんの学習データ（今週）:**
- 名前: $childName
- 完了ステージ数: $completedThisWeek/週
- 累計完了: $totalCompleted ステージ
- 現在レベル: $currentLevel
- 学習ストリーク: $streakDays 日継続
- 得意分野: $strong
- 苦手分野: $weak

以下の形式で手紙を作成してください：
1. 導入（お子さんの頑張りを褒める）
2. 今週の成果（具体的な数字と内容）
3. 得意分野・成長した点
4. 課題・改善提案（得意分野の継続 + 苦手分野への取り組み方）
5. 親からのアドバイス提案（日常での声かけ例）
6. 締め（励ましと期待）

親しみやすく、かつ教育的で、実行可能なアドバイスを含めてください。400-500字程度。''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-haiku-20241022',
          'max_tokens': 600,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return (content[0]['text'] as String? ?? '').trim();
        }
      }

      return 'レポート生成に失敗しました。';
    } catch (e) {
      return 'エラー: $e';
    }
  }
}
