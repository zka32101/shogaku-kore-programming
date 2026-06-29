import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../widgets/code_highlight.dart';
import '../services/sound_service.dart';
import '../providers/flashcard_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/shortcut_help.dart';
import 'badge_unlock_screen.dart';

// ─── データモデル ──────────────────────────────────────────────────────────────

class Flashcard {
  final String id;
  final String front;    // 表面: キーワード・質問
  final String back;     // 裏面: 説明
  final String? code;    // コード例（任意）
  final String category; // カテゴリ

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.code,
    required this.category,
  });
}

// ─── フラッシュカードデータプール ─────────────────────────────────────────────

const List<Flashcard> kFlashcards = [
  Flashcard(
    id: 'fc_01',
    front: 'print()',
    back: '画面にテキストを表示する関数',
    code: 'print("こんにちは！")\nprint(42)',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_02',
    front: '変数 (variable)',
    back: 'データを入れておく箱。「=」で値を代入する',
    code: 'name = "たろう"\nage = 10',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_03',
    front: 'if 文',
    back: '条件が True のときだけ処理を実行する',
    code: 'if score >= 60:\n    print("合格！")',
    category: '制御',
  ),
  Flashcard(
    id: 'fc_04',
    front: 'elif / else',
    back: 'if の後に追加条件・それ以外の処理を書く',
    code: 'if x > 0:\n    print("正")\nelif x == 0:\n    print("零")\nelse:\n    print("負")',
    category: '制御',
  ),
  Flashcard(
    id: 'fc_05',
    front: 'for ループ',
    back: 'リストや range() の要素を1つずつ処理する',
    code: 'for i in range(5):\n    print(i)',
    category: '制御',
  ),
  Flashcard(
    id: 'fc_06',
    front: 'while ループ',
    back: '条件が True の間、繰り返し処理を続ける',
    code: 'count = 0\nwhile count < 3:\n    print(count)\n    count += 1',
    category: '制御',
  ),
  Flashcard(
    id: 'fc_07',
    front: 'range()',
    back: '連続した整数のシーケンスを生成する',
    code: 'range(5)      # 0,1,2,3,4\nrange(1, 6)   # 1,2,3,4,5\nrange(0,10,2) # 0,2,4,6,8',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_08',
    front: 'def (関数定義)',
    back: '繰り返し使う処理をまとめる。def 名前(): で定義',
    code: 'def greet(name):\n    print("こんにちは、" + name)\n\ngreet("花子")',
    category: '関数',
  ),
  Flashcard(
    id: 'fc_09',
    front: 'return',
    back: '関数から値を返す。呼び出し元に結果を渡す',
    code: 'def double(n):\n    return n * 2\n\nresult = double(5)  # 10',
    category: '関数',
  ),
  Flashcard(
    id: 'fc_10',
    front: 'リスト (list)',
    back: '複数の値をまとめて管理できる。[ ] で作る',
    code: 'fruits = ["りんご", "バナナ"]\nfruits[0]  # "りんご"',
    category: 'データ',
  ),
  Flashcard(
    id: 'fc_11',
    front: 'list.append()',
    back: 'リストの末尾に要素を追加する',
    code: 'nums = [1, 2]\nnums.append(3)\n# [1, 2, 3]',
    category: 'データ',
  ),
  Flashcard(
    id: 'fc_12',
    front: 'len()',
    back: 'リストや文字列の長さ（要素数）を返す',
    code: 'len([1, 2, 3])   # 3\nlen("こんにちは")    # 5',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_13',
    front: '辞書 (dict)',
    back: 'キーと値のペアでデータを管理する。{ } で作る',
    code: 'person = {"名前": "太郎", "年齢": 10}\nperson["名前"]  # "太郎"',
    category: 'データ',
  ),
  Flashcard(
    id: 'fc_14',
    front: 'f-string',
    back: '変数を文字列に埋め込む便利な書き方',
    code: 'name = "太郎"\nprint(f"こんにちは、{name}！")',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_15',
    front: 'import',
    back: 'ライブラリ（モジュール）を読み込んで使えるようにする',
    code: 'import math\nprint(math.pi)  # 3.14159...',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_16',
    front: 'str() / int() / float()',
    back: 'データの型を変換する関数',
    code: 'str(42)      # "42"\nint("10")    # 10\nfloat("3.14") # 3.14',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_17',
    front: 'break / continue',
    back: 'break: ループを中断。continue: 次の繰り返しにスキップ',
    code: 'for i in range(10):\n    if i == 5:\n        break  # 5で終了',
    category: '制御',
  ),
  Flashcard(
    id: 'fc_18',
    front: 'class (クラス)',
    back: 'オブジェクトの設計図。属性とメソッドをまとめる',
    code: 'class Dog:\n    def __init__(self, name):\n        self.name = name\n\nd = Dog("ポチ")',
    category: 'クラス',
  ),
  Flashcard(
    id: 'fc_19',
    front: '== と =',
    back: '「=」は代入、「==」は比較（等しいか確認）',
    code: 'x = 10        # 代入\nx == 10       # True（比較）\nx == 5        # False',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_20',
    front: 'コメント (#)',
    back: '「#」から行末はコメント。プログラムに影響しない',
    code: '# これはコメントです\nx = 5  # 変数に5を代入',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_21',
    front: 'リスト内包表記',
    back: 'ループと条件をワンライナーでリストを生成する書き方',
    code: '[x*2 for x in range(5)]\n# [0, 2, 4, 6, 8]\n[x for x in range(10) if x % 2 == 0]\n# [0, 2, 4, 6, 8]',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_22',
    front: 'lambda (無名関数)',
    back: '名前をつけずに簡単な関数を作る。1行で書ける',
    code: 'double = lambda x: x * 2\ndouble(5)  # 10\nadd = lambda a, b: a + b',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_23',
    front: 'try / except',
    back: 'エラーが起きそうな処理を try で囲み、except で対処する',
    code: 'try:\n    x = int("abc")\nexcept ValueError:\n    print("変換できない！")',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_24',
    front: 'with 文',
    back: 'リソース（ファイルなど）を安全に開いて自動で閉じる',
    code: 'with open("file.txt", "r") as f:\n    content = f.read()',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_25',
    front: 'タプル (tuple)',
    back: '変更できないリスト。( ) で作る。定数データに使う',
    code: 'point = (10, 20)\npoint[0]   # 10\n# point[0] = 5  # エラー！',
    category: 'データ',
  ),
  Flashcard(
    id: 'fc_26',
    front: 'セット (set)',
    back: '重複なしのデータ集合。{ } または set() で作る',
    code: 's = {1, 2, 3, 2, 1}\n# {1, 2, 3}\ns.add(4)\n1 in s  # True',
    category: 'データ',
  ),
  Flashcard(
    id: 'fc_27',
    front: 'None',
    back: '「何もない」を表す特別な値。関数の戻り値がないときも None',
    code: 'x = None\nif x is None:\n    print("値がない")',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_28',
    front: 'bool (True / False)',
    back: '真偽値。比較演算の結果は bool 型になる',
    code: 'True and False  # False\nTrue or False   # True\nnot True        # False\nbool(0)         # False',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_29',
    front: 'sorted() / sort()',
    back: 'sorted() は新しいリストを返す。sort() はリストを直接並べ替える',
    code: 'nums = [3, 1, 4, 1, 5]\nsorted(nums)        # [1, 1, 3, 4, 5]\nnums.sort(reverse=True)',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_30',
    front: 'map() / filter()',
    back: 'map: 全要素に関数を適用。filter: 条件に合う要素を取り出す',
    code: 'list(map(str, [1,2,3]))    # ["1","2","3"]\nlist(filter(lambda x: x>2, [1,2,3,4]))\n# [3, 4]',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_31',
    front: 'input()',
    back: 'ユーザーからキーボード入力を受け取る関数。結果は文字列になる',
    code: 'name = input("名前を入れてね: ")\nprint(f"こんにちは、{name}！")\n\n# 数値として使いたいときは変換が必要\nage = int(input("年齢: "))',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_32',
    front: 'クラス (class)',
    back: 'データと処理をまとめたオブジェクトの設計図',
    code: 'class Dog:\n    def __init__(self, name):\n        self.name = name\n    def bark(self):\n        print(f"{self.name}：ワン！")',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_33',
    front: '__init__ メソッド',
    back: 'クラスのインスタンスを作るときに自動で呼ばれる初期化メソッド',
    code: 'class Cat:\n    def __init__(self, name, age):\n        self.name = name\n        self.age = age\n\nc = Cat("みけ", 3)',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_34',
    front: 'import / from...import',
    back: 'ライブラリやモジュールを読み込む。fromで特定の関数だけ取得',
    code: 'import math\nprint(math.sqrt(16))  # 4.0\n\nfrom random import randint\nprint(randint(1, 6))',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_35',
    front: 'open() とファイル操作',
    back: 'ファイルを開いて読み書きする。with文で自動的に閉じる',
    code: '# 書き込み\nwith open("data.txt", "w") as f:\n    f.write("こんにちは")\n\n# 読み込み\nwith open("data.txt", "r") as f:\n    text = f.read()',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_36',
    front: 'f文字列 (f-string)',
    back: '変数を{}で埋め込める文字列。f""で始める',
    code: 'name = "たろう"\nage = 10\nprint(f"{name}は{age}歳です")\n# たろうは10歳です',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_37',
    front: 'enumerate()',
    back: 'リストを繰り返すとき、インデックス番号も一緒に取得できる関数',
    code: 'fruits = ["りんご", "バナナ", "みかん"]\nfor i, fruit in enumerate(fruits):\n    print(f"{i}: {fruit}")\n# 0: りんご\n# 1: バナナ\n# 2: みかん',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_38',
    front: 'zip()',
    back: '2つ以上のリストを同時に繰り返す関数。同じ位置の要素をペアにする',
    code: 'names = ["たろう", "はなこ"]\nscores = [90, 85]\nfor name, score in zip(names, scores):\n    print(f"{name}: {score}点")\n# たろう: 90点\n# はなこ: 85点',
    category: '基本',
  ),
  Flashcard(
    id: 'fc_39',
    front: 'isinstance()',
    back: 'オブジェクトが指定した型かどうかを調べる関数',
    code: 'x = 42\nprint(isinstance(x, int))    # True\nprint(isinstance(x, str))    # False\nprint(isinstance(x, (int, float)))  # True',
    category: '応用',
  ),
  Flashcard(
    id: 'fc_40',
    front: 'in 演算子',
    back: 'リストや文字列に値が含まれているか調べる',
    code: 'fruits = ["りんご", "バナナ", "みかん"]\nprint("バナナ" in fruits)   # True\nprint("grape" in "grapefruit")  # True',
    category: '基本',
  ),
];

// ─── フラッシュカードセッション画面 ──────────────────────────────────────────

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

enum _MasteryFilter { all, unmastered, mastered }

enum _SortMode { defaultOrder, masteredDateNew, masteredDateOld, alphabetical }

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with TickerProviderStateMixin {
  // セッションサイズはプロファイル設定から取得（デフォルト10）
  int get _sessionSize => ref.read(profileProvider).flashcardSessionSize;

  // カテゴリフィルター (null = 全カテゴリ)
  String? _selectedCategory;

  // 習得フィルター
  _MasteryFilter _masteryFilter = _MasteryFilter.all;

  // 一覧ソートモード
  _SortMode _sortMode = _SortMode.defaultOrder;

  // 一覧表示モード
  bool _listViewMode = false;

  // 一覧検索クエリ
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late List<Flashcard> _deck;      // 現在のデッキ
  late List<Flashcard> _retryDeck; // 再チャレンジカード
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isRetryRound = false;
  int _correct = 0;
  int _total = 0;
  int _newlyMastered = 0;  // このセッションで新たに習得したカード枚数
  bool _sessionDone = false;

  // フリップアニメーション
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // セッションタイマー
  late DateTime _sessionStart;
  late Timer _sessionTimer;
  int _elapsedSeconds = 0;
  bool _timeRecorded = false;

  // 自動めくりタイマー (設定オンの場合のみ使用)
  Timer? _autoFlipTimer;
  bool _autoFlipEnabled = false;
  // 自動めくり間隔はプロファイル設定から取得（デフォルト5秒）
  int get _autoFlipSeconds => ref.read(profileProvider).flashcardAutoFlipSecs;

  // クイズモード
  bool _quizMode = false;
  int? _quizSelectedIndex;  // 選択した選択肢インデックス
  bool _quizAnswered = false; // 回答済みか
  List<String> _quizChoices = []; // 4択の選択肢（back テキスト）
  int _quizCorrectIndex = 0;      // 正解の位置

  // キーボードショートカット
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _deck = _buildDeck();
    _retryDeck = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleAutoFlip();
      _focusNode.requestFocus();
    });

    // セッション開始時刻・1秒タイマー
    _sessionStart = DateTime.now();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_sessionDone) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_sessionStart).inSeconds;
        });
      }
    });
  }

  List<Flashcard> _buildDeck() {
    final masteredIds = ref.read(flashcardProvider).masteredIds;
    var pool = _selectedCategory == null
        ? List<Flashcard>.from(kFlashcards)
        : kFlashcards.where((c) => c.category == _selectedCategory).toList();

    // 習得フィルター適用
    switch (_masteryFilter) {
      case _MasteryFilter.unmastered:
        pool = pool.where((c) => !masteredIds.contains(c.id)).toList();
        break;
      case _MasteryFilter.mastered:
        pool = pool.where((c) => masteredIds.contains(c.id)).toList();
        break;
      case _MasteryFilter.all:
        break;
    }

    if (pool.isEmpty) return [];
    pool.shuffle(Random());
    return pool.take(_sessionSize).toList();
  }

  /// クイズモード用: 現在カードの4択選択肢を生成してセット
  void _prepareQuizChoices() {
    if (_deck.isEmpty) return;
    final card = _deck[_currentIndex];
    final correct = card.back;
    // 他カードのbackからランダムに最大3つ選ぶ
    final others = kFlashcards
        .where((c) => c.id != card.id && c.back != correct)
        .map((c) => c.back)
        .toList()
      ..shuffle(Random());
    final distractors = others.take(3).toList();
    final choices = [correct, ...distractors]..shuffle(Random());
    _quizChoices = choices;
    _quizCorrectIndex = choices.indexOf(correct);
    _quizSelectedIndex = null;
    _quizAnswered = false;
  }

  /// クイズモードで回答を選択
  void _submitQuizAnswer(int idx) {
    if (_quizAnswered) return;
    final isCorrect = idx == _quizCorrectIndex;
    if (isCorrect) {
      SoundService().playCorrect();
    } else {
      SoundService().playWrong();
    }
    HapticService.mediumImpact();
    setState(() {
      _quizSelectedIndex = idx;
      _quizAnswered = true;
    });
  }

  /// クイズモードで次へ（回答後）
  void _quizNext() {
    if (!_quizAnswered) return;
    final isCorrect = _quizSelectedIndex == _quizCorrectIndex;
    if (isCorrect) {
      final cardId = _deck[_currentIndex].id;
      final wasAlreadyMastered = ref.read(flashcardProvider).masteredIds.contains(cardId);
      ref.read(flashcardProvider.notifier).markMastered(cardId);
      final masteredCount = ref.read(flashcardProvider).masteredIds.length;
      _checkMasteryBadge(masteredCount);
      setState(() {
        _correct++;
        _total++;
        if (!wasAlreadyMastered) _newlyMastered++;
      });
    } else {
      final current = _deck[_currentIndex];
      setState(() {
        _retryDeck.add(current);
        _total++;
      });
    }
    _nextCard();
    if (!_sessionDone) {
      _prepareQuizChoices();
    }
  }

  @override
  void dispose() {
    if (!_timeRecorded) {
      final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
      if (elapsed > 0) {
        ref.read(progressProvider.notifier).recordLearningSeconds(elapsed);
      }
    }
    _flipController.dispose();
    _sessionTimer.cancel();
    _autoFlipTimer?.cancel();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // Esc → 戻る（どの状態でも有効）
    if (key == LogicalKeyboardKey.escape) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }

    // Enter or R → セッション完了後にリスタート
    if (_sessionDone) {
      // S → シェア
      if (key == LogicalKeyboardKey.keyS) {
        _shareResult(context);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.keyR) {
        HapticService.mediumImpact();
        SoundService().playTap();
        _sessionStart = DateTime.now();
        setState(() {
          _deck = _buildDeck();
          _retryDeck = [];
          _currentIndex = 0;
          _isFlipped = false;
          _isRetryRound = false;
          _correct = 0;
          _total = 0;
          _newlyMastered = 0;
          _sessionDone = false;
          _elapsedSeconds = 0;
        });
        _flipController.reset();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // L → 一覧/カードモード切り替え
    if (key == LogicalKeyboardKey.keyL) {
      HapticService.selectionClick();
      setState(() {
        _listViewMode = !_listViewMode;
        if (!_listViewMode) {
          _searchQuery = '';
          _searchController.clear();
        }
      });
      return KeyEventResult.handled;
    }

    // O (Order) → 一覧ソートモードを順送り（一覧モード中のみ）
    if (key == LogicalKeyboardKey.keyO && _listViewMode) {
      HapticService.selectionClick();
      final modes = _SortMode.values;
      final nextMode = modes[(_sortMode.index + 1) % modes.length];
      setState(() => _sortMode = nextMode);
      final label = switch (nextMode) {
        _SortMode.defaultOrder   => 'デフォルト順',
        _SortMode.masteredDateNew => '習得：新しい順',
        _SortMode.masteredDateOld => '習得：古い順',
        _SortMode.alphabetical   => 'あいうえお順',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗂️ 並び順: $label'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return KeyEventResult.handled;
    }

    if (_listViewMode || _deck.isEmpty) return KeyEventResult.ignored;

    // ─── クイズモード専用ショートカット ───
    if (_quizMode && !_sessionDone) {
      // 1-4 or numpad1-4 → 選択肢を選ぶ
      final numKeys = {
        LogicalKeyboardKey.digit1: 0,
        LogicalKeyboardKey.digit2: 1,
        LogicalKeyboardKey.digit3: 2,
        LogicalKeyboardKey.digit4: 3,
        LogicalKeyboardKey.numpad1: 0,
        LogicalKeyboardKey.numpad2: 1,
        LogicalKeyboardKey.numpad3: 2,
        LogicalKeyboardKey.numpad4: 3,
      };
      if (numKeys.containsKey(key)) {
        final idx = numKeys[key]!;
        if (idx < _quizChoices.length) {
          if (!_quizAnswered) {
            setState(() => _quizSelectedIndex = idx);
          }
          return KeyEventResult.handled;
        }
      }
      // Enter / Space → 未回答なら回答確定、回答済みなら次へ
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
        if (_quizAnswered) {
          _quizNext();
        } else if (_quizSelectedIndex != null) {
          _submitQuizAnswer(_quizSelectedIndex!);
        }
        return KeyEventResult.handled;
      }
      // ? → クイズモード用ショートカット一覧
      if (key == LogicalKeyboardKey.slash &&
          HardwareKeyboard.instance.isShiftPressed) {
        showShortcutsHelpDialog(context, shortcuts: const [
          ('1 / 2 / 3 / 4', '選択肢を選ぶ'),
          ('Enter / Space', '回答確定 / 次のカードへ'),
          ('Q', 'クイズモード ON/OFF'),
          ('C', 'カテゴリを順送り'),
          ('L', '一覧/カードモード切り替え'),
          ('Esc', '戻る'),
          ('?', 'このヘルプを表示'),
        ]);
        return KeyEventResult.handled;
      }
      // Q → クイズモード終了
      if (key == LogicalKeyboardKey.keyQ) {
        HapticService.selectionClick();
        setState(() {
          _quizMode = false;
          _deck = _buildDeck();
          _retryDeck = [];
          _currentIndex = 0;
          _isFlipped = false;
          _isRetryRound = false;
          _correct = 0;
          _total = 0;
          _newlyMastered = 0;
          _sessionDone = false;
          _elapsedSeconds = 0;
        });
        _flipController.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🃏 カードモードに戻りました'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // C → カテゴリを順送り
    if (key == LogicalKeyboardKey.keyC) {
      final categories = [null, ...{for (final c in kFlashcards) c.category}];
      final currentIdx = categories.indexOf(_selectedCategory);
      final nextIdx = (currentIdx + 1) % categories.length;
      final nextCategory = categories[nextIdx];
      HapticService.selectionClick();
      _sessionStart = DateTime.now();
      setState(() {
        _selectedCategory = nextCategory;
        _deck = _buildDeck();
        _retryDeck = [];
        _currentIndex = 0;
        _isFlipped = false;
        _isRetryRound = false;
        _correct = 0;
        _total = 0;
        _newlyMastered = 0;
        _elapsedSeconds = 0;
      });
      _flipController.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📚 カテゴリ: ${nextCategory ?? '全て'}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return KeyEventResult.handled;
    }

    // A → 自動めくりのオン/オフ切り替え
    if (key == LogicalKeyboardKey.keyA) {
      HapticService.selectionClick();
      setState(() {
        _autoFlipEnabled = !_autoFlipEnabled;
      });
      if (_autoFlipEnabled) {
        _scheduleAutoFlip();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('自動めくり ON: $_autoFlipSeconds秒後に自動で裏返します'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _autoFlipTimer?.cancel();
      }
      return KeyEventResult.handled;
    }

    // Space or F → カードをめくる
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyF) {
      _flipCard();
      return KeyEventResult.handled;
    }
    // Right arrow or Enter → わかった（正解）
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.enter) {
      if (_isFlipped) _markCorrect();
      return KeyEventResult.handled;
    }
    // Left arrow or Backspace → もう一度（再挑戦）
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.backspace) {
      if (_isFlipped) _markRetry();
      return KeyEventResult.handled;
    }
    // M → 習得済みトグル（カード移動なし）
    if (key == LogicalKeyboardKey.keyM && !_sessionDone) {
      if (_deck.isNotEmpty) {
        HapticService.selectionClick();
        final card = _deck[_currentIndex];
        final isMastered = ref.read(flashcardProvider).masteredIds.contains(card.id);
        if (isMastered) {
          ref.read(flashcardProvider.notifier).unmarkMastered(card.id);
          SoundService().playWrong();
        } else {
          ref.read(flashcardProvider.notifier).markMastered(card.id);
          SoundService().playCorrect();
          _checkMasteryBadge(ref.read(flashcardProvider).masteredIds.length);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMastered ? '📌 習得マークを外しました' : '✅ 習得済みにしました！'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return KeyEventResult.handled;
    }
    // N → メモ編集
    if (key == LogicalKeyboardKey.keyN && !_sessionDone) {
      if (_deck.isNotEmpty) {
        HapticService.lightImpact();
        final card = _deck[_currentIndex];
        final note = ref.read(flashcardProvider).noteFor(card.id) ?? '';
        _showNoteEditor(card, note);
      }
      return KeyEventResult.handled;
    }
    // Q → クイズモード ON/OFF
    if (key == LogicalKeyboardKey.keyQ) {
      HapticService.selectionClick();
      setState(() {
        _quizMode = !_quizMode;
        _deck = _buildDeck();
        _retryDeck = [];
        _currentIndex = 0;
        _isFlipped = false;
        _isRetryRound = false;
        _correct = 0;
        _total = 0;
        _newlyMastered = 0;
        _sessionDone = false;
        _elapsedSeconds = 0;
        if (_quizMode) _prepareQuizChoices();
      });
      _flipController.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_quizMode ? '❓ クイズモード ON: 4択で答えよう！' : '🃏 カードモードに戻りました'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('Space / F', 'カードをめくる'),
        ('→ / Enter', 'わかった（正解）'),
        ('← / Backspace', 'もう一度（再挑戦）'),
        ('M', '習得済みトグル（その場でマーク）'),
        ('N', 'メモを編集'),
        ('C', 'カテゴリを順送り'),
        ('A', '自動めくり ON/OFF'),
        ('Q', 'クイズモード ON/OFF'),
        ('L', '一覧/カードモード切り替え'),
        ('O', '一覧並び順を切り替え（一覧モード）'),
        ('S', 'シェア（結果画面）'),
        ('Esc', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scheduleAutoFlip() {
    _autoFlipTimer?.cancel();
    if (!_autoFlipEnabled || _isFlipped || _sessionDone || _listViewMode) return;
    _autoFlipTimer = Timer(Duration(seconds: _autoFlipSeconds), () {
      if (mounted && !_isFlipped && !_sessionDone) {
        _flipCard();
      }
    });
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    _autoFlipTimer?.cancel();
    SoundService().playTap();
    HapticService.lightImpact();
    if (!_isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _markCorrect() {
    if (!_isFlipped) return; // 裏面を見てから評価
    SoundService().playCorrect();
    HapticService.lightImpact();
    // 習得状態を永続化
    final cardId = _deck[_currentIndex].id;
    final wasAlreadyMastered = ref.read(flashcardProvider).masteredIds.contains(cardId);
    ref.read(flashcardProvider.notifier).markMastered(cardId);
    final masteredCount = ref.read(flashcardProvider).masteredIds.length;
    _checkMasteryBadge(masteredCount);
    setState(() {
      _correct++;
      _total++;
      if (!wasAlreadyMastered) _newlyMastered++;
    });
    _nextCard();
  }

  void _checkMasteryBadge(int masteredCount) {
    final (icon, name, message, goal) = switch (masteredCount) {
      5  => ('📚', '単語マスター', 'フラッシュカード5枚習得！', '10枚習得を目指そう！'),
      10 => ('🃏', 'カードビギナー', 'フラッシュカード10枚習得！', '20枚習得が次の目標！'),
      20 => ('🧠', 'Python知識人', 'フラッシュカード20枚習得！', 'あと20枚で全カード制覇！'),
      30 => ('💡', '上級知識人', 'フラッシュカード30枚習得！', '残り10枚！全制覇まであと少し！'),
      _ when masteredCount == kFlashcards.length => ('🎴', 'カードマスター！', 'フラッシュカード全${kFlashcards.length}枚習得！完全マスター！', '全問題で実力を試そう！'),
      _ => ('', '', '', ''),
    };
    if (icon.isEmpty) return;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      showBadgeUnlock(
        context,
        icon: icon,
        name: name,
        message: message,
        points: masteredCount * 3,
        nextGoal: goal,
        onContinue: () {},
      );
    });
  }

  void _markRetry() {
    if (!_isFlipped) return;
    SoundService().playWrong();
    HapticService.mediumImpact();
    final current = _deck[_currentIndex];
    setState(() {
      _retryDeck.add(current);
      _total++;
    });
    _nextCard();
  }

  Future<void> _nextCard() async {
    _autoFlipTimer?.cancel();
    if (_currentIndex < _deck.length - 1) {
      _flipController.reset();
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
      _scheduleAutoFlip();
    } else if (_retryDeck.isNotEmpty && !_isRetryRound) {
      // 1周目終了 → 再チャレンジへ
      _flipController.reset();
      setState(() {
        _deck = List.from(_retryDeck);
        _retryDeck = [];
        _currentIndex = 0;
        _isFlipped = false;
        _isRetryRound = true;
      });
      _scheduleAutoFlip();
    } else {
      // セッション完了
      SoundService().playComplete();
      HapticService.heavyImpact();
      setState(() => _sessionDone = true);
      // アクティビティログに記録（フラッシュカードのカレンダー反映）
      await ref.read(progressProvider.notifier).recordActivity();
      if (!_timeRecorded && _elapsedSeconds > 0) {
        _timeRecorded = true;
        final learningBadge = await ref
            .read(progressProvider.notifier)
            .recordLearningSeconds(_elapsedSeconds);
        if (learningBadge != null && mounted) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            showBadgeUnlock(
              context, // ignore: use_build_context_synchronously
              icon: learningBadge.$1,
              name: learningBadge.$2,
              message: learningBadge.$3,
              points: 30,
              nextGoal: learningBadge.$4,
              onContinue: () {},
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(context),
            if (!_sessionDone) ...[
              _buildCategoryFilter(),
              _buildMasteryFilter(),
            ],
            if (_listViewMode) ...[
              _buildSearchBar(),
              _buildSortBar(),
              Expanded(child: _buildListView()),
            ]
            else if (_sessionDone)
              Expanded(child: _buildResultView())
            else if (_deck.isEmpty)
              Expanded(child: _buildEmptyDeckView())
            else if (_quizMode)
              Expanded(child: _buildQuizCardView())
            else
              Expanded(child: _buildCardView()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E44AD), Color(0xFF5B2C6F)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'フラッシュカード',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Consumer(builder: (context, ref, _) {
                      final mastered =
                          ref.watch(flashcardProvider).masteredCount;
                      final total = kFlashcards.length;
                      return Text(
                        '習得済み $mastered / $total',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // 自動めくりトグル
              if (!_listViewMode)
                IconButton(
                  icon: Icon(
                    Icons.auto_mode,
                    color: _autoFlipEnabled
                        ? Colors.yellow.shade300
                        : Colors.white54,
                    size: 20,
                  ),
                  tooltip: _autoFlipEnabled
                      ? '自動めくり: オン ($_autoFlipSeconds秒)'
                      : '自動めくり: オフ',
                  onPressed: () {
                    HapticService.selectionClick();
                    setState(() {
                      _autoFlipEnabled = !_autoFlipEnabled;
                    });
                    if (_autoFlipEnabled) {
                      _scheduleAutoFlip();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('自動めくり ON: $_autoFlipSeconds秒後に自動で裏返します'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      _autoFlipTimer?.cancel();
                    }
                  },
                ),
              // クイズモードトグル
              if (!_listViewMode)
                IconButton(
                  icon: Icon(
                    Icons.quiz_outlined,
                    color: _quizMode ? Colors.yellow.shade300 : Colors.white54,
                    size: 20,
                  ),
                  tooltip: _quizMode ? 'クイズモード: オン' : 'クイズモード: オフ',
                  onPressed: () {
                    HapticService.selectionClick();
                    setState(() {
                      _quizMode = !_quizMode;
                      // モード切替時にデッキをリセット
                      _deck = _buildDeck();
                      _retryDeck = [];
                      _currentIndex = 0;
                      _isFlipped = false;
                      _isRetryRound = false;
                      _correct = 0;
                      _total = 0;
                      _newlyMastered = 0;
                      _sessionDone = false;
                      _elapsedSeconds = 0;
                      if (_quizMode) _prepareQuizChoices();
                    });
                    _flipController.reset();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_quizMode ? '❓ クイズモード ON: 4択で答えよう！' : '🃏 カードモードに戻りました'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              // 一覧/カードモード切り替え
              IconButton(
                icon: Icon(
                  _listViewMode ? Icons.style : Icons.list,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: _listViewMode ? 'カードモード' : '一覧モード',
                onPressed: () {
                  HapticService.selectionClick();
                  setState(() {
                    _listViewMode = !_listViewMode;
                    // カードモードに戻る際は検索クエリをリセット
                    if (!_listViewMode) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
              // セッションタイマー
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
                    const SizedBox(width: 3),
                    Text(
                      _formatElapsed(_elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (!_sessionDone && !_listViewMode)
                Text(
                  _isRetryRound
                      ? '再チャレンジ ${_currentIndex + 1}/${_deck.length}'
                      : '${_currentIndex + 1}/${_deck.length}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
            ],
          ),
          if (!_sessionDone) ...[
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: (_currentIndex + 1) / _deck.length),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMasteryFilter() {
    return Container(
      height: 40,
      color: const Color(0xFF8E44AD).withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Text(
            '絞り込み：',
            style: TextStyle(fontSize: 11, color: kTextSecondary),
          ),
          const SizedBox(width: 6),
          ..._MasteryFilter.values.map((f) {
            final label = switch (f) {
              _MasteryFilter.all => '全て',
              _MasteryFilter.unmastered => '未習得',
              _MasteryFilter.mastered => '習得済み',
            };
            final isSelected = f == _masteryFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  _sessionStart = DateTime.now();
                  setState(() {
                    _masteryFilter = f;
                    _deck = _buildDeck();
                    _retryDeck = [];
                    _currentIndex = 0;
                    _isFlipped = false;
                    _isRetryRound = false;
                    _correct = 0;
                    _total = 0;
                    _sessionDone = false;
                    _elapsedSeconds = 0;
                  });
                  _flipController.reset();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8E44AD)
                        : const Color(0xFF8E44AD).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF8E44AD),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyDeckView() {
    final label = _masteryFilter == _MasteryFilter.unmastered
        ? '未習得のカードがありません！\nすべてのカードを習得しました 🎉'
        : _masteryFilter == _MasteryFilter.mastered
            ? '習得済みのカードがありません。\nカードをめくって習得マークをつけよう！'
            : 'カードがありません。';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎴', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: kTextSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _sessionStart = DateTime.now();
                setState(() {
                  _masteryFilter = _MasteryFilter.all;
                  _deck = _buildDeck();
                  _currentIndex = 0;
                  _elapsedSeconds = 0;
                });
              },
              child: const Text('全て表示'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['全て', ...{for (final c in kFlashcards) c.category}];
    final masteredIds = ref.watch(flashcardProvider).masteredIds;
    return Container(
      height: 44,
      color: const Color(0xFF8E44AD).withValues(alpha: 0.06),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (context, i) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected =
              (cat == '全て' && _selectedCategory == null) ||
              cat == _selectedCategory;

          // カテゴリ別習得カウント
          final String countLabel;
          if (cat == '全て') {
            final total = kFlashcards.length;
            final mastered = masteredIds.length;
            countLabel = mastered == total ? ' ✅' : ' $mastered/$total';
          } else {
            final catCards = kFlashcards.where((c) => c.category == cat).toList();
            final mastered = catCards.where((c) => masteredIds.contains(c.id)).length;
            final total = catCards.length;
            countLabel = mastered == total ? ' ✅' : ' $mastered/$total';
          }

          return GestureDetector(
            onTap: () {
              _sessionStart = DateTime.now();
              setState(() {
                _selectedCategory = cat == '全て' ? null : cat;
                // カテゴリ変更時はデッキをリセット
                _deck = _buildDeck();
                _retryDeck = [];
                _currentIndex = 0;
                _isFlipped = false;
                _isRetryRound = false;
                _correct = 0;
                _total = 0;
                _newlyMastered = 0;
                _elapsedSeconds = 0;
              });
              _flipController.reset();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8E44AD)
                    : const Color(0xFF8E44AD).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$cat$countLabel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF8E44AD),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardView() {
    final card = _deck[_currentIndex];
    final remaining = _retryDeck.length;
    final isMastered = ref.watch(flashcardProvider).masteredIds.contains(card.id);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // カテゴリ + 習得済みバッジ + 残数
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E44AD).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E44AD),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isMastered) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 11, color: Color(0xFF27AE60)),
                          SizedBox(width: 3),
                          Text(
                            '習得済み',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (remaining > 0)
                Text(
                  '🔄 再チャレンジ: $remaining枚',
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                ),
              Text(
                _isFlipped ? '裏面' : 'タップして答えを見る',
                style: const TextStyle(fontSize: 12, color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // フラッシュカード本体（フリップアニメーション）
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              onHorizontalDragEnd: (details) {
                if (!_isFlipped) return;
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 300) {
                  _markCorrect(); // 右スワイプ = 知ってた！
                } else if (velocity < -300) {
                  _markRetry();   // 左スワイプ = もう一度
                }
              },
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * pi;
                  final isFront = angle < pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isFront
                        ? _CardFront(card: card)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _CardBack(card: card),
                          ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // スワイプ / キーボードヒント
          if (_isFlipped)
            const Text(
              '← / [←] もう一度  |  知ってた！ [→] / →',
              style: TextStyle(fontSize: 10, color: kTextSecondary),
              textAlign: TextAlign.center,
            )
          else
            const Text(
              '[Space] または タップ でカードをめくる',
              style: TextStyle(fontSize: 10, color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),

          // アクションボタン
          if (_isFlipped) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markRetry,
                    icon: const Text('🔄', style: TextStyle(fontSize: 16)),
                    label: const Text('もう一度'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.orange),
                      foregroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markCorrect,
                    icon: const Text('👍', style: TextStyle(fontSize: 16)),
                    label: const Text('知ってた！'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _flipCard,
                icon: const Icon(Icons.flip, size: 18),
                label: const Text('カードをめくる'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF8E44AD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // メモボタン
          _buildNoteButton(card),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── クイズモード ─────────────────────────────────────────────────────────

  Widget _buildQuizCardView() {
    if (_deck.isEmpty) return _buildEmptyDeckView();
    final card = _deck[_currentIndex];
    final isMastered = ref.watch(flashcardProvider).masteredIds.contains(card.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          // カテゴリ + 習得済みバッジ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E44AD).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  card.category,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E44AD), fontWeight: FontWeight.w600),
                ),
              ),
              if (isMastered) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 11, color: Color(0xFF27AE60)),
                      SizedBox(width: 3),
                      Text('習得済み', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('❓ クイズモード', style: TextStyle(fontSize: 11, color: Colors.deepPurple, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 問題カード (front)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8E44AD), Color(0xFF5B2C6F)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E44AD).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('この用語の説明は？', style: TextStyle(fontSize: 11, color: Colors.white60)),
                const SizedBox(height: 8),
                Text(
                  card.front,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (card.code != null) ...[
                  const SizedBox(height: 10),
                  CodeHighlightWidget(code: card.code!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 選択肢
          Expanded(
            child: ListView.separated(
              shrinkWrap: false,
              physics: const BouncingScrollPhysics(),
              itemCount: _quizChoices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final choice = _quizChoices[idx];
                final isCorrect = idx == _quizCorrectIndex;
                final isSelected = _quizSelectedIndex == idx;

                // 回答後のカラー
                Color? bgColor;
                Color? borderColor;
                Color textColor = context.textPrimary;
                if (_quizAnswered) {
                  if (isCorrect) {
                    bgColor = const Color(0xFF27AE60).withValues(alpha: 0.12);
                    borderColor = const Color(0xFF27AE60);
                    textColor = const Color(0xFF1A6B3A);
                  } else if (isSelected) {
                    bgColor = const Color(0xFFE74C3C).withValues(alpha: 0.1);
                    borderColor = const Color(0xFFE74C3C);
                    textColor = const Color(0xFFB03020);
                  } else {
                    bgColor = context.subCardBg;
                    borderColor = context.borderColor;
                    textColor = kTextSecondary;
                  }
                } else if (isSelected) {
                  bgColor = const Color(0xFF8E44AD).withValues(alpha: 0.12);
                  borderColor = const Color(0xFF8E44AD);
                } else {
                  bgColor = context.cardBg;
                  borderColor = context.borderColor;
                }

                return GestureDetector(
                  onTap: _quizAnswered ? null : () => _submitQuizAnswer(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_quizAnswered && isCorrect) ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _quizAnswered && isCorrect
                                ? const Color(0xFF27AE60)
                                : _quizAnswered && isSelected
                                    ? const Color(0xFFE74C3C)
                                    : isSelected
                                        ? const Color(0xFF8E44AD)
                                        : context.borderColor.withValues(alpha: 0.5),
                          ),
                          child: Center(
                            child: _quizAnswered && isCorrect
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : _quizAnswered && isSelected
                                    ? const Icon(Icons.close, size: 14, color: Colors.white)
                                    : Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : kTextSecondary,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            choice,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: isSelected || (_quizAnswered && isCorrect)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(key: ValueKey('choice_${_currentIndex}_$idx'))
                   .fadeIn(duration: Duration(milliseconds: 200 + idx * 60))
                   .slideX(begin: 0.05, curve: Curves.easeOut),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 回答後: 正誤フィードバック + 次へボタン
          if (_quizAnswered) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _quizSelectedIndex == _quizCorrectIndex
                    ? const Color(0xFF27AE60).withValues(alpha: 0.1)
                    : const Color(0xFFE74C3C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _quizSelectedIndex == _quizCorrectIndex
                      ? const Color(0xFF27AE60).withValues(alpha: 0.4)
                      : const Color(0xFFE74C3C).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _quizSelectedIndex == _quizCorrectIndex
                    ? '✅ 正解！正しい説明を選べました！'
                    : '❌ 不正解。緑の選択肢が正解です。',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _quizSelectedIndex == _quizCorrectIndex
                      ? const Color(0xFF1A6B3A)
                      : const Color(0xFFB03020),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _quizNext,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('次のカードへ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF8E44AD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _quizSelectedIndex != null ? () => _submitQuizAnswer(_quizSelectedIndex!) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF8E44AD),
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('回答する', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '1〜4 キーで選択、Enter/Space で回答',
              style: TextStyle(fontSize: 10, color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteButton(Flashcard card) {
    final flashState = ref.watch(flashcardProvider);
    final hasNote = flashState.hasNote(card.id);
    final noteText = flashState.noteFor(card.id) ?? '';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showNoteEditor(card, noteText),
        icon: Text(hasNote ? '📝' : '✏️', style: const TextStyle(fontSize: 14)),
        label: Text(hasNote ? 'メモを編集' : 'メモを追加'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: BorderSide(
            color: hasNote
                ? const Color(0xFFF39C12).withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.4),
          ),
          foregroundColor: hasNote ? const Color(0xFFF39C12) : kTextSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _showNoteEditor(Flashcard card, String initial) async {
    final controller = TextEditingController(text: initial);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '「${card.front}」のメモ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: '自分だけのメモを書こう（例：「printは画面に出す関数」）',
                hintStyle: const TextStyle(fontSize: 12, color: kTextSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: context.subCardBg,
              ),
              style: TextStyle(fontSize: 14, color: context.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (initial.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(flashcardProvider.notifier).setNote(card.id, '');
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('削除'),
                    ),
                  ),
                if (initial.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticService.lightImpact();
                      ref.read(flashcardProvider.notifier).setNote(card.id, controller.text);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E44AD),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Widget _buildSortBar() {
    const sortModes = [
      (_SortMode.defaultOrder,   '🗂️ デフォルト'),
      (_SortMode.masteredDateNew, '🆕 習得：新'),
      (_SortMode.masteredDateOld, '📅 習得：古'),
      (_SortMode.alphabetical,    '🔤 あいうえお順'),
    ];
    return Container(
      height: 36,
      color: const Color(0xFF8E44AD).withValues(alpha: 0.03),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Text(
            '並び順：',
            style: TextStyle(fontSize: 10, color: kTextSecondary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sortModes.map((entry) {
                  final (mode, label) = entry;
                  final isSelected = _sortMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        HapticService.selectionClick();
                        setState(() => _sortMode = mode);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8E44AD)
                              : const Color(0xFF8E44AD).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF8E44AD),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF8E44AD).withValues(alpha: 0.04),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(fontSize: 13, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: 'カードを検索...',
          hintStyle: const TextStyle(fontSize: 13, color: kTextSecondary),
          prefixIcon: const Icon(Icons.search, size: 18, color: kTextSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: kTextSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: context.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: const Color(0xFF8E44AD).withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF8E44AD), width: 1.5),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBulkMaster(List<Flashcard> unmasteredCards) async {
    HapticService.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('一括習得', style: TextStyle(fontSize: 16)),
        content: Text(
          '「$_selectedCategory」の未習得${unmasteredCards.length}件をすべて習得済みにしますか？',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E44AD)),
            child: const Text('習得済みにする', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await ref.read(flashcardProvider.notifier)
        .markAllMastered(unmasteredCards.map((c) => c.id).toList());
    HapticService.mediumImpact();
    SoundService().playComplete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${unmasteredCards.length}件を習得済みにしました！'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildListView() {
    final flashState = ref.watch(flashcardProvider);
    // カテゴリフィルター + 習得フィルター適用
    var cards = _selectedCategory == null
        ? List<Flashcard>.from(kFlashcards)
        : kFlashcards.where((c) => c.category == _selectedCategory).toList();
    switch (_masteryFilter) {
      case _MasteryFilter.unmastered:
        cards = cards.where((c) => !flashState.masteredIds.contains(c.id)).toList();
        break;
      case _MasteryFilter.mastered:
        cards = cards.where((c) => flashState.masteredIds.contains(c.id)).toList();
        break;
      case _MasteryFilter.all:
        break;
    }
    // 検索クエリフィルター
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      cards = cards.where((c) =>
        c.front.toLowerCase().contains(q) ||
        c.back.toLowerCase().contains(q) ||
        (c.code?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    // ソート適用
    switch (_sortMode) {
      case _SortMode.masteredDateNew:
        cards.sort((a, b) {
          final da = flashState.masteredDates[a.id];
          final db = flashState.masteredDates[b.id];
          if (da == null && db == null) return 0;
          if (da == null) return 1;  // 未習得を末尾へ
          if (db == null) return -1;
          return db.compareTo(da); // 新しい順
        });
        break;
      case _SortMode.masteredDateOld:
        cards.sort((a, b) {
          final da = flashState.masteredDates[a.id];
          final db = flashState.masteredDates[b.id];
          if (da == null && db == null) return 0;
          if (da == null) return 1;  // 未習得を末尾へ
          if (db == null) return -1;
          return da.compareTo(db); // 古い順
        });
        break;
      case _SortMode.alphabetical:
        cards.sort((a, b) => a.front.compareTo(b.front));
        break;
      case _SortMode.defaultOrder:
        break; // デフォルト順はそのまま
    }

    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty ? '「$_searchQuery」に一致するカードがありません' : 'カードがありません',
                style: const TextStyle(color: kTextSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // カテゴリフィルター中の一括習得ヘッダー
    final unmasteredInView = cards
        .where((c) => !flashState.masteredIds.contains(c.id))
        .toList();
    Widget? bulkMasterHeader;
    if (_selectedCategory != null && unmasteredInView.isNotEmpty) {
      bulkMasterHeader = Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF8E44AD).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8E44AD).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Text('📘', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '未習得: ${unmasteredInView.length}件',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E44AD),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _confirmBulkMaster(unmasteredInView),
              icon: const Icon(Icons.check_circle_outline, size: 14),
              label: const Text('一括習得'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8E44AD),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // カテゴリ別進捗サマリー（フィルターなしのときのみ表示）
    Widget? categoryHeader;
    if (_selectedCategory == null &&
        _masteryFilter == _MasteryFilter.all &&
        _searchQuery.isEmpty) {
      final categories = {for (final c in kFlashcards) c.category}.toList()
        ..sort();
      categoryHeader = Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カテゴリ別進捗',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: categories.map((cat) {
                final total = kFlashcards.where((c) => c.category == cat).length;
                final mastered = kFlashcards
                    .where((c) => c.category == cat)
                    .where((c) => flashState.masteredIds.contains(c.id))
                    .length;
                final pct = total > 0 ? mastered / total : 0.0;
                final isDone = mastered == total;
                return GestureDetector(
                  onTap: () {
                    HapticService.selectionClick();
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF27AE60).withValues(alpha: 0.12)
                          : const Color(0xFF8E44AD).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFF27AE60).withValues(alpha: 0.4)
                            : const Color(0xFF8E44AD).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDone ? '✅' : '📘',
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? const Color(0xFF1A6B3A)
                                : const Color(0xFF8E44AD),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$mastered/$total',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDone ? const Color(0xFF27AE60) : kTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 28,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDone
                                    ? const Color(0xFF27AE60)
                                    : const Color(0xFF8E44AD),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    // ヘッダー（カテゴリ進捗 または 一括習得バー）をまとめて組み立て
    final headers = <Widget>[
      ?categoryHeader,
      ?bulkMasterHeader,
    ];

    if (headers.isNotEmpty) {
      return Column(
        children: [
          ...headers,
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: cards.length,
              itemBuilder: (ctx, i) => _buildListItem(ctx, cards[i], flashState),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: cards.length,
      itemBuilder: (ctx, i) => _buildListItem(ctx, cards[i], flashState),
    );
  }

  Widget _buildListItem(BuildContext ctx, Flashcard card, FlashcardState flashState) {
        final isMastered = flashState.masteredIds.contains(card.id);
        final note = flashState.noteFor(card.id);
        final daysSince = flashState.daysSinceMastered(card.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: ctx.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMastered
                  ? const Color(0xFF27AE60).withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF8E44AD).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  isMastered ? '✅' : '📘',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            title: Text(
              card.front,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ctx.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E44AD).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    card.category,
                    style: const TextStyle(fontSize: 9, color: Color(0xFF8E44AD)),
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  const Text('📝', style: TextStyle(fontSize: 10)),
                ],
                if (isMastered && daysSince != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    daysSince == 0 ? '今日習得' : '$daysSince日前',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ],
              ],
            ),
            children: [
              Text(
                card.back,
                style: TextStyle(
                  fontSize: 14,
                  color: ctx.textPrimary,
                  height: 1.4,
                ),
              ),
              if (card.code != null) ...[
                const SizedBox(height: 8),
                CodeHighlightWidget(code: card.code!, fontSize: 11),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ctx.isDark ? const Color(0xFF3D2E00) : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 11,
                            color: ctx.isDark ? const Color(0xFFFFE082) : const Color(0xFF795548),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // メモ追加/編集ボタン
                  TextButton.icon(
                    onPressed: () => _showNoteEditor(card, note ?? ''),
                    icon: Text(
                      note != null && note.isNotEmpty ? '📝' : '✏️',
                      style: const TextStyle(fontSize: 12),
                    ),
                    label: Text(
                      note != null && note.isNotEmpty ? 'メモ編集' : 'メモ追加',
                      style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () {
                      if (isMastered) {
                        ref.read(flashcardProvider.notifier).unmarkMastered(card.id);
                      } else {
                        ref.read(flashcardProvider.notifier).markMastered(card.id);
                        final count = ref.read(flashcardProvider).masteredIds.length;
                        _checkMasteryBadge(count);
                      }
                    },
                    icon: Icon(
                      isMastered ? Icons.check_circle : Icons.check_circle_outline,
                      size: 14,
                      color: isMastered ? const Color(0xFF27AE60) : kTextSecondary,
                    ),
                    label: Text(
                      isMastered ? '習得済み' : '習得済みにする',
                      style: TextStyle(
                        fontSize: 11,
                        color: isMastered ? const Color(0xFF27AE60) : kTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
  }

  Widget _buildCategoryMasterySection() {
    final masteredIds = ref.watch(flashcardProvider).masteredIds;
    // カテゴリ別に集計
    final Map<String, List<Flashcard>> byCategory = {};
    for (final card in kFlashcards) {
      byCategory.putIfAbsent(card.category, () => []).add(card);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'カテゴリ別習得状況',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...byCategory.entries.map((entry) {
            final category = entry.key;
            final cards = entry.value;
            final total = cards.length;
            final mastered = cards.where((c) => masteredIds.contains(c.id)).length;
            final ratio = total > 0 ? mastered / total : 0.0;
            final percentVal = (ratio * 100).round();
            final color = ratio >= 1.0
                ? Colors.green
                : ratio >= 0.5
                    ? const Color(0xFF8E44AD)
                    : Colors.orange;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '$mastered / $total  ($percentVal%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: ratio),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _shareResult(BuildContext context) {
    HapticService.lightImpact();
    final percent = _total > 0 ? (_correct / _total * 100).round() : 0;
    final totalMastered = ref.read(flashcardProvider).masteredIds.length;
    final timeStr = _elapsedSeconds >= 60
        ? '${_elapsedSeconds ~/ 60}分${_elapsedSeconds % 60}秒'
        : '$_elapsedSeconds秒';
    final masteredLine = _newlyMastered > 0
        ? '✨ 新たに習得: $_newlyMastered枚\n'
        : '';
    final totalLine = totalMastered > 0
        ? '🎓 累計習得: $totalMastered/${kFlashcards.length}枚\n'
        : '';
    final text =
        '🃏 フラッシュカード結果\n'
        '正解: $_correct/$_total ($percent%)\n'
        '$masteredLine'
        '$totalLine'
        '⏱ タイム: $timeStr\n'
        '#しょうがくプログラミング';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 結果をコピーしました！'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildResultView() {
    final percent = _total > 0 ? (_correct / _total * 100).round() : 0;
    final String emoji;
    final String message;
    if (percent >= 90) {
      emoji = '🏆';
      message = '完璧！Python マスター！';
    } else if (percent >= 70) {
      emoji = '⭐';
      message = 'よくできました！';
    } else if (percent >= 50) {
      emoji = '💪';
      message = 'もう少し！復習しよう';
    } else {
      emoji = '📚';
      message = 'もう一度チャレンジ！';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 72))
              .animate()
              .scale(
                begin: const Offset(0.0, 0.0),
                curve: Curves.elasticOut,
                duration: 600.ms,
              )
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          )
              .animate(delay: 300.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 24),
          // スコアカード
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _ResultRow(label: '正解', value: '$_correct', color: kPrimaryColor),
                const Divider(height: 20),
                _ResultRow(
                    label: '間違い', value: '${_total - _correct}', color: Colors.orange),
                const Divider(height: 20),
                _ResultRow(label: '正答率', value: '$percent%', color: Colors.purple),
                if (_newlyMastered > 0) ...[
                  const Divider(height: 20),
                  _ResultRow(
                    label: '✨ 新たに習得',
                    value: '$_newlyMastered枚',
                    color: const Color(0xFF27AE60),
                  ),
                ],
                const Divider(height: 20),
                _ResultRow(
                  label: '⏱ タイム',
                  value: _formatElapsed(_elapsedSeconds),
                  color: Colors.blueAccent,
                ),
                if (_total > 0 && _elapsedSeconds > 0) ...[
                  const Divider(height: 20),
                  _ResultRow(
                    label: '📊 平均',
                    value: '${(_elapsedSeconds / _total).round()}秒/枚',
                    color: Colors.blueGrey,
                  ),
                ],
              ],
            ),
          )
              .animate(delay: 500.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 20),
          // カテゴリ別習得状況
          _buildCategoryMasterySection()
              .animate(delay: 700.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 24),
          // ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _sessionStart = DateTime.now();
                setState(() {
                  _deck = _buildDeck();
                  _retryDeck = [];
                  _currentIndex = 0;
                  _isFlipped = false;
                  _isRetryRound = false;
                  _correct = 0;
                  _total = 0;
                  _sessionDone = false;
                  _elapsedSeconds = 0;
                });
                _flipController.reset();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('もう一度チャレンジ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF8E44AD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareResult(context),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('結果をシェア'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8E44AD),
                side: BorderSide(color: const Color(0xFF8E44AD).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ステージ一覧へ戻る',
              style: TextStyle(color: kTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── カード表面 ───────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  final Flashcard card;
  const _CardFront({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E44AD), Color(0xFF5B2C6F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E44AD).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📘', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              card.front,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'タップして答えを見る →',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── カード裏面 ───────────────────────────────────────────────────────────────

class _CardBack extends ConsumerWidget {
  final Flashcard card;
  const _CardBack({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(flashcardProvider).noteFor(card.id);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8E44AD).withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '答え',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E44AD),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              card.back,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                height: 1.4,
              ),
            ),
            if (card.code != null) ...[
              const SizedBox(height: 16),
              const Text(
                '例',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: kTextSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              CodeHighlightWidget(code: card.code!, fontSize: 12),
            ],
            // メモ表示
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF3D2E00) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFCC02).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.isDark ? const Color(0xFFFFE082) : const Color(0xFF795548),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 結果行ウィジェット ───────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: kTextSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
