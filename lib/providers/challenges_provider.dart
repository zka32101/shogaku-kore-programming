import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../config/constants.dart';

// 全ステージデータ
final allChallengesProvider = Provider<List<Challenge>>((ref) {
  return _buildChallenges();
});

// レベル別フィルター
final beginnerChallengesProvider = Provider<List<Challenge>>((ref) {
  return ref.watch(allChallengesProvider)
      .where((c) => c.level == StageLevel.beginner)
      .toList();
});

final intermediateChallengesProvider = Provider<List<Challenge>>((ref) {
  return ref.watch(allChallengesProvider)
      .where((c) => c.level == StageLevel.intermediate)
      .toList();
});

final advancedChallengesProvider = Provider<List<Challenge>>((ref) {
  return ref.watch(allChallengesProvider)
      .where((c) => c.level == StageLevel.advanced)
      .toList();
});

List<Challenge> _buildChallenges() {
  final list = [
    // ===== 初級: ビジュアルプログラミング =====
    Challenge(
      id: 'stage_01',
      stageNumber: 1,
      title: '直線を描こう',
      description: '「前に進む」ブロックを使って、ロボットを右へ動かしてみよう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🤖',
      isFree: true,
      expectedOutput: 'move_forward(100)',
      hints: ['「前に進む」ブロックを1回使おう', '歩数は100に設定しよう'],
      availableBlocks: [
        const BlockTemplate(
          id: 'move_forward',
          name: '前に進む',
          icon: '📍',
          category: 'motion',
          description: 'ロボットを前に進める',
        ),
      ],
    ),
    Challenge(
      id: 'stage_02',
      stageNumber: 2,
      title: '右に曲がろう',
      description: '「前に進む」と「右に回転」を組み合わせてL字を描こう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '↪️',
      isFree: true,
      expectedOutput: 'move_forward(100)\nturn_right(90)',
      hints: ['2つのブロックを順番に並べよう', '先に進んでから回転しよう'],
    ),
    Challenge(
      id: 'stage_03',
      stageNumber: 3,
      title: '四角を描こう',
      description: '繰り返しを使って、4回同じ動きをして四角を描こう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '⬜',
      isFree: true,
      expectedOutput: 'repeat(4):\n  move_forward(100)\n  turn_right(90)',
      hints: ['「繰り返す」ブロックを使おう', '中に「前に進む」と「右に回転」を入れよう'],
    ),
    Challenge(
      id: 'stage_04',
      stageNumber: 4,
      title: '迷路を解こう①',
      description: 'ロボットを動かして迷路をゴールまで導こう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🧩',
      isFree: true,
      expectedOutput: 'move_forward(100)\nturn_right(90)\nmove_forward(200)\nturn_left(90)\nmove_forward(100)',
      hints: ['まず右に曲がる必要があるよ', 'ゴールまで4手順でたどり着けるよ'],
    ),
    Challenge(
      id: 'stage_05',
      stageNumber: 5,
      title: '条件を使おう',
      description: '「もし壁があれば」を使って、ロボットが賢く動けるようにしよう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🔀',
      isFree: true,
      expectedOutput: 'if wall:\n  turn_right(90)\nelse:\n  move_forward(100)',
      hints: ['壁があるときと、ないときで動きを変えよう', '「もし〜なら」の中に動きを入れよう'],
    ),

    // ===== 中級: Pythonクイズ =====
    Challenge(
      id: 'stage_06',
      stageNumber: 6,
      title: 'はじめてのprint',
      description: 'Pythonの基本！print文の使い方を学ぼう',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🐍',
      isFree: true,
      conceptExplanation: '''
🐍 Python（パイソン）ってなに？

Pythonは、世界中で大人気のプログラミングことば！
マイクラのMODや、AIにも使われているよ。

📺 print（プリント）で画面に文字を出そう！

→ print("こんにちは")  と書くと…
→ 画面に「こんにちは」と表示されるよ！

💡 ポイント
• print( ) のかっこの中に表示したいものを書く
• 文字は " "（ダブルクォート）で囲む
• 数字はそのまま書ける（例: print(5 + 3) → 8）

🎮 ゲームでも使われてるよ！
スコアを表示する、メッセージを出す、
ぜんぶ print の仲間の命令で動いてるんだ。
''',
      questions: [
        const Question(
          id: 'q_06_1',
          text: '次のコードを実行すると何が表示される？',
          codeSnippet: 'print("こんにちは")\nprint("世界")',
          options: [
            'こんにちは世界',
            'こんにちは\n世界',
            'エラーが出る',
            '何も表示されない',
          ],
          correctIndex: 1,
          explanation: 'print()は一行ごとに改行して表示します。「こんにちは」と「世界」が別々の行に表示されます。',
          hint: 'print()を1回呼ぶたびに、1行が出力されるよ。',
        ),
        const Question(
          id: 'q_06_2',
          text: '変数に文字を入れてprintするには？',
          codeSnippet: 'name = "太郎"\nprint(____)',
          options: [
            'print("name")',
            'print(name)',
            'print[name]',
            'print{name}',
          ],
          correctIndex: 1,
          explanation: '変数は""なしで書きます。print(name)で変数の中身が表示されます。',
          hint: '変数名を""で囲むと文字列になって、変数の中身が出ないよ。',
        ),
        const Question(
          id: 'q_06_3',
          text: 'このコードの実行結果は？',
          codeSnippet: 'x = 5\nprint(x + 3)',
          options: ['5 + 3', '53', '8', 'エラー'],
          correctIndex: 2,
          explanation: 'x = 5 なので、x + 3 = 5 + 3 = 8 が表示されます。',
          hint: 'x に 5 が入っているから、x + 3 を計算してみよう。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_07',
      stageNumber: 7,
      title: 'くり返し入門',
      description: '同じ処理を何度もくり返す「くり返し」を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🔁',
      isFree: true,
      conceptExplanation: '''
🔁 くり返し（for ループ）ってなに？

「おなじことを何回もやる」命令だよ！

🎮 ゲームで例えると…
→ コインを10枚集める → 10回くり返す！
→ 敵を5体たおす → 5回くり返す！

📝 Pythonの書き方

for i in range(3):
    print("進め！")

→ 「進め！」が3回表示されるよ

💡 range の使い方
• range(3) → 0, 1, 2 の3回
• range(1, 4) → 1, 2, 3 の3回
• for の下はスペース4つ下げて書く（インデント）

⚡ なんでくり返しが便利なの？
100回おなじことを書くかわりに、
「100回くり返す」1行で書けるから！
''',
      questions: [
        const Question(
          id: 'q_07_1',
          text: '次のコードは何回「進め」と表示する？',
          codeSnippet: 'for i in range(3):\n    print("進め")',
          options: ['1回', '2回', '3回', '4回'],
          correctIndex: 2,
          explanation: 'range(3)は0,1,2の3回繰り返します。「進め」が3回表示されます。',
          hint: 'range(n) は 0 から始まって n 個の数を作るよ。',
        ),
        const Question(
          id: 'q_07_2',
          text: '次のコードの結果は？',
          codeSnippet: 'for i in range(3):\n    print("進め")\n    print("曲がる")',
          options: [
            '進め曲がる（1回）',
            '進め曲がる（3回）',
            '進め（3回）、曲がる',
            '進め曲がる曲がる',
          ],
          correctIndex: 1,
          explanation: 'ループの中の処理が3回繰り返されます。「進め」→「曲がる」のセットが3回です。',
          hint: 'for ブロックの中にある行は、すべてループで繰り返されるよ。',
        ),
        const Question(
          id: 'q_07_3',
          text: 'range(1, 4)が作るのは？',
          options: [
            '[0, 1, 2, 3]',
            '[1, 2, 3, 4]',
            '[1, 2, 3]',
            '[0, 1, 2, 3, 4]',
          ],
          correctIndex: 2,
          explanation: 'range(start, stop)はstartからstop-1まで。range(1,4)は[1,2,3]です。',
          hint: 'range(start, stop) の stop は含まれないよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_08',
      stageNumber: 8,
      title: 'もし～なら',
      description: '条件によって処理を変える「もし～なら」を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🔀',
      isFree: true,
      conceptExplanation: '''
🔀 もし～なら（if 文）ってなに？

「条件によって、やることを変える」命令だよ！

🎮 ゲームで例えると…
→ もし HP が0になったら → ゲームオーバー！
→ もし コインが100枚なら → 1アップ！
→ そうでなければ → ゲームつづく！

📝 Pythonの書き方

if x > 5:
    print("大きい！")
else:
    print("小さい！")

💡 比べるときの記号
• x > 5  → xが5より大きい？
• x == 3 → xが3と同じ？（= を2回書く！）
• x != 3 → xが3と違う？

⚡ elif（エリフ）で3つ以上に分けられるよ！
if x == 1: print("いち")
elif x == 2: print("に")
else: print("その他")
''',
      questions: [
        const Question(
          id: 'q_08_1',
          text: 'x = 10のとき、このコードの結果は？',
          codeSnippet: 'x = 10\nif x > 5:\n    print("大きい")\nelse:\n    print("小さい")',
          options: ['大きい', '小さい', '何も表示されない', 'エラー'],
          correctIndex: 0,
          explanation: 'x = 10 > 5 が True なので、「大きい」が表示されます。',
          hint: '10 は 5 より大きい？小さい？どっちかな。',
        ),
        const Question(
          id: 'q_08_2',
          text: 'x = 3のとき、何が表示される？',
          codeSnippet: 'x = 3\nif x == 1:\n    print("いち")\nelif x == 2:\n    print("に")\nelif x == 3:\n    print("さん")\nelse:\n    print("その他")',
          options: ['いち', 'に', 'さん', 'その他'],
          correctIndex: 2,
          explanation: 'x == 3 が True なので「さん」が表示されます。elifは「else if」の短縮形です。',
          hint: '上から順に条件を確認して、最初に True になったブロックが実行されるよ。',
        ),
        const Question(
          id: 'q_08_3',
          text: 'Pythonで「等しい」を確認するには？',
          options: ['=', '==', '===', '!='],
          correctIndex: 1,
          explanation: '「==」は比較（等しい確認）、「=」は代入（値を入れる）です。',
          hint: '「=」は代入（値を入れる）、比較には別の記号を使うよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_09',
      stageNumber: 9,
      title: 'まとめて入れよう',
      description: 'たくさんのデータをまとめて扱う「リスト（まとめ入れ物）」を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '📋',
      isFree: true,
      conceptExplanation: '''
📋 リスト（list）ってなに？

たくさんのデータをまとめて入れられる「入れ物」だよ！

🎮 ゲームで例えると…
→ ポケモンずかん → たくさんのポケモンをまとめて管理！
→ インベントリ → アイテムをまとめて持てる！

📝 Pythonの書き方

fruits = ["りんご", "バナナ", "みかん"]

→ [ ] の中に , で区切って入れる

💡 取り出し方（番号は 0 から！）
• fruits[0] → "りんご"
• fruits[1] → "バナナ"
• fruits[2] → "みかん"

⚡ 便利な使い方
• fruits.append("ぶどう") → 末尾に追加
• len(fruits) → 何個入ってるか数える
• for fruit in fruits: → 全部に順番にアクセス
''',
      questions: [
        const Question(
          id: 'q_09_1',
          text: '次のコードでfruits[1]は何？',
          codeSnippet: 'fruits = ["りんご", "バナナ", "みかん"]',
          options: ['りんご', 'バナナ', 'みかん', 'エラー'],
          correctIndex: 1,
          explanation: 'リストの番号は0から始まります。fruits[0]=りんご、fruits[1]=バナナです。',
          hint: 'リストの番号（インデックス）は 0 から始まるよ。',
        ),
        const Question(
          id: 'q_09_2',
          text: 'リストに要素を追加するには？',
          codeSnippet: 'fruits = ["りんご"]\n____("ぶどう")',
          options: [
            'fruits.add("ぶどう")',
            'fruits.append("ぶどう")',
            'fruits.insert("ぶどう")',
            'fruits.push("ぶどう")',
          ],
          correctIndex: 1,
          explanation: 'Pythonではappend()でリストの末尾に要素を追加します。',
          hint: 'Python のリストに追加するメソッドは「a...」で始まるよ。',
        ),
        const Question(
          id: 'q_09_3',
          text: 'len(fruits)が返すのは？',
          codeSnippet: 'fruits = ["りんご", "バナナ", "みかん"]',
          options: ['fruits', '3', '2', '0'],
          correctIndex: 1,
          explanation: 'len()はリストの要素数を返します。3つの果物があるのでlen(fruits) = 3です。',
          hint: 'len は length（長さ）の略。要素がいくつあるか数えてみよう。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_10',
      stageNumber: 10,
      title: '動きを作ろう',
      description: 'よく使う処理をまとめた「動き（関数）」を作ってみよう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🔧',
      isFree: true,
      conceptExplanation: '''
🔧 関数（function）ってなに？

「よく使う命令をひとまとめにして名前をつける」仕組みだよ！

🎮 ゲームで例えると…
→ 「ジャンプ」ボタンを押す → ジャンプの動作が全部まとめて実行！
→ 「攻撃」ボタンを押す → 攻撃アニメ+ダメージ計算+効果音が全部実行！

📝 Pythonの書き方

def greet(name):
    print("こんにちは、" + name)

greet("太郎")  ← 「こんにちは、太郎」と表示！

💡 ポイント
• def で始める（define = 定義する）
• ( ) の中に受け取るデータを書く（引数）
• return で答えを返せる

⚡ 同じ処理を何度も使いたいときに大活躍！
def square(x):
    return x * x

print(square(5))  → 25
''',
      questions: [
        const Question(
          id: 'q_10_1',
          text: 'Pythonで関数を定義するキーワードは？',
          options: ['function', 'def', 'func', 'define'],
          correctIndex: 1,
          explanation: 'Pythonは「def 関数名():」で関数を定義します。',
          hint: '「def」は define（定義する）の略だよ。',
        ),
        const Question(
          id: 'q_10_2',
          text: 'この関数の実行結果は？',
          codeSnippet: 'def greet(name):\n    print("こんにちは、" + name)\n\ngreet("花子")',
          options: [
            'こんにちは、name',
            'こんにちは、花子',
            'こんにちは、',
            'エラー',
          ],
          correctIndex: 1,
          explanation: 'greet("花子")を呼ぶとname="花子"になります。「こんにちは、花子」と表示されます。',
          hint: 'greet("花子") を呼ぶと、name に「花子」が入るよ。',
        ),
        const Question(
          id: 'q_10_3',
          text: '関数が値を返すキーワードは？',
          options: ['give', 'output', 'return', 'result'],
          correctIndex: 2,
          explanation: '「return」で関数の結果を返します。return value で呼び出し元に値を渡せます。',
          hint: '多くのプログラミング言語で共通して使われる英単語だよ。',
        ),
      ],
    ),

    // ===== 中級追加: Python応用入門 =====
    Challenge(
      id: 'stage_26',
      stageNumber: 26,
      title: '入れ物の種類を知ろう',
      description: '数・文字・真偽値など、Pythonの「入れ物の種類（型）」を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🧮',
      isFree: true,
      conceptExplanation: '''
🧮 型（かた）ってなに？

データの「種類」のことだよ！
数字と文字はちがう種類なんだ。

📦 Pythonの主な型

• int（整数）  → 1, 42, -5 など
• float（小数）→ 3.14, 0.5 など
• str（文字列）→ "こんにちは", "太郎" など
• bool（真偽値）→ True か False の2つだけ

🎮 ゲームで例えると…
→ HP は数字（int）
→ 名前は文字（str）
→ 生きてるかどうかは True/False（bool）

⚠️ 注意！型が違うと足せない！
x = "3"    ← 文字の3
y = 2      ← 数字の2
x + y      → エラー！！

int(x) で変換してから足そう！
''',
      questions: [
        const Question(
          id: 'q_26_1',
          text: 'type(42)の結果は？',
          options: ['str', 'int', 'float', 'bool'],
          correctIndex: 1,
          explanation: '整数（42など）は int 型です。type()で型を調べられます。',
        ),
        const Question(
          id: 'q_26_2',
          text: 'このコードの結果は？',
          codeSnippet: 'x = "3"\ny = 2\nprint(x + y)',
          options: ['"5"', '5', '"32"', 'エラー'],
          correctIndex: 3,
          explanation: '文字列(str)と整数(int)は直接足せません。int(x)で変換するか、str(y)にする必要があります。',
        ),
        const Question(
          id: 'q_26_3',
          text: 'bool型の値として正しいのは？',
          options: ['"True"', '1 == 1', 'true', '"yes"'],
          correctIndex: 1,
          explanation: '「1 == 1」は比較式で True（bool型）を返します。Pythonの真偽値は True / False（大文字始まり）です。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_27',
      stageNumber: 27,
      title: '辞書を使いこなそう',
      description: '名前と値をセットで管理できる「辞書（dict）」をさらに深く学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🗃️',
      isFree: true,
      conceptExplanation: '''
🗃️ 辞書（dict）ってなに？

「名前」と「データ」をセットで管理できる入れ物！

🎮 ゲームで例えると…
→ キャラクターデータ
  名前 → "ピカチュウ"
  タイプ → "でんき"
  HP → 100

📝 Pythonの書き方

pokemon = {
  "name": "ピカチュウ",
  "type": "でんき",
  "hp": 100
}

→ pokemon["name"] → "ピカチュウ"
→ pokemon["hp"]   → 100

💡 辞書の便利な使い方
• 追加 → pokemon["level"] = 5
• キー一覧 → pokemon.keys()
• 値一覧 → pokemon.values()

⚡ リストとの違い
• リスト → 番号で取り出す [0], [1]...
• 辞書 → 名前で取り出す ["name"], ["hp"]...
''',
      questions: [
        const Question(
          id: 'q_27_1',
          text: 'profile["name"]の結果は？',
          codeSnippet: 'profile = {"name": "太郎", "age": 10}',
          options: ['profile', '"name"', '"太郎"', '10'],
          correctIndex: 2,
          explanation: '辞書はキーを[]で指定して値を取り出します。"name"キーの値は"太郎"です。',
        ),
        const Question(
          id: 'q_27_2',
          text: '辞書に新しいキーと値を追加するには？',
          codeSnippet: 'd = {"x": 1}',
          options: [
            'd.append("y", 2)',
            'd["y"] = 2',
            'd.add("y", 2)',
            'd.push("y", 2)',
          ],
          correctIndex: 1,
          explanation: '辞書への追加・更新は d[キー] = 値 で行います。d["y"] = 2 で新しい要素が追加されます。',
        ),
        const Question(
          id: 'q_27_3',
          text: '辞書のキー一覧を取得するには？',
          codeSnippet: 'd = {"a": 1, "b": 2, "c": 3}',
          options: ['d.keys()', 'd.values()', 'list(d)', 'd.all()'],
          correctIndex: 0,
          explanation: 'd.keys()でキーの一覧が得られます。d.values()は値一覧、d.items()はキーと値のペア一覧です。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_28',
      stageNumber: 28,
      title: 'f文字列で整形しよう',
      description: '変数を文字列の中に埋め込む「f文字列」を使いこなそう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '✏️',
      isFree: true,
      conceptExplanation: '''
✏️ f文字列（エフもじれつ）ってなに？

変数を文字の中に直接入れられる、便利な書き方だよ！

📝 普通の書き方 vs f文字列

普通: "こんにちは、" + name + "！"  ← 面倒…
f文字: f"こんにちは、{name}！"      ← スッキリ！

🎮 ゲームで例えると…

score = 1200
name = "太郎"
print(f"プレイヤー {name} のスコアは {score} 点！")
→「プレイヤー 太郎 のスコアは 1200 点！」

💡 ポイント
• 文字列の前に f をつける
• 変数は { } で囲む
• { } の中で計算もできる！ f"答えは {5 + 3}"

⚡ 小数点の表示も自由自在！
pi = 3.14159
f"{pi:.2f}"  → "3.14"（小数点2桁）
''',
      questions: [
        const Question(
          id: 'q_28_1',
          text: 'このコードの出力は？',
          codeSnippet: 'name = "花子"\nprint(f"こんにちは、{name}！")',
          options: [
            'こんにちは、{name}！',
            'こんにちは、花子！',
            'こんにちは、name！',
            'エラー',
          ],
          correctIndex: 1,
          explanation: 'f文字列（f"..."）では {変数名} で変数の値を文字列の中に埋め込めます。',
        ),
        const Question(
          id: 'q_28_2',
          text: 'f文字列で計算結果を埋め込むには？',
          codeSnippet: 'x = 5\ny = 3',
          options: [
            'f"答えは x + y"',
            'f"答えは {x + y}"',
            '"答えは " + x + y',
            'f"答えは (x+y)"',
          ],
          correctIndex: 1,
          explanation: 'f文字列の{}の中には式も書けます。{x + y}で足し算の結果が埋め込まれます。',
        ),
        const Question(
          id: 'q_28_3',
          text: '小数点2桁で表示するf文字列は？',
          codeSnippet: 'pi = 3.14159',
          options: [
            'f"{pi:.2}"',
            'f"{pi:.2f}"',
            'f"{pi,2}"',
            'f"{pi|2}"',
          ],
          correctIndex: 1,
          explanation: '{変数:.2f}で小数点以下2桁に丸めて表示できます。「.2f」の「f」はfloat（浮動小数点）を意味します。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_29',
      stageNumber: 29,
      title: '続けてくり返そう',
      description: '条件が続く限り繰り返す「while（続けてくり返し）」のPythonコードを学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🔄',
      isFree: false,
      conceptExplanation: '''
🔄 続けてくり返そう（while）

「while（ホワイル）」は「〜のあいだ、くり返す」という命令！
条件が続く限り、何度でも同じ処理をくり返せるんだ。

📝 基本の書き方

count = 0
while count < 3:       ← count が3未満のあいだ
    print("進め！")
    count += 1         ← 毎回1ずつ増やす

→「進め！」が3回表示される

🔧 break と continue

• break    → ループを途中で止める
• continue → その回をスキップして次へ

🎮 ゲームで例えると…

while 体力 > 0:        ← 体力があるあいだ
    戦う()
    体力 -= 敵のこうげき力

→ 体力が0になるまで戦い続ける！

⚠️ 注意！
while True: で「永遠にくり返す」こともできるけど、
break で止める条件を入れないと止まらなくなるよ！
''',
      questions: [
        const Question(
          id: 'q_29_1',
          text: 'このコードは何回「進め」と表示する？',
          codeSnippet: 'count = 0\nwhile count < 3:\n    print("進め")\n    count += 1',
          options: ['0回', '2回', '3回', '無限ループ'],
          correctIndex: 2,
          explanation: 'count = 0, 1, 2 のとき条件 count < 3 が True。count = 3 で終了。合計3回表示されます。',
        ),
        const Question(
          id: 'q_29_2',
          text: 'whileループを途中で抜けるには？',
          options: ['stop', 'exit', 'break', 'end'],
          correctIndex: 2,
          explanation: 'break 文でwhileループを即座に終了できます。条件に関係なくループを抜けます。',
        ),
        const Question(
          id: 'q_29_3',
          text: 'continueは何をする？',
          codeSnippet: 'for i in range(5):\n    if i == 3:\n        continue\n    print(i)',
          options: [
            'ループ全体を終了する',
            '次のループ反復へスキップする',
            'iを1増やす',
            '何もしない',
          ],
          correctIndex: 1,
          explanation: 'continue は現在の繰り返しをスキップして次へ進みます。i=3のとき print(i) が実行されません。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_30',
      stageNumber: 30,
      title: 'エラー処理を学ぼう',
      description: 'プログラムのエラーを上手に扱う「try/except」を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🛡️',
      isFree: false,
      conceptExplanation: '''
🛡️ エラーをキャッチしよう（try/except）

プログラムは予期しないエラーで止まることがある。
「try/except」を使えば、エラーが起きても続けられるんだ！

📝 基本の書き方

try:
    x = int("abc")       ← エラーが起きそうな処理
except ValueError:
    print("変換できません！")   ← エラーのときはここが動く

💡 3つのブロック

• try     → まず試してみる
• except  → エラーが起きたらここへ
• finally → エラーに関係なく、最後に必ず実行

🎮 ゲームで例えると…

try:
    セーブデータを読み込む()    ← ファイルを開こうとする
except FileNotFoundError:
    print("セーブデータがありません")   ← 初回プレイ用メッセージ

→ セーブがなくても、ゲームが強制終了しない！
→ これが「丈夫なプログラム」の作り方だよ
''',
      questions: [
        const Question(
          id: 'q_30_1',
          text: 'try/exceptの役割は？',
          options: [
            '処理を繰り返す',
            'エラーが起きても続けて実行できる',
            '変数に型をつける',
            '関数を定義する',
          ],
          correctIndex: 1,
          explanation: 'try: でエラーが起きそうな処理を書き、except: でエラー時の対応を書きます。プログラムが止まらなくなります。',
        ),
        const Question(
          id: 'q_30_2',
          text: 'このコードが表示するのは？',
          codeSnippet: 'try:\n    x = int("abc")\nexcept ValueError:\n    print("変換できません")',
          options: ['abc', 'エラー終了', '変換できません', 'None'],
          correctIndex: 2,
          explanation: '"abc"を整数に変換しようとすると ValueError が起きます。exceptで捕まえて「変換できません」と表示します。',
        ),
        const Question(
          id: 'q_30_3',
          text: 'finally ブロックはいつ実行される？',
          options: [
            'エラーが起きたときだけ',
            'エラーが起きなかったときだけ',
            '常に実行される',
            '条件による',
          ],
          correctIndex: 2,
          explanation: 'finally: は try/except の後に常に実行されます。ファイルを閉じる・後片付けをする処理に使います。',
        ),
      ],
    ),

    // ===== 上級: 応用 =====
    Challenge(
      id: 'stage_11',
      stageNumber: 11,
      title: '文字列を操作しよう',
      description: '文字列の便利な操作を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '📝',
      isFree: false,
      conceptExplanation: '''
📝 もじれつ（文字列）を操作しよう

「こんにちは！」のような文字の集まりを「もじれつ」というよ。
Pythonにはもじれつを便利に変える道具がたくさんある！

🔧 よく使う道具

• .upper()   → 全部大文字   "hello" → "HELLO"
• .lower()   → 全部小文字   "HELLO" → "hello"
• .replace() → 一部を入れかえる
• .split()   → バラバラに切り分ける

💡 使い方の例

name = "pikachu"
print(name.upper())
→ "PIKACHU"

text = "りんご,バナナ,みかん"
print(text.split(","))
→ ["りんご", "バナナ", "みかん"]

🎮 ゲームで例えると…
→ プレイヤー名を大文字で表示したり
→ チャットのNGワードを置き換えたり！
''',
      questions: [
        const Question(
          id: 'q_11_1',
          text: '"Hello".upper()の結果は？',
          options: ['hello', 'Hello', 'HELLO', 'エラー'],
          correctIndex: 2,
          explanation: 'upper()は文字列を全部大文字にします。',
        ),
        const Question(
          id: 'q_11_2',
          text: '"こんにちは世界".replace("世界","地球")の結果は？',
          options: [
            'こんにちは世界',
            'こんにちは地球',
            '地球世界',
            'こんにちは',
          ],
          correctIndex: 1,
          explanation: 'replace(old, new)で文字列の一部を置き換えます。',
        ),
        const Question(
          id: 'q_11_3',
          text: '"apple,banana,mango".split(",")の結果は？',
          options: [
            '"apple" "banana" "mango"',
            '["apple", "banana", "mango"]',
            '"apple,banana,mango"',
            'エラー',
          ],
          correctIndex: 1,
          explanation: 'split()は文字列を指定した区切り文字でリストに分割します。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_12',
      stageNumber: 12,
      title: 'ファイルを読もう',
      description: 'Pythonでファイルを読み書きする方法を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '📁',
      isFree: false,
      conceptExplanation: '''
📁 ファイルを読み書きしよう

コンピューターには、データを保存する「ファイル」があるよ。
Pythonでファイルを開いて、読んだり書いたりできるんだ！

📖 開き方の種類
• "r"（read）   → 読み込み（見るだけ）
• "w"（write）  → 書き込み（上書き保存）
• "a"（append） → 追加（末尾に足す）

🎮 ゲームで例えると…
→ セーブデータを読む      → "r"
→ スコアを保存する        → "w"
→ ランキングに追加する    → "a"

💡 おすすめの書き方（withを使う）

with open("data.txt", "r") as f:
    content = f.read()

「with」を使うと、ファイルを自動で閉じてくれるよ！
閉め忘れの心配なし。

⚠️ 注意
"w"で開くと、前のデータが消えるよ。
追加したいときは"a"を使おう！
''',
      questions: [
        const Question(
          id: 'q_12_1',
          text: 'ファイルを読み込む正しいコードは？',
          options: [
            'file = open("data.txt", "w")',
            'file = open("data.txt", "r")',
            'file = read("data.txt")',
            'file.open("data.txt")',
          ],
          correctIndex: 1,
          explanation: 'open(ファイル名, "r")でファイルを読み込みモードで開きます。"r"はread（読み込み）の意味。',
        ),
        const Question(
          id: 'q_12_2',
          text: 'with文を使う理由は？',
          codeSnippet: 'with open("data.txt") as f:\n    content = f.read()',
          options: [
            '速く実行できるから',
            '自動的にファイルを閉じてくれるから',
            'エラーが出ないから',
            '何もしない',
          ],
          correctIndex: 1,
          explanation: 'with文を使うと処理が終わった後に自動でファイルを閉じてくれます。ファイルの閉め忘れを防げます。',
        ),
        const Question(
          id: 'q_12_3',
          text: 'ファイルに書き込むモードは？',
          options: ['"r"（read）', '"w"（write）', '"x"（execute）', '"a"（all）'],
          correctIndex: 1,
          explanation: '"w"はwrite（書き込み）モードです。既存の内容を上書きします。追記は"a"（append）を使います。',
        ),
      ],
    ),
    // ===== 初級追加: ビジュアルプログラミング応用 =====
    Challenge(
      id: 'stage_13',
      stageNumber: 13,
      title: '三角を描こう',
      description: '3回同じ動きを繰り返して三角形を描こう！120°ずつ回転するよ。',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🔺',
      isFree: true,
      expectedOutput: 'repeat(3):\n  move_forward(100)\n  turn_right(120)',
      hints: ['繰り返しは3回だよ', '三角形は120°ずつ回るよ', '「前に進む」→「右に120°回転」を繰り返そう'],
    ),
    Challenge(
      id: 'stage_14',
      stageNumber: 14,
      title: 'ジグザグ道を進もう',
      description: '右に45°、左に45°を交互に使ってジグザグに進もう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '〰️',
      isFree: true,
      expectedOutput: 'move_forward(100)\nturn_right(45)\nmove_forward(100)\nturn_left(45)\nmove_forward(100)',
      hints: ['斜めに進んでから方向を変えよう', '右・左と交互に使うよ'],
    ),
    Challenge(
      id: 'stage_15',
      stageNumber: 15,
      title: '入れ物で数えよう',
      description: '入れ物「count」を使ってロボットが何歩進んだか数えてみよう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🔢',
      isFree: true,
      expectedOutput: 'set_variable(count=0)\nmove_forward(100)\nadd_variable',
      hints: ['まず変数を0にセットしよう', '進んだ後に変数に1を足そう'],
    ),

    // ===== 中級追加: Pythonクイズ応用 =====
    Challenge(
      id: 'stage_16',
      stageNumber: 16,
      title: 'リストを使いこなそう',
      description: 'Pythonのリスト（まとめ入れ物）の操作をさらに深く学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🗒️',
      isFree: true,
      conceptExplanation: '''
🗒️ リスト（list）をさらに使いこなそう！

リストは、たくさんのデータをならべておける「箱」だよ。
今回は、リストをもっと便利に使うわざを学ぼう！

📦 リストの基本おさらい

fruits = ["りんご", "バナナ", "みかん"]
→ [0]番、[1]番、[2]番…と番号で取り出す

fruits[0]  → "りんご"
fruits[1]  → "バナナ"

🔧 よく使う道具

• fruits.append("ぶどう") → 末尾に追加する
• len(fruits)             → いくつあるか数える
• fruits.remove("バナナ") → 特定のものを消す

🎮 ゲームで例えると…
→ 「アイテムぶくろ」みたいなもの！
  .append() でアイテムを入れる
  .remove() でアイテムを使う
  len() で残りのアイテム数を数える！
''',
      questions: [
        const Question(
          id: 'q_16_1',
          text: 'リストの最初の要素を取り出すには？',
          codeSnippet: 'fruits = ["りんご", "バナナ", "みかん"]',
          options: ['fruits[0]', 'fruits[1]', 'fruits.first', 'fruits.get(0)'],
          correctIndex: 0,
          explanation: 'リストは0から始まるインデックスで要素を取り出します。fruits[0]は「りんご」です。',
        ),
        const Question(
          id: 'q_16_2',
          text: 'リストに要素を追加するメソッドは？',
          codeSnippet: 'fruits = ["りんご", "バナナ"]\nfruits.____("みかん")',
          options: ['add()', 'append()', 'push()', 'insert()'],
          correctIndex: 1,
          explanation: 'append()でリストの末尾に要素を追加できます。fruits.append("みかん")とすると3つ目に追加されます。',
        ),
        const Question(
          id: 'q_16_3',
          text: 'リストの長さを調べるには？',
          codeSnippet: 'nums = [10, 20, 30, 40, 50]',
          options: ['nums.size', 'nums.count()', 'len(nums)', 'nums.length'],
          correctIndex: 2,
          explanation: 'len()関数でリストの要素数を調べられます。len(nums)は5を返します。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_17',
      stageNumber: 17,
      title: '辞書の基本',
      description: 'Pythonの辞書（dict）でキーと値のペアを扱おう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '📖',
      isFree: true,
      conceptExplanation: '''
📖 じしょ（辞書・dict）の基本

「辞書」は「名前（キー）」と「データ（値）」を
セットで管理できる入れ物だよ！

📝 書き方

person = {"なまえ": "太郎", "ねんれい": 10}

取り出し方:
→ person["なまえ"]   → "太郎"
→ person["ねんれい"] → 10

🔧 よく使うわざ

• 追加    → person["すきなもの"] = "ゲーム"
• 確認    → "なまえ" in person  → True
• キー一覧 → person.keys()
• 値一覧  → person.values()

🎮 ゲームで例えると…
→ ポケモンのずかんデータみたいなもの！

pikachu = {
  "なまえ": "ピカチュウ",
  "タイプ": "でんき",
  "HP": 100
}
''',
      questions: [
        const Question(
          id: 'q_17_1',
          text: '辞書から「名前」を取り出すには？',
          codeSnippet: 'person = {"名前": "太郎", "年齢": 10}',
          options: [
            'person.名前',
            'person["名前"]',
            'person.get名前()',
            'person[0]',
          ],
          correctIndex: 1,
          explanation: '辞書はperson["キー名"]でアクセスします。person["名前"]は「太郎」を返します。',
        ),
        const Question(
          id: 'q_17_2',
          text: '辞書に新しいキーを追加するには？',
          codeSnippet: 'data = {"x": 1}\ndata.____ = 2',
          options: ['data["y"] = 2', 'data.add("y", 2)', 'data.insert("y", 2)', 'data.set(y=2)'],
          correctIndex: 0,
          explanation: 'data["新しいキー"] = 値 で辞書に新しいペアを追加できます。',
        ),
        const Question(
          id: 'q_17_3',
          text: 'このコードの結果は？',
          codeSnippet: 'scores = {"国語": 80, "算数": 95}\nprint(scores["算数"])',
          options: ['80', '95', '"算数"', 'エラー'],
          correctIndex: 1,
          explanation: 'scores["算数"]で算数の値95を取り出します。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_18',
      stageNumber: 18,
      title: '動きを使いこなそう',
      description: 'Pythonで自分だけの「動き（関数・def）」を作れるようになろう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '⚙️',
      isFree: true,
      conceptExplanation: '''
⚙️ 関数（def）をさらに使いこなそう！

「関数」は、よく使う命令のかたまりに名前をつけたもの。
いつでも呼び出せる「自分だけのブロック」が作れるんだ！

📝 関数の書き方おさらい

def あいさつ(name):
    print("こんにちは、" + name + "！")

あいさつ("太郎")  →「こんにちは、太郎！」
あいさつ("花子")  →「こんにちは、花子！」

🔧 return（返り値）のある関数

def たし算(a, b):
    return a + b

result = たし算(3, 5)  → result = 8

💡 return があると計算結果を受け取れる！

🎮 ゲームで例えると…
→ 「こうげき！」ボタンで attackPlayer() 関数が動く！
  毎回同じ処理を1か所にまとめると、
  あとで変更するのもカンタン！
''',
      questions: [
        const Question(
          id: 'q_18_1',
          text: '関数を定義するキーワードは？',
          options: ['function', 'def', 'func', 'define'],
          correctIndex: 1,
          explanation: 'Pythonでは def キーワードで関数を定義します。def 関数名(): のように書きます。',
        ),
        const Question(
          id: 'q_18_2',
          text: 'このコードの実行結果は？',
          codeSnippet: 'def greet(name):\n    print("こんにちは、" + name)\n\ngreet("花子")',
          options: ['greet(花子)', 'こんにちは、花子', 'こんにちは、name', 'エラー'],
          correctIndex: 1,
          explanation: 'greet("花子")を呼び出すとnameに「花子」が入り、「こんにちは、花子」と表示されます。',
        ),
        const Question(
          id: 'q_18_3',
          text: '値を返す（return）関数の結果を使うには？',
          codeSnippet: 'def double(n):\n    return n * 2\n\nresult = ____',
          options: ['double(5)', 'call double(5)', 'return double(5)', 'get double(5)'],
          correctIndex: 0,
          explanation: 'result = double(5) で関数を呼び出し、戻り値10をresultに代入できます。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_19',
      stageNumber: 19,
      title: 'エラーを直そう',
      description: 'Pythonのエラーメッセージを読んでバグを直す方法を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🐛',
      isFree: true,
      conceptExplanation: '''
🐛 エラーを見つけて直そう！（デバッグ）

プログラムがうまく動かないとき、Pythonは「エラーメッセージ」で
何が間違いか教えてくれるよ。エラーは「失敗」じゃなくて「ヒント」！

🚨 よくあるエラー3種類

① NameError（なまえエラー）
name = "太郎"
print(Name)   → エラー！
理由: name と Name は別物（大文字と小文字が違う！）

② IndentationError（字下げエラー）
for i in range(3):
print(i)   → エラー！
理由: for の後はスペース4つの字下げが必要！

③ ZeroDivisionError（ゼロで割った）
10 / 0   → エラー！
理由: 数学と同じで 0 では割れない

🔍 デバッグのコツ
→ エラーの「行番号」を見る
→ 変数名のスペルをチェック
→ インデント（字下げ）を確認する
''',
      questions: [
        const Question(
          id: 'q_19_1',
          text: 'このコードのエラーの原因は？',
          codeSnippet: 'name = "たろう"\nprint(Name)',
          options: [
            '文字列にダブルクォートを使っているから',
            '変数名が大文字と小文字で違うから',
            'printの書き方が違うから',
            'nameが短すぎるから',
          ],
          correctIndex: 1,
          explanation: 'Pythonは大文字・小文字を区別します。name と Name は別の変数です。NameError: name "Name" is not defined というエラーになります。',
        ),
        const Question(
          id: 'q_19_2',
          text: 'IndentationError が出た。何が間違い？',
          codeSnippet: 'for i in range(3):\nprint(i)',
          options: [
            'range()の引数が違う',
            'printのスペルミス',
            'インデント（字下げ）が足りない',
            'forの書き方が違う',
          ],
          correctIndex: 2,
          explanation: 'forやif、defの後はインデント（スペース4つかタブ）が必要です。print(i)の前に字下げを入れましょう。',
        ),
        const Question(
          id: 'q_19_3',
          text: 'ZeroDivisionError を防ぐには？',
          codeSnippet: 'def divide(a, b):\n    return a / b\n\ndivide(10, 0)',
          options: [
            'try-except でエラーをキャッチする',
            'bを1に変える',
            'floatに変換する',
            'returnを削除する',
          ],
          correctIndex: 0,
          explanation: 'try-except を使うとエラーが起きてもプログラムが止まらずに処理を続けられます。ゼロ除算など予測できるエラーに使います。',
        ),
      ],
    ),
    // ===== 初級追加: 新ブロック応用 =====
    Challenge(
      id: 'stage_21',
      stageNumber: 21,
      title: 'くり返しブロックを使おう',
      description: '「くり返し」ブロックで3回繰り返して進んでみよう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🔄',
      isFree: true,
      expectedOutput: 'while_loop(3):\n  move_forward(100)',
      hints: ['「whileループ」を選んで3回に設定しよう', 'ループの後に「前に進む」を置こう'],
    ),
    Challenge(
      id: 'stage_22',
      stageNumber: 22,
      title: 'もし〜ならばを使おう',
      description: '「もし〜ならば」ブロックで条件によって動きを変えてみよう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🔱',
      isFree: true,
      expectedOutput: 'if_condition:\n  move_forward(100)',
      hints: ['「もし〜ならば」ブロックを置こう', 'その後に「前に進む」を追加しよう'],
    ),
    Challenge(
      id: 'stage_23',
      stageNumber: 23,
      title: '表示ブロックを使おう',
      description: '「表示する」ブロックでメッセージを出してから進もう！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '📢',
      isFree: true,
      expectedOutput: 'print_block\nmove_forward(100)',
      hints: ['「表示する」ブロックを最初に置こう', '次に「前に進む」を追加しよう'],
    ),
    Challenge(
      id: 'stage_24',
      stageNumber: 24,
      title: 'くり返して三角を描こう',
      description: 'くり返しブロックを使って三角形を描こう！3回、前進・回転を繰り返すよ。',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🔻',
      isFree: true,
      expectedOutput: 'while_loop(3):\n  move_forward(100)\n  turn_right(120)',
      hints: ['whileループを3回に設定しよう', 'ループ内に「前に進む」→「右に120°回転」を入れよう'],
    ),
    Challenge(
      id: 'stage_25',
      stageNumber: 25,
      title: '組み合わせチャレンジ',
      description: '表示→条件→ループをすべて組み合わせた最終チャレンジ！',
      type: ChallengeType.visual,
      level: StageLevel.beginner,
      icon: '🏅',
      isFree: true,
      expectedOutput: 'print_block\nif_condition:\n  while_loop(3):\n    move_forward(100)',
      hints: ['最初に「表示する」を置こう', '次に「もし〜ならば」→「whileループ」→「前に進む」の順で'],
    ),
    // ===== 上級追加: Python発展ステージ 31〜40 =====
    Challenge(
      id: 'stage_31',
      stageNumber: 31,
      title: 'リストを1行で作ろう',
      description: '1行でリストを作れる便利な書き方をマスターしよう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '⚡',
      isFree: false,
      conceptExplanation: '''
⚡ リストを1行で作ろう（リスト内包表記）

「リスト内包表記」は、forループをたった1行に
スッキリまとめられる Pythonの超便利わざ！

📝 普通のやり方 vs 内包表記

【普通の書き方】
doubles = []
for x in range(4):
    doubles.append(x * 2)
→ [0, 2, 4, 6]

【内包表記（1行で同じことができる！）】
doubles = [x * 2 for x in range(4)]
→ [0, 2, 4, 6]

🔧 条件付きフィルター

# 偶数だけ取り出す
evens = [x for x in range(10) if x % 2 == 0]
→ [0, 2, 4, 6, 8]

書き方のポイント: [何を入れる for 変数 in リスト]
条件付き:        [何を入れる for 変数 in リスト if 条件]

🎮 ゲームで例えると…
# HPが50以上の敵だけ残す
alive = [e for e in enemies if e["hp"] > 50]
''',
      questions: [
        const Question(
          id: 'q_31_1',
          text: 'このリスト内包表記の結果は？',
          codeSnippet: 'result = [x * 2 for x in range(4)]',
          options: ['[0, 2, 4, 6]', '[2, 4, 6, 8]', '[0, 1, 2, 3]', 'エラー'],
          correctIndex: 0,
          explanation: 'range(4)は0,1,2,3。それぞれ×2すると[0,2,4,6]になります。',
        ),
        const Question(
          id: 'q_31_2',
          text: '偶数だけ取り出す内包表記は？',
          codeSnippet: 'nums = [1, 2, 3, 4, 5, 6]',
          options: [
            '[x for x in nums if x % 2 == 0]',
            '[x if x % 2 == 0 for x in nums]',
            '[x for x % 2 == 0 in nums]',
            'filter(nums, x % 2 == 0)',
          ],
          correctIndex: 0,
          explanation: 'リスト内包表記の末尾に if 条件 を付けると絞り込みができます。x % 2 == 0 で偶数だけ選べます。',
        ),
        const Question(
          id: 'q_31_3',
          text: '次の2つのコードは同じ結果になる？',
          codeSnippet: '# A\nsquares = []\nfor n in range(5):\n    squares.append(n ** 2)\n\n# B\nsquares = [n ** 2 for n in range(5)]',
          options: ['同じ結果になる', 'Aは[0,1,4,9,16]、Bは違う', 'Bだけエラー', '全く違う'],
          correctIndex: 0,
          explanation: 'リスト内包表記はforループを1行に書いたもの。結果は[0,1,4,9,16]で同じです。内包表記の方が短く速く書けます。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_32',
      stageNumber: 32,
      title: '辞書内包表記',
      description: '辞書もワンライナーで作れる「辞書内包表記」を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '📚',
      isFree: false,
      questions: [
        const Question(
          id: 'q_32_1',
          text: 'この辞書内包表記の結果は？',
          codeSnippet: 'd = {k: v for k, v in [("a", 1), ("b", 2)]}',
          options: [
            '{"a": 1, "b": 2}',
            '[("a", 1), ("b", 2)]',
            '{"k": "v"}',
            'エラー',
          ],
          correctIndex: 0,
          explanation: '{k: v for k, v in リスト} でタプルのリストを辞書に変換できます。{"a": 1, "b": 2}になります。',
        ),
        const Question(
          id: 'q_32_2',
          text: '辞書のキーと値を入れ替えるコードは？',
          codeSnippet: 'orig = {"a": 1, "b": 2, "c": 3}',
          options: [
            '{v: k for k, v in orig.items()}',
            '{k: v for v, k in orig.items()}',
            'orig.swap()',
            'dict.flip(orig)',
          ],
          correctIndex: 0,
          explanation: 'orig.items()でキーと値のペアを取り出し、{v: k ...}で入れ替えた辞書を作れます。',
        ),
        const Question(
          id: 'q_32_3',
          text: 'ネストした辞書のアクセス方法は？',
          codeSnippet: 'data = {"user": {"name": "太郎", "age": 12}}',
          options: [
            'data["user"]["name"]',
            'data["user.name"]',
            'data.user.name',
            'data[0]["name"]',
          ],
          correctIndex: 0,
          explanation: 'ネストした辞書は data["外側キー"]["内側キー"] でアクセスします。data["user"]["name"]は"太郎"を返します。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_33',
      stageNumber: 33,
      title: '設計図を引き継ごう',
      description: 'クラス（設計図）を受け継いで機能を追加する方法を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🧬',
      isFree: false,
      questions: [
        const Question(
          id: 'q_33_1',
          text: 'Pythonで継承はどう書く？',
          codeSnippet: 'class Animal:\n    def speak(self):\n        print("...")\n\nclass Dog(____):',
          options: ['Animal', 'extends Animal', 'inherits Animal', ':Animal'],
          correctIndex: 0,
          explanation: 'class 子クラス(親クラス): と書くと継承できます。Dogはclass Dog(Animal):となります。',
        ),
        const Question(
          id: 'q_33_2',
          text: '子クラスから親クラスのメソッドを呼ぶには？',
          codeSnippet: 'class Cat(Animal):\n    def __init__(self):\n        ____._____()',
          options: ['super().__init__()', 'parent().__init__()', 'Animal().__init__()', 'base.__init__()'],
          correctIndex: 0,
          explanation: 'super() で親クラスを参照できます。super().__init__() で親の初期化を呼び出せます。',
        ),
        const Question(
          id: 'q_33_3',
          text: 'メソッドのオーバーライドとは？',
          options: [
            '親クラスのメソッドを子クラスで再定義すること',
            '新しいメソッドを追加すること',
            'メソッドを削除すること',
            'メソッドの引数を増やすこと',
          ],
          correctIndex: 0,
          explanation: 'オーバーライドは親クラスと同名のメソッドを子クラスで定義し直すことです。子クラス固有の動作に変更できます。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_34',
      stageNumber: 34,
      title: '道具箱を使おう',
      description: '作ったコードを再利用できる「道具箱（モジュール）」の使い方を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '📦',
      isFree: false,
      questions: [
        const Question(
          id: 'q_34_1',
          text: 'randomモジュールをインポートするには？',
          options: [
            'import random',
            'include random',
            'use random',
            'require random',
          ],
          correctIndex: 0,
          explanation: 'Pythonは import モジュール名 でモジュールを読み込みます。importはPython固有のキーワードです。',
        ),
        const Question(
          id: 'q_34_2',
          text: 'mathモジュールのsqrt関数だけを使うには？',
          options: [
            'from math import sqrt',
            'import math.sqrt',
            'include math { sqrt }',
            'using math.sqrt',
          ],
          correctIndex: 0,
          explanation: 'from モジュール名 import 関数名 で特定の関数だけ取り込めます。その後は sqrt(4) のように直接呼べます。',
        ),
        const Question(
          id: 'q_34_3',
          text: 'import random as r と書くと？',
          options: [
            'random をr という短い名前で使える',
            'rという別のモジュールを読む',
            'エラーになる',
            'randomをr回インポートする',
          ],
          correctIndex: 0,
          explanation: 'as で別名（エイリアス）を付けられます。import numpy as np などよく使われるパターンです。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_35',
      stageNumber: 35,
      title: 'map/filterを使おう',
      description: 'リストをスマートに処理する「map」と「filter」を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🗂️',
      isFree: false,
      questions: [
        const Question(
          id: 'q_35_1',
          text: 'このコードの結果は？',
          codeSnippet: 'nums = [1, 2, 3, 4]\nresult = list(map(lambda x: x * 3, nums))',
          options: ['[1, 2, 3, 4]', '[3, 6, 9, 12]', '[4, 5, 6, 7]', 'エラー'],
          correctIndex: 1,
          explanation: 'map(関数, リスト) でリストの各要素に関数を適用します。×3 なので[3,6,9,12]になります。',
        ),
        const Question(
          id: 'q_35_2',
          text: 'filterの役割は？',
          codeSnippet: 'nums = [1, 2, 3, 4, 5]\nodd = list(filter(lambda x: x % 2 != 0, nums))',
          options: [
            '全要素に変換を適用する',
            '条件を満たす要素だけを残す',
            'リストを並び替える',
            'リストを結合する',
          ],
          correctIndex: 1,
          explanation: 'filter(条件関数, リスト) で条件がTrueの要素だけを残します。奇数のみ → [1,3,5]になります。',
        ),
        const Question(
          id: 'q_35_3',
          text: 'lambda x: x + 1 と同じ通常関数は？',
          options: [
            'def f(x): return x + 1',
            'def f(): x + 1',
            'func f(x) = x + 1',
            'f = x + 1',
          ],
          correctIndex: 0,
          explanation: 'lambda は無名の関数を1行で書く記法です。lambda x: x + 1 は def f(x): return x + 1 と同じ意味です。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_36',
      stageNumber: 36,
      title: 'ソートをマスター',
      description: 'リストや辞書を自在に並び替える「sort」の使い方を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🔢',
      isFree: false,
      questions: [
        const Question(
          id: 'q_36_1',
          text: 'sorted([3,1,4,1,5])の結果は？',
          options: ['[1, 1, 3, 4, 5]', '[5, 4, 3, 1, 1]', '[3, 1, 4, 1, 5]', 'エラー'],
          correctIndex: 0,
          explanation: 'sorted()は昇順（小さい順）のソートされた新しいリストを返します。元のリストは変わりません。',
        ),
        const Question(
          id: 'q_36_2',
          text: '降順にソートするには？',
          codeSnippet: 'nums = [3, 1, 4, 1, 5]',
          options: [
            'sorted(nums, reverse=True)',
            'sorted(nums, order="desc")',
            'nums.sort(down=True)',
            'reverse(sorted(nums))',
          ],
          correctIndex: 0,
          explanation: 'sorted() に reverse=True を渡すと降順になります。[5,4,3,1,1]が返ります。',
        ),
        const Question(
          id: 'q_36_3',
          text: '名前の長さでリストをソートするには？',
          codeSnippet: 'names = ["花子", "太郎さん", "はな"]',
          options: [
            'sorted(names, key=len)',
            'sorted(names, by=len)',
            'names.sort(key="len")',
            'sorted(names, length=True)',
          ],
          correctIndex: 0,
          explanation: 'key= に関数を渡すとその関数の結果を基準にソートします。key=len で文字数順になります。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_37',
      stageNumber: 37,
      title: '文字列メソッド応用',
      description: '文字列を自在に操る高度なメソッドをマスターしよう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🔤',
      isFree: false,
      questions: [
        const Question(
          id: 'q_37_1',
          text: '"  hello  ".strip()の結果は？',
          options: ['"hello"', '"  hello  "', '"hello  "', 'エラー'],
          correctIndex: 0,
          explanation: 'strip()は文字列の前後の空白を取り除きます。lstrip()は左のみ、rstrip()は右のみ取り除きます。',
        ),
        const Question(
          id: 'q_37_2',
          text: '"-".join(["a","b","c"])の結果は？',
          options: ['"a-b-c"', '"abc"', '["a-","b-","c"]', 'エラー'],
          correctIndex: 0,
          explanation: 'join()はリストの要素を指定した区切り文字でつなげます。"-".join(...)で"a-b-c"ができます。',
        ),
        const Question(
          id: 'q_37_3',
          text: '"hello world".startswith("hello")は？',
          options: ['True', 'False', '"hello"', 'エラー'],
          correctIndex: 0,
          explanation: 'startswith()は文字列が指定した文字で始まるか確認します。"hello world"は"hello"で始まるのでTrueです。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_38',
      stageNumber: 38,
      title: 'mathモジュール',
      description: '数学計算に便利な「mathモジュール」の関数を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🔭',
      isFree: false,
      questions: [
        const Question(
          id: 'q_38_1',
          text: 'math.sqrt(16)の結果は？',
          options: ['2.0', '4.0', '8.0', 'エラー'],
          correctIndex: 1,
          explanation: 'sqrt()は平方根を返します。√16 = 4.0 です。結果はfloat型になります。',
        ),
        const Question(
          id: 'q_38_2',
          text: 'math.floor(3.9)の結果は？',
          options: ['3', '4', '3.9', '3.0'],
          correctIndex: 0,
          explanation: 'floor()は切り捨て（床関数）です。3.9を切り捨てると3になります。反対のceil()は切り上げです。',
        ),
        const Question(
          id: 'q_38_3',
          text: '円周率πを使うには？',
          options: ['math.pi', 'math.PI', 'math.pie', '3.14'],
          correctIndex: 0,
          explanation: 'math.pi で円周率（3.141592...）が使えます。面積 = math.pi * r**2 のように活用します。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_39',
      stageNumber: 39,
      title: 'ジェネレーター入門',
      description: 'メモリに優しい「ジェネレーター」とyieldを学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '⚙️',
      isFree: false,
      questions: [
        const Question(
          id: 'q_39_1',
          text: 'ジェネレーター関数を作るキーワードは？',
          options: ['yield', 'generate', 'return', 'produce'],
          correctIndex: 0,
          explanation: 'yield を使った関数がジェネレーター関数です。yield は値を1つずつ返し、次の呼び出しまで処理を一時停止します。',
        ),
        const Question(
          id: 'q_39_2',
          text: 'このコードは何を出力する？',
          codeSnippet: 'def count_up(n):\n    for i in range(n):\n        yield i\n\nfor v in count_up(3):\n    print(v)',
          options: ['0\n1\n2', '1\n2\n3', '[0,1,2]', 'エラー'],
          correctIndex: 0,
          explanation: 'ジェネレーターはyieldで値を1つずつ生成します。range(3)は0,1,2なので0,1,2が順に出力されます。',
        ),
        const Question(
          id: 'q_39_3',
          text: 'ジェネレーターのメリットは？',
          options: [
            '一度に全データをメモリに載せず省メモリ',
            '通常の関数より常に速い',
            'エラーが起きない',
            'コードが長くなる',
          ],
          correctIndex: 0,
          explanation: 'ジェネレーターは値を1つずつ生成するため、大量データでもメモリを使いすぎません。巨大なファイルの行を読む場合などに有効です。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_40',
      stageNumber: 40,
      title: '総合チャレンジ',
      description: 'これまで学んだPythonの知識を総まとめ！最終ステージに挑もう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🏆',
      isFree: false,
      questions: [
        const Question(
          id: 'q_40_1',
          text: 'このコードの最終的な出力は？',
          codeSnippet: 'class Counter:\n    def __init__(self):\n        self.count = 0\n    def increment(self):\n        self.count += 1\n        return self\n\nc = Counter()\nc.increment().increment().increment()\nprint(c.count)',
          options: ['1', '2', '3', 'エラー'],
          correctIndex: 2,
          explanation: 'increment()はself（自分自身）を返します。メソッドチェーンで3回呼べます。self.count が3回増えて3になります。',
        ),
        const Question(
          id: 'q_40_2',
          text: '次のコードの出力は？',
          codeSnippet: 'data = [3, 1, 4, 1, 5, 9, 2, 6]\ntop3 = sorted(data, reverse=True)[:3]\nprint(sum(top3))',
          options: ['15', '18', '20', '24'],
          correctIndex: 2,
          explanation: '降順ソート→[9,6,5,4,3,2,1,1]。スライス[:3]→[9,6,5]。sum([9,6,5])=20です。',
        ),
        const Question(
          id: 'q_40_3',
          text: '最も Pythonicな書き方は？',
          codeSnippet: '# 偶数のみ2乗したリストを作る\nnums = [1, 2, 3, 4, 5, 6]',
          options: [
            '[x**2 for x in nums if x % 2 == 0]',
            'list(map(lambda x: x**2, filter(lambda x: x%2==0, nums)))',
            'result = []\nfor x in nums:\n    if x % 2 == 0:\n        result.append(x**2)',
            'どれも同じ',
          ],
          correctIndex: 0,
          explanation: 'リスト内包表記が最もPythonらしい（Pythonicな）書き方です。短く、読みやすく、パフォーマンスも良いです。結果は[4, 16, 36]です。',
        ),
      ],
    ),

    // ===== 中級追加: 新概念ステージ (41-45) =====
    Challenge(
      id: 'stage_41',
      stageNumber: 41,
      title: 'キーボード入力を受け取ろう',
      description: 'ユーザーからの入力を受け取る「input()」の使い方を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '⌨️',
      isFree: false,
      conceptExplanation: '''
⌨️ キーボードから入力を受け取ろう（input）

「input()」を使うと、プログラムがユーザーから
文字や数字を受け取れるよ！

📝 基本の使い方

name = input("名前を入れてね: ")
print("こんにちは、" + name + "！")

→ 「太郎」と入力すると「こんにちは、太郎！」と表示される

⚠️ 大事なポイント！

input() は「文字列（str）」として受け取るよ。
→ 数字を計算したいときは変換が必要！

普通:  age = input("年齢: ")        → "12"（文字列）
変換:  age = int(input("年齢: "))   → 12（整数）

💡 変換の種類
• int()   → 整数に変換
• float() → 小数に変換
• str()   → 文字列に変換

🎮 ゲームで例えると…
name = input("プレイヤー名: ")
print(f"{name}、冒険の旅へようこそ！")
→ 自分の名前がゲームに出てくる！
''',
      questions: [
        const Question(
          id: 'q_41_1',
          text: 'ユーザーから文字を受け取るコードは？',
          options: [
            'name = input("名前は？")',
            'name = read("名前は？")',
            'name = get("名前は？")',
            'name = scan("名前は？")',
          ],
          correctIndex: 0,
          explanation: 'input("メッセージ") でキーボードから入力を受け取ります。入力した内容は文字列（str）として返ります。',
          hint: 'キーボードからの「入れる（input）」→ input() だよ。',
        ),
        const Question(
          id: 'q_41_2',
          text: '数字を入力してもらい計算するには？',
          codeSnippet: 'x = input("数を入力：")\nresult = x + 5',
          options: [
            'このままでOK',
            'x = int(input("数を入力：")) に変える',
            'x = float(input("数を入力：")) に変える',
            'result = str(x) + 5 に変える',
          ],
          correctIndex: 1,
          explanation: 'input() は常に文字列を返します。数字として使うには int() か float() で変換が必要です。',
          hint: 'input() で受け取った "5" は文字列。足し算するには数字に変換しよう。',
        ),
        const Question(
          id: 'q_41_3',
          text: 'このコードの実行結果は？（「太郎」と入力した場合）',
          codeSnippet: 'name = input("名前：")\nprint(f"こんにちは、{name}！")',
          options: [
            'こんにちは、name！',
            'こんにちは、太郎！',
            'こんにちは、{name}！',
            'エラー',
          ],
          correctIndex: 1,
          explanation: 'input() で「太郎」を受け取り、f文字列で埋め込むと「こんにちは、太郎！」と表示されます。',
          hint: 'f文字列の {} の中には変数を入れられるよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_42',
      stageNumber: 42,
      title: 'タプル（変わらないリスト）',
      description: '変更できないデータをまとめる「タプル」を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🔒',
      isFree: false,
      conceptExplanation: '''
🔒 変えられないリスト（タプル・tuple）

「タプル」は、リストと似ているけど
「一度作ったら変えられない」入れ物だよ！

📝 リストとタプルの違い

リスト  → fruits = ["りんご", "バナナ"]   ← [ ] 変えられる
タプル  → point  = (10, 20)              ← ( ) 変えられない

取り出し方はリストと同じ！
point = (10, 20, 30)
point[0]  → 10
point[1]  → 20

💡 タプルを使う場面

• GPS座標（緯度・経度）   → (35.68, 139.76)
• RGBカラー             → (255, 0, 0)  ← 赤色
• 変わってはいけないデータ

🎮 ゲームで例えると…

# スタート地点（変えてはいけない）
start_pos = (3, 5)   ← x=3、y=5の場所

# リストなら間違えて変えてしまうかも…
# タプルなら変えようとするとエラーになるので安全！
''',
      questions: [
        const Question(
          id: 'q_42_1',
          text: 'タプルの作り方は？',
          options: [
            'colors = ["赤", "青", "緑"]',
            'colors = ("赤", "青", "緑")',
            'colors = {"赤", "青", "緑"}',
            'colors = <"赤", "青", "緑">',
          ],
          correctIndex: 1,
          explanation: 'タプルは () で作ります。リストの [] と似ていますが、一度作ると変更できません。',
          hint: '丸いカッコ () を使うよ。',
        ),
        const Question(
          id: 'q_42_2',
          text: 'タプルの2番目の要素を取り出すには？',
          codeSnippet: 'point = (10, 20, 30)',
          options: ['point[1]', 'point[2]', 'point.get(1)', 'point.second'],
          correctIndex: 0,
          explanation: 'タプルもリストと同じく [インデックス] でアクセスします。インデックスは0から始まるのでpoint[1]は20です。',
          hint: 'インデックスは 0 から始まるよ。',
        ),
        const Question(
          id: 'q_42_3',
          text: 'リストではなくタプルを使う場面は？',
          options: [
            '後から要素を追加したいとき',
            '変更されては困る座標や定数を保存するとき',
            '要素を並び替えたいとき',
            '重複を除きたいとき',
          ],
          correctIndex: 1,
          explanation: 'タプルは変更不可（イミュータブル）です。GPS座標・RGBカラー値など「変わってはいけないデータ」に使います。',
          hint: '変わってほしくないデータには何が向いてるかな？',
        ),
      ],
    ),
    Challenge(
      id: 'stage_43',
      stageNumber: 43,
      title: 'セット（重複なしリスト）',
      description: '同じ値が入らない「セット（集合）」を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🎯',
      isFree: false,
      conceptExplanation: '''
🎯 かぶりなし！セット（set）

「セット」は、同じ値が絶対に入らない特別な入れ物！
重複（かぶり）を自動で消してくれるんだ。

📝 セットの作り方

s = {1, 2, 3, 3, 3}    ← 3が3つ入っているけど…
print(s)               → {1, 2, 3}  ← 1つになった！

💡 リストから重複を除く

nums = [1, 2, 2, 3, 3, 3, 4]
unique = set(nums)     → {1, 2, 3, 4}

🔧 セットの演算

a = {1, 2, 3, 4}
b = {3, 4, 5, 6}

a & b  → {3, 4}         ← 両方にある（共通）
a | b  → {1,2,3,4,5,6}  ← どちらかにある（全部）
a - b  → {1, 2}         ← aにだけある（差）

🎮 ゲームで例えると…
# クリア済みのステージ（かぶりを防ぐ）
cleared = {1, 3, 5}
cleared.add(3)    ← もう一度クリアしても
print(cleared)    → {1, 3, 5}  ← 変わらない！
''',
      questions: [
        const Question(
          id: 'q_43_1',
          text: 'このセットの要素数は？',
          codeSnippet: 's = {1, 2, 2, 3, 3, 3}',
          options: ['6', '3', '1', 'エラー'],
          correctIndex: 1,
          explanation: 'セットは重複を自動で除きます。{1, 2, 2, 3, 3, 3} → {1, 2, 3} となり要素数は3です。',
          hint: 'セットに同じ値は1つしか入れられないよ。',
        ),
        const Question(
          id: 'q_43_2',
          text: '2つのセットの共通部分を求めるには？',
          codeSnippet: 'a = {1, 2, 3, 4}\nb = {3, 4, 5, 6}',
          options: [
            'a & b',
            'a + b',
            'a | b',
            'a - b',
          ],
          correctIndex: 0,
          explanation: '& は積集合（共通部分）です。a & b は {3, 4} になります。| は和集合（どちらかにある全要素）です。',
          hint: '「両方に入っている」のを積集合（AND）というよ。',
        ),
        const Question(
          id: 'q_43_3',
          text: 'リストから重複を除く最も簡単な方法は？',
          codeSnippet: 'nums = [1, 2, 2, 3, 3, 3, 4]',
          options: [
            'unique = set(nums)',
            'unique = list.unique(nums)',
            'unique = nums.remove_duplicates()',
            'unique = nums[0:]',
          ],
          correctIndex: 0,
          explanation: 'set() でリストをセットに変換すると重複が除かれます。set([1,2,2,3,3,3,4]) → {1,2,3,4} になります。',
          hint: 'リストをセットに変換すれば重複は自動で消えるよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_44',
      stageNumber: 44,
      title: 'スライスで切り取ろう',
      description: 'リストや文字列の一部を切り取る「スライス」を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '✂️',
      isFree: false,
      conceptExplanation: '''
✂️ 一部を切り取ろう（スライス）

「スライス」は、リストや文字列の好きな部分だけ
切り取れる機能だよ！パンをスライスするイメージ。

📝 書き方

nums = [0, 10, 20, 30, 40]
       [0]  [1]  [2]  [3]  [4]

nums[1:3]   → [10, 20]        ← 1番から3番の手前まで
nums[:2]    → [0, 10]         ← 最初から2番の手前まで
nums[2:]    → [20, 30, 40]    ← 2番から最後まで
nums[::-1]  → [40, 30, 20, 10, 0]  ← 逆順！

💡 止まる番号は「含まれない」
[1:3] は インデックス1と2 → 3は含まない！

🎮 ゲームで例えると…
# ランキングのTOP3だけ取り出す
ranking = [100, 80, 70, 60, 50]
top3 = ranking[:3]    → [100, 80, 70]

# 文字列も同じようにスライスできる！
"こんにちは"[0:3]   → "こんに"
''',
      questions: [
        const Question(
          id: 'q_44_1',
          text: 'nums[1:3] の結果は？',
          codeSnippet: 'nums = [0, 10, 20, 30, 40]',
          options: [
            '[0, 10, 20]',
            '[10, 20]',
            '[10, 20, 30]',
            '[20, 30]',
          ],
          correctIndex: 1,
          explanation: 'スライス [start:stop] は start から stop-1 までを切り取ります。[1:3] はインデックス1,2 → [10, 20] です。',
          hint: 'stop の番号は含まれないよ。1から2番目まで。',
        ),
        const Question(
          id: 'q_44_2',
          text: '"こんにちは世界"[4:6] の結果は？',
          options: ['こんにちは', 'は世界', 'は世', 'こんに'],
          correctIndex: 2,
          explanation: '文字列もスライスできます。インデックス4は「は」、5は「世」です。4:6 → 「は世」になります。',
          hint: '「こ(0)ん(1)に(2)ち(3)は(4)世(5)界(6)」と数えてみよう。',
        ),
        const Question(
          id: 'q_44_3',
          text: 'nums[::-1] は何をする？',
          codeSnippet: 'nums = [1, 2, 3, 4, 5]',
          options: [
            'リストをコピーする',
            'リストを逆順にする',
            'リストの最後の要素を取る',
            'エラー',
          ],
          correctIndex: 1,
          explanation: '[::-1] は step=-1 でリスト全体を逆順に取り出します。[1,2,3,4,5] → [5,4,3,2,1] になります。',
          hint: 'ステップを -1 にすると逆向きに進むよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_45',
      stageNumber: 45,
      title: 'リストを検索・整理しよう',
      description: 'リストの中を探したり、並べ替えたりする便利な方法を学ぼう！',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🔍',
      isFree: false,
      questions: [
        const Question(
          id: 'q_45_1',
          text: 'リストに特定の値があるか調べるには？',
          codeSnippet: 'fruits = ["りんご", "バナナ", "みかん"]',
          options: [
            '"バナナ" in fruits',
            'fruits.contains("バナナ")',
            'fruits.has("バナナ")',
            'fruits.find("バナナ") != -1',
          ],
          correctIndex: 0,
          explanation: 'in 演算子で要素が含まれているか確認できます。"バナナ" in fruits は True を返します。',
          hint: '英語で「〜の中に」は "in" だよ。',
        ),
        const Question(
          id: 'q_45_2',
          text: '"バナナ" のインデックスを調べるには？',
          codeSnippet: 'fruits = ["りんご", "バナナ", "みかん"]',
          options: [
            'fruits.index("バナナ")',
            'fruits.find("バナナ")',
            'fruits.search("バナナ")',
            'index(fruits, "バナナ")',
          ],
          correctIndex: 0,
          explanation: '.index() で要素の位置（インデックス）を調べられます。"バナナ"はインデックス1なので1が返ります。',
          hint: '「位置（index）を調べる」メソッドを使おう。',
        ),
        const Question(
          id: 'q_45_3',
          text: 'リストの最大値・最小値を求めるには？',
          codeSnippet: 'scores = [85, 92, 78, 95, 88]',
          options: [
            'max(scores) と min(scores)',
            'scores.max() と scores.min()',
            'scores.largest() と scores.smallest()',
            'sort(scores)[-1] と sort(scores)[0]',
          ],
          correctIndex: 0,
          explanation: 'max() と min() は組み込み関数でリストの最大値・最小値を返します。max(scores)=95、min(scores)=78です。',
          hint: '「最大（max）」「最小（min）」の組み込み関数があるよ。',
        ),
      ],
    ),

    // ===== ミニプロジェクトステージ (46-50) =====
    Challenge(
      id: 'stage_46',
      stageNumber: 46,
      title: '✊ じゃんけんゲームを作ろう',
      description: 'じゃんけんゲームをステップで作りながらPythonを実感しよう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '✊',
      isFree: false,
      conceptExplanation: '''
✊ じゃんけんゲームを作ろう！

これまで学んだ知識を全部使って、じゃんけんゲームを作るよ！
「ゲームを作る = プログラミングを実践する」んだ！

🎮 じゃんけんゲームに使う道具

① ランダム（random）で手を選ぶ
import random
hands = ["グー", "チョキ", "パー"]
pc = random.choice(hands)     ← コンピューターが選ぶ

② 条件分岐（if/elif）で勝敗を判定
if player == "グー" and pc == "チョキ":
    print("勝ち！")   ← グーはチョキに勝つ

③ くり返し（for）で3回勝負
for round in range(3):
    # じゃんけんの処理

💡 ゲーム作りの流れ

「ルールを決める」
  ↓
「データを用意する」（手のリスト）
  ↓
「条件を書く」（勝ち負けの判定）
  ↓
「くり返す」（3回勝負）
''',
      questions: [
        const Question(
          id: 'q_46_1',
          text: 'じゃんけんの手をランダムに選ぶコードは？',
          codeSnippet: 'import random\nhands = ["グー", "チョキ", "パー"]\npc_hand = ____',
          options: [
            'random.choice(hands)',
            'random.select(hands)',
            'hands[random()]',
            'random.get(hands)',
          ],
          correctIndex: 0,
          explanation: 'random.choice(リスト) でリストからランダムに1つ選べます。じゃんけんの手をコンピュータに選ばせるのに最適です。',
          hint: '「選ぶ（choice）」という単語のメソッドがあるよ。',
        ),
        const Question(
          id: 'q_46_2',
          text: 'グー vs チョキ のとき勝ちと判定するコードは？',
          codeSnippet: 'player = "グー"\npc = "チョキ"\n# 勝ちの条件を書く',
          options: [
            'if (player == "グー" and pc == "チョキ") or (player == "チョキ" and pc == "パー") or (player == "パー" and pc == "グー"):\n    print("勝ち！")',
            'if player > pc:\n    print("勝ち！")',
            'if player != pc:\n    print("勝ち！")',
            'if player == "グー":\n    print("勝ち！")',
          ],
          correctIndex: 0,
          explanation: 'じゃんけんの勝ち条件は3通り。or でつなげて全ての勝ちパターンを判定します。',
          hint: 'グー>チョキ、チョキ>パー、パー>グーの3通りをorでつなごう。',
        ),
        const Question(
          id: 'q_46_3',
          text: '3回勝負にするには？',
          codeSnippet: '# ゲームを3回繰り返す',
          options: [
            'for round in range(3):\n    # じゃんけん処理',
            'while 3:\n    # じゃんけん処理',
            'repeat(3):\n    # じゃんけん処理',
            'for round in [1,2,3,4]:\n    # じゃんけん処理',
          ],
          correctIndex: 0,
          explanation: 'for range(3) で3回繰り返します。range(3)は0,1,2の3回分です。各回のラウンドでじゃんけん処理を行います。',
          hint: 'range(3) は 0, 1, 2 の3回だよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_47',
      stageNumber: 47,
      title: '🔢 数当てゲームを作ろう',
      description: '1〜100の数を当てるゲームを作りながらwhileループを実践しよう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.intermediate,
      icon: '🔢',
      isFree: false,
      conceptExplanation: '''
🔢 数当てゲームを作ろう！

コンピューターが決めた数を当てるゲームだよ！
「while True + break」の使い方を実践で学ぼう。

🎮 ゲームの流れ

① コンピューターが1〜100の数を決める
② プレイヤーが数を入力する
③「大きい！」「小さい！」のヒントを出す
④ 正解したら終了！

📝 よく使うコードパターン

import random
answer = random.randint(1, 100)   ← 1〜100の整数

while True:                        ← 当たるまで続ける
    guess = int(input("数は？: "))
    if guess == answer:
        print("正解！🎉")
        break                      ← 正解でループを抜ける
    elif guess < answer:
        print("もっと大きい！↑")
    else:
        print("もっと小さい！↓")

💡 このゲームで学べること
→ while True + break パターン
→ 数の比較（<、>、==）
→ int() で入力を数字に変換する方法
''',
      questions: [
        const Question(
          id: 'q_47_1',
          text: '1〜100のランダムな整数を生成するには？',
          codeSnippet: 'import random\nanswer = ____',
          options: [
            'random.randint(1, 100)',
            'random.int(1, 100)',
            'random.range(1, 100)',
            'random.choice(1, 100)',
          ],
          correctIndex: 0,
          explanation: 'random.randint(a, b) で a 以上 b 以下のランダムな整数を返します。randint(1, 100) は1〜100の整数です。',
          hint: 'randint の "int" は整数（integer）の略だよ。',
        ),
        const Question(
          id: 'q_47_2',
          text: '当たるまで繰り返す処理に最適なのは？',
          codeSnippet: '# 正解するまで何度でも挑戦させる',
          options: [
            'while True:\n    guess = int(input("数は？"))\n    if guess == answer: break',
            'for i in range(100):\n    guess = int(input("数は？"))',
            'if guess == answer:\n    print("正解！")',
            'repeat_until(guess == answer):\n    input("数は？")',
          ],
          correctIndex: 0,
          explanation: 'while True で無限ループを作り、正解したら break で抜けます。「当たるまで続ける」ゲームに最適なパターンです。',
          hint: '「いつまでも続けて、条件で止まる」には while True + break を使おう。',
        ),
        const Question(
          id: 'q_47_3',
          text: 'ヒントを出すコードを追加するには？',
          codeSnippet: 'guess = int(input("数は？"))\n# 大きい・小さいヒントを出す',
          options: [
            'if guess < answer:\n    print("もっと大きい！")\nelif guess > answer:\n    print("もっと小さい！")',
            'if guess != answer:\n    print("ヒント：" + answer)',
            'print("答えは" + str(answer) + "です")',
            'if guess == answer:\n    print("大きい！")',
          ],
          correctIndex: 0,
          explanation: 'if/elif で「入力 < 答え → 大きい」「入力 > 答え → 小さい」のヒントを出します。これで効率よく絞り込めます。',
          hint: '入力した数と答えを比べて「大きい方向」「小さい方向」を教えよう。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_48',
      stageNumber: 48,
      title: '📊 成績表プログラムを作ろう',
      description: '辞書とリストを使って成績を計算するプログラムを作ろう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '📊',
      isFree: false,
      questions: [
        const Question(
          id: 'q_48_1',
          text: '成績を辞書で管理するとき、平均点を求めるには？',
          codeSnippet: 'scores = {"国語": 80, "算数": 95, "理科": 70, "社会": 85}',
          options: [
            'sum(scores.values()) / len(scores)',
            'average(scores)',
            'scores.avg()',
            'sum(scores) / 4',
          ],
          correctIndex: 0,
          explanation: 'scores.values() で点数のリストを取り出し、sum() で合計、len() で科目数を取得して割ります。(80+95+70+85)/4 = 82.5 です。',
          hint: 'values() で値を取り出して、sum() と len() を使おう。',
        ),
        const Question(
          id: 'q_48_2',
          text: '最高得点の教科を求めるには？',
          codeSnippet: 'scores = {"国語": 80, "算数": 95, "理科": 70, "社会": 85}',
          options: [
            'max(scores, key=scores.get)',
            'scores.max_key()',
            'max(scores.keys())',
            'scores[max(scores)]',
          ],
          correctIndex: 0,
          explanation: 'max(辞書, key=辞書.get) でキー（科目名）の中から、対応する値（点数）が最大のキーを取り出します。「算数」が返ります。',
          hint: 'max() の key= で「何を基準に比べるか」を指定できるよ。',
        ),
        const Question(
          id: 'q_48_3',
          text: '成績をランク付けする関数を作るには？',
          codeSnippet: 'def get_rank(score):\n    # 90以上→S、70以上→A、50以上→B、それ以外→C',
          options: [
            'if score >= 90: return "S"\nelif score >= 70: return "A"\nelif score >= 50: return "B"\nelse: return "C"',
            'return score > 90 ? "S" : "A"',
            'match score:\n    case >= 90: return "S"',
            'return ["C","B","A","S"][score // 25]',
          ],
          correctIndex: 0,
          explanation: 'if/elif/else を並べて条件を上から順にチェックします。最初に True になった条件のブロックが実行され、return で値を返します。',
          hint: '点数の高い条件から順に elif で確認しよう。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_49',
      stageNumber: 49,
      title: '🎲 サイコロシミュレーター',
      description: 'サイコロを振ってデータを集計するプログラムを作ろう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🎲',
      isFree: false,
      questions: [
        const Question(
          id: 'q_49_1',
          text: '1〜6のサイコロを100回振って結果を記録するには？',
          codeSnippet: 'import random\nresults = []\n# 100回サイコロを振る',
          options: [
            'for _ in range(100):\n    results.append(random.randint(1, 6))',
            'results = random.roll(100, 6)',
            'for i in range(1, 101):\n    results = random.randint(1, 6)',
            'results = [random.randint(1, 6)] * 100',
          ],
          correctIndex: 0,
          explanation: 'for _ in range(100) で100回繰り返し、毎回 random.randint(1,6) でサイコロを振り、append() でリストに追加します。',
          hint: '100回ループして、毎回 append() でリストに追加しよう。',
        ),
        const Question(
          id: 'q_49_2',
          text: '各目の出た回数を数えるには？',
          codeSnippet: 'results = [1, 3, 2, 1, 6, 3, ...]\n# 各目の回数を数える',
          options: [
            'from collections import Counter\ncount = Counter(results)',
            'count = results.count_all()',
            'count = dict(results)',
            'count = {i: 0 for i in range(7)}',
          ],
          correctIndex: 0,
          explanation: 'Counter はリストの各要素の出現回数を自動で数える便利なクラスです。Counter([1,1,2,3]) → {1:2, 2:1, 3:1} のような辞書になります。',
          hint: '「数える（Counter）」という便利なクラスがあるよ。',
        ),
        const Question(
          id: 'q_49_3',
          text: '確率（%）を計算して表示するには？',
          codeSnippet: 'count = {1: 17, 2: 16, 3: 18, 4: 15, 5: 19, 6: 15}\ntotal = 100',
          options: [
            'for face, n in count.items():\n    print(f"{face}の目: {n/total*100:.1f}%")',
            'print(count / total * 100)',
            'for n in count:\n    print(n * 100 / total)',
            'print(f"{count}%")',
          ],
          correctIndex: 0,
          explanation: 'items() でキーと値のペアを取り出し、確率 = n/total*100 を計算します。:.1f で小数点1桁にフォーマットします。',
          hint: 'items() でキーと値のペアを取り出して、割り算で確率を計算しよう。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_50',
      stageNumber: 50,
      title: '🏆 総合ミニプロジェクト',
      description: 'Pythonの知識を全部使って「自分だけのクイズゲーム」を完成させよう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🏆',
      isFree: false,
      questions: [
        const Question(
          id: 'q_50_1',
          text: 'クイズ問題を辞書のリストで管理するには？',
          codeSnippet: '# 問題・答え・ヒントをまとめて管理',
          options: [
            'quiz = [\n  {"q": "日本の首都は？", "a": "東京", "hint": "東の方角"},\n  {"q": "1+1は？", "a": "2", "hint": "足し算だよ"}\n]',
            'quiz = ("日本の首都は？", "東京")',
            'quiz = {"q1": "日本の首都は？", "q2": "1+1は？"}',
            'quiz = ["日本の首都は？", "東京", "1+1は？", "2"]',
          ],
          correctIndex: 0,
          explanation: '辞書をリストに入れると、問題・答え・ヒントをセットで管理できます。quiz[0]["q"] で最初の問題文にアクセスできます。',
          hint: '辞書でひとつの問題をまとめて、リストに入れると管理しやすいよ。',
        ),
        const Question(
          id: 'q_50_2',
          text: '全問正解した場合だけ「パーフェクト！」と表示するには？',
          codeSnippet: 'correct = 0\ntotal = len(quiz)\n# 全問正解の判定',
          options: [
            'if correct == total:\n    print("パーフェクト！")',
            'if correct > 0:\n    print("パーフェクト！")',
            'if correct != 0:\n    print("パーフェクト！")',
            'if total - correct == 0:\n    print("パーフェクト！")',
          ],
          correctIndex: 0,
          explanation: 'correct == total で「正解数 = 問題数」を確認します。全問正解のときだけ True になります。',
          hint: '「全部正解」= 正解数が問題の総数と等しい、ということだよ。',
        ),
        const Question(
          id: 'q_50_3',
          text: '結果をランク付けして表示する関数の正しい実装は？',
          codeSnippet: 'def show_result(correct, total):\n    rate = correct / total\n    # rate に応じてランクを表示',
          options: [
            'if rate == 1.0: print("🌟 パーフェクト！")\nelif rate >= 0.8: print("⭐ すごい！")\nelif rate >= 0.6: print("👍 合格！")\nelse: print("💪 もう一回！")',
            'print(rate * 100 + "点")',
            'return rate',
            'if correct == total: print("合格") else: print("不合格")',
          ],
          correctIndex: 0,
          explanation: '正解率（rate）に応じて if/elif/else でランクを分けます。絵文字を使うと小学生向けに楽しい表示になります。',
          hint: '正解率 = correct ÷ total。それに応じてメッセージを変えよう。',
        ),
      ],
    ),

    Challenge(
      id: 'stage_20',
      stageNumber: 20,
      title: '設計図を作ろう',
      description: 'Pythonの「設計図（クラス）」でオリジナルの部品を作ろう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🏗️',
      isFree: false,
      conceptExplanation: '''
🏗️ 設計図（クラス）を作ろう！

「クラス」は、キャラクターや物の「設計図」のこと。
1つの設計図から、たくさんのキャラクターが作れるんだ！

📝 基本の書き方

class Robot:
    def __init__(self, name):
        self.name = name      ← このロボットの名前

    def move(self):
        print(self.name + "が動いた！")

robot1 = Robot("R2D2")   ← 設計図からロボット1を作る
robot2 = Robot("C3PO")   ← ロボット2も作れる！

🔧 キーワード説明

• class     → 設計図を定義する
• __init__  → 作るときに最初に動く処理
• self      → その「本人」のこと

🎮 ゲームで例えると…

class Monster:
    def __init__(self, name, hp):
        self.name = name
        self.hp = hp

slime  = Monster("スライム", 30)    ← スライムを作る
dragon = Monster("ドラゴン", 200)   ← ドラゴンも作れる！
''',
      questions: [
        const Question(
          id: 'q_20_1',
          text: 'クラスを定義するキーワードは？',
          options: ['object', 'class', 'type', 'struct'],
          correctIndex: 1,
          explanation: 'class キーワードでクラスを定義します。クラスはオブジェクトの設計図です。',
        ),
        const Question(
          id: 'q_20_2',
          text: 'クラスのインスタンスを作るには？',
          codeSnippet: 'class Dog:\n    def __init__(self, name):\n        self.name = name',
          options: [
            'Dog.create("ポチ")',
            'Dog("ポチ")',
            'new Dog("ポチ")',
            'Dog.new("ポチ")',
          ],
          correctIndex: 1,
          explanation: 'Pythonでは クラス名(引数) でインスタンスを作れます。my_dog = Dog("ポチ") のように使います。',
        ),
        const Question(
          id: 'q_20_3',
          text: 'self は何を指す？',
          codeSnippet: 'class Robot:\n    def move(self):\n        print(self.name + "が動いた！")',
          options: [
            'クラス全体',
            'そのインスタンス自身',
            '親クラス',
            '何も指さない',
          ],
          correctIndex: 1,
          explanation: 'self はそのインスタンス（作ったオブジェクト）自身を指します。self.name で各インスタンスの名前にアクセスできます。',
        ),
      ],
    ),
    // ===== 上級追加: アルゴリズム入門ステージ (51-55) =====
    Challenge(
      id: 'stage_51',
      stageNumber: 51,
      title: '🔁 再帰で問題を解こう',
      description: '自分自身を呼び出す「再帰関数」でフィボナッチ数列を計算しよう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🔁',
      isFree: false,
      conceptExplanation: '''
🔁 自分自身を呼び出す関数（再帰）

「再帰（さいき）」とは、関数が自分自身を呼び出すこと！
難しく聞こえるけど、パターンさえわかれば使えるよ。

📝 再帰の例：階乗（かいじょう）

5! = 5 × 4 × 3 × 2 × 1 = 120

def factorial(n):
    if n == 0:              ← ここで止まる（必須！）
        return 1
    return n * factorial(n - 1)   ← 自分を呼ぶ

factorial(3) の動き:
→ 3 × factorial(2)
  → 3 × 2 × factorial(1)
    → 3 × 2 × 1 × factorial(0)
      → 3 × 2 × 1 × 1 = 6

⚠️ 再帰の2つのルール（必ず守ろう！）

① 止まる条件（ベースケース）を必ず書く！
② 毎回、問題を少し小さくする！

止まる条件がないと、永遠に呼び続けてエラーになるよ。

🎮 ゲームで例えると…
→ マトリョーシカ人形（中に小さい人形が入っている）
→ 最後は「一番小さい人形」で終わる！
''',
      questions: [
        const Question(
          id: 'q_51_1',
          text: '再帰関数の必須要素は？',
          options: [
            '無限に呼び出し続けること',
            '基底条件（ベースケース）と再帰ステップ',
            'forループの中で使うこと',
            'クラスの中で定義すること',
          ],
          correctIndex: 1,
          explanation: '再帰関数には①再帰を止める基底条件（ベースケース）と②自分自身を呼ぶ再帰ステップの2つが必要です。',
          hint: '再帰が止まる条件がないと無限ループになってしまうよ。',
        ),
        const Question(
          id: 'q_51_2',
          text: 'factorial(3) の実行結果は？',
          codeSnippet: 'def factorial(n):\n    if n == 0:\n        return 1\n    return n * factorial(n - 1)',
          options: ['3', '6', '9', '1'],
          correctIndex: 1,
          explanation: 'factorial(3) = 3 × factorial(2) = 3 × 2 × factorial(1) = 3 × 2 × 1 = 6 です。',
          hint: '3! = 3 × 2 × 1 を手で計算してみよう。',
        ),
        const Question(
          id: 'q_51_3',
          text: 'fib(5)の結果は？（fib(0)=0, fib(1)=1）',
          codeSnippet: 'def fib(n):\n    if n <= 1:\n        return n\n    return fib(n-1) + fib(n-2)',
          options: ['3', '5', '8', '13'],
          correctIndex: 1,
          explanation: 'fib(5) = fib(4)+fib(3) = (fib(3)+fib(2))+(fib(2)+fib(1)) = ... = 5 です。0,1,1,2,3,5 がフィボナッチ数列です。',
          hint: '0,1,1,2,3,5,8… と順に数えてみよう。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_52',
      stageNumber: 52,
      title: '🔍 二分探索を学ぼう',
      description: 'ソート済みリストを半分ずつ絞り込む高速検索「二分探索」を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🔍',
      isFree: false,
      questions: [
        const Question(
          id: 'q_52_1',
          text: '100個の要素から二分探索で見つけるまでに最大何回比較する？',
          options: ['100回', '50回', '7回', '1回'],
          correctIndex: 2,
          explanation: '二分探索は毎回半分に絞るため log₂(100) ≈ 7 回です。線形探索の100回と比べて非常に高速です。',
          hint: '100 → 50 → 25 → 12 → 6 → 3 → 1 と数えてみよう。',
        ),
        const Question(
          id: 'q_52_2',
          text: 'このコードで target=7 を探すとき、最初に比較するのは？',
          codeSnippet: 'nums = [1, 3, 5, 7, 9, 11, 13]\n# 二分探索で7を探す',
          options: ['1', '5', '7', '13'],
          correctIndex: 1,
          explanation: '二分探索は中央値から比較します。nums[3]=7 の中央は nums[3]（7個の真ん中=インデックス3）ではなく nums[3] = 7 です。実際には mid = (0+6)//2 = 3 なので nums[3] = 7 と比較します。',
          hint: 'まず配列の真ん中の要素を見るよ。中央はどこかな？',
        ),
        const Question(
          id: 'q_52_3',
          text: 'bisect_left の役割は？',
          codeSnippet: 'import bisect\nnums = [1, 3, 5, 7, 9]\npos = bisect.bisect_left(nums, 5)',
          options: [
            'リストをソートする',
            'ソート済みリストで値の挿入位置を返す',
            'リストの左端を返す',
            '値を削除する',
          ],
          correctIndex: 1,
          explanation: 'bisect_left(list, x) はソート済みリストに x を挿入すべき位置（インデックス）を返します。5の場合はインデックス2が返ります。',
          hint: '「bisect（2等分）」→ ソートを保ちながらどこに挿入するかを探すよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_53',
      stageNumber: 53,
      title: '🫧 バブルソートの仕組み',
      description: '隣同士を比べて並び替える「バブルソート」アルゴリズムを理解しよう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🫧',
      isFree: false,
      questions: [
        const Question(
          id: 'q_53_1',
          text: 'バブルソートは1回のパスで何をする？',
          options: [
            'リスト全体をソートする',
            '最大値を末尾に移動させる',
            'リストを2等分する',
            '最小値を先頭に移動させる',
          ],
          correctIndex: 1,
          explanation: 'バブルソートは隣同士を比較・交換を繰り返します。1回のパスで最大値が末尾「浮かび上がる」ように移動します。',
          hint: '泡（バブル）が浮かぶようにイメージしよう。何が一番上に浮かぶ？',
        ),
        const Question(
          id: 'q_53_2',
          text: '[3, 1, 4, 1, 5] を1回パスした後の結果は？',
          options: [
            '[1, 1, 3, 4, 5]',
            '[1, 3, 4, 1, 5]',
            '[3, 1, 4, 1, 5]',
            '[1, 3, 1, 4, 5]',
          ],
          correctIndex: 3,
          explanation: '3>1→swap→[1,3,4,1,5]、3<4→そのまま、4>1→swap→[1,3,1,4,5]、4<5→そのまま。最大値5が末尾に到達。',
          hint: '左から順に隣と比べて、大きい方を右に移していこう。',
        ),
        const Question(
          id: 'q_53_3',
          text: 'バブルソートの時間計算量は？',
          options: ['O(n)', 'O(n log n)', 'O(n²)', 'O(1)'],
          correctIndex: 2,
          explanation: 'n個の要素に対して最悪n×nの比較が必要なのでO(n²)です。n=1000なら最大100万回の比較が必要です。',
          hint: '外側のループがn回、内側もn回 → n×n = n²だよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_54',
      stageNumber: 54,
      title: '📚 スタックとキュー',
      description: 'データの出し入れルールが違う「スタック」と「キュー」を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '📚',
      isFree: false,
      questions: [
        const Question(
          id: 'q_54_1',
          text: 'スタックの出し入れルールは？',
          options: [
            '最初に入れたものが最初に出る（FIFO）',
            '最後に入れたものが最初に出る（LIFO）',
            'ランダムに出る',
            '最も小さいものが出る',
          ],
          correctIndex: 1,
          explanation: 'スタックは LIFO（Last In, First Out）。本を積み上げた状態で一番上（最後に置いた本）から取り出すイメージです。',
          hint: 'お皿の積み重ねをイメージ。一番上のお皿（最後に置いたもの）から取るよ。',
        ),
        const Question(
          id: 'q_54_2',
          text: 'Pythonでスタックを実装するのに適したものは？',
          codeSnippet: 'stack = []\nstack.append(1)\nstack.append(2)\nstack.append(3)\nprint(stack.pop())',
          options: ['3', '2', '1', 'エラー'],
          correctIndex: 0,
          explanation: 'リストの append()でpush、pop()でpopができます。最後に追加した3が pop() で取り出されます。',
          hint: 'append() で追加、pop() で取り出し。最後に追加したのは何？',
        ),
        const Question(
          id: 'q_54_3',
          text: 'キューに最適なPythonのデータ構造は？',
          options: [
            'list（リスト）',
            'collections.deque',
            'dict（辞書）',
            'tuple（タプル）',
          ],
          correctIndex: 1,
          explanation: 'deque（デック）は両端への追加・取り出しがO(1)で高速です。appendで後端追加、popleftで前端取り出しをしてキューを実装できます。',
          hint: '先頭からの取り出しが速いデータ構造を選ぼう。list の pop(0) は遅いよ。',
        ),
      ],
    ),
    Challenge(
      id: 'stage_55',
      stageNumber: 55,
      title: '🔤 正規表現入門',
      description: '文字列のパターン検索が強力になる「正規表現」の基本を学ぼう！（プレミアム）',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🔤',
      isFree: false,
      questions: [
        const Question(
          id: 'q_55_1',
          text: 'メールアドレスが含まれるか調べるコードは？',
          codeSnippet: 'import re\ntext = "連絡先: test@example.com"\n# @が含まれるか検索',
          options: [
            're.search(r"@", text)',
            're.find("@", text)',
            're.contains("@", text)',
            'text.regex("@")',
          ],
          correctIndex: 0,
          explanation: 're.search(パターン, 文字列) でパターンが見つかればMatchオブジェクト、なければNoneを返します。',
          hint: '「検索（search）」するメソッドを使おう。',
        ),
        const Question(
          id: 'q_55_2',
          text: r'"\\d+" は何にマッチする？',
          options: [
            '英字の連続',
            '1桁以上の数字の連続',
            'スペースの連続',
            '任意の1文字',
          ],
          correctIndex: 1,
          explanation: r'\d は数字1文字、+ は1回以上の繰り返しです。\d+ で「1桁以上の数字の連続」にマッチします。',
          hint: r'\d = digit（数字）、+ = 1つ以上 を組み合わせると？',
        ),
        const Question(
          id: 'q_55_3',
          text: '文字列から全ての数字を抽出するには？',
          codeSnippet: 'import re\ntext = "商品A:300円、商品B:450円"',
          options: [
            r're.findall(r"\d+", text)',
            r're.search(r"\d+", text)',
            r're.match(r"\d+", text)',
            r're.split(r"\d+", text)',
          ],
          correctIndex: 0,
          explanation: 'findall() はパターンにマッチする全ての文字列をリストで返します。["300", "450"] が得られます。',
          hint: '「全て見つける（findall）」メソッドを使おう。',
        ),
      ],
    ),

    // ===== ゲーム制作特別ステージ =====
    Challenge(
      id: 'stage_56',
      stageNumber: 56,
      title: '🐍 Python（パイソン）ってなに？魔法のことば',
      description: '🎮 キミの好きなゲーム、ぜんぶプログラミングで作られているって知ってた？\n\nここからは、世界中のプロが使う「Python（パイソン）」という魔法のことばを学ぶよ！\n\n✨ このことばを覚えると…\n🎯 ゲームが作れる\n🤖 ロボットが動かせる\n🚀 キミのアイデアが現実になる！\n\nさあ、ゲームクリエイターへの第一歩をふみだそう！',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🐍',
      isFree: true,
      conceptExplanation: '''
🐍 Python（パイソン）ってなに？

「Python」は、せかい中のプロが使うプログラミング言語！
キミもこれを学べば、ゲームが作れるようになるよ！

🌟 Pythonでできること

🎮 ゲームを作る
  → マインクラフトの教育版でPythonが使える！
  → 自動でブロックを置いてお城を建てたりできる！

🤖 ロボットを動かす
  → ラズベリーパイというロボットボードで使われてる

🧠 AIを作る
  → ChatGPTもPythonで作られているんだよ！

📱 アプリを作る
  → ウェブサービスやツールも作れる

📖 名前の由来
「モンティ・パイソン」というイギリスのおもしろい
コメディ番組から名前をとったんだ！（ヘビじゃないよ笑）

💡 Pythonが人気な理由
→ 英語みたいに読みやすい
→ はじめての人にもやさしい
→ それでいてプロも使う本格的な言語！
''',
      questions: [
        const Question(
          id: 'q_56_1',
          text: '「Python（パイソン）」って、どんな名前の由来？',
          options: [
            'ヘビの名前から',
            'イギリスのおもしろコメディ番組から',
            'えらい科学者の名前から',
            'お菓子の名前から',
          ],
          correctIndex: 1,
          explanation: '実はPythonは「モンティ・パイソン」という、イギリスのおもしろいコメディ番組から名前をとったんだ！作った人がこの番組のファンだったんだよ。😆',
          hint: 'ヘビっぽい名前だけど、じつはちがうんだ！',
        ),
        const Question(
          id: 'q_56_2',
          text: 'Pythonが世界中で大人気なのは、なぜ？',
          options: [
            '読みやすくて、書きやすいから',
            'むずかしくて、かっこいいから',
            'ゲームしか作れないから',
            'お金がかかるから',
          ],
          correctIndex: 0,
          explanation: 'Pythonは英語みたいに読みやすいから、はじめての人にもピッタリ！それでいてゲーム・AI・アプリまで作れる、すごいことばなんだ。🌟',
          hint: 'はじめての人にやさしい言語だよ。',
        ),
        const Question(
          id: 'q_56_3',
          text: 'マインクラフトにも、じつはPythonが使えるって本当？',
          options: [
            '本当！ブロックを自動でならべたりできる',
            'うそ。ゲームには使えない',
            'マイクラだけは使えない',
            '大人しか使えない',
          ],
          correctIndex: 0,
          explanation: '本当だよ！マインクラフトの「教育版」では、Pythonでお城を一瞬で建てたり、自動で道を作ったりできるんだ。プログラミングってすごいでしょ？⛏️',
          hint: 'キミの好きなゲームでも使えるかも？',
        ),
      ],
    ),
    Challenge(
      id: 'stage_57',
      stageNumber: 57,
      title: '🎮 ポケモンずかんを作ろう！',
      description: '🐉 ポケモンには、なまえ・タイプ・HP（たいりょく）があるよね？\n\nゲームの中では、キャラクターのじょうほうを「データ」として整理しているんだ。\n\n✨ このステージでは…\n📒 自分だけの「モンスターずかん」をプログラミングで作る方法を学ぶよ！\n\nなまえやHPを、コンピューターにおぼえさせよう！',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🎮',
      isFree: true,
      conceptExplanation: '''
🎮 ポケモンずかんをプログラミングで作ろう！

ポケモンずかんは、モンスターのデータをまとめたもの。
プログラミングで同じものが作れるんだ！

📒 「じしょ（dict）」でデータをまとめる

monster = {
  "なまえ": "ピカチュウ",
  "タイプ": "でんき",
  "HP": 100
}

→ monster["なまえ"]  で「ピカチュウ」が取り出せる！
→ monster["HP"]     で「100」が取り出せる！

⚔️ HPをへらす方法

monster["HP"] -= 10    ← 10ダメージ！
（100 → 90 になる）

「-=」は「いまの数から、へらす」というしるしだよ

🗂️ リストにまとめると「ずかん」になる！

zukan = [ピカチュウデータ, イーブイデータ, カビゴンデータ]

for pokemon in zukan:
    print(pokemon["なまえ"])   ← 全部のポケモンを表示！
''',
      questions: [
        const Question(
          id: 'q_57_1',
          text: 'モンスター1ぴきのじょうほうを、まとめてしまっておくには？',
          codeSnippet: '# なまえ・HP・こうげき力をまとめたい\nmonster = {"name": "ドラゴン", "hp": 100, "attack": 20}',
          options: [
            '{ } を使った「じしょ」にまとめる',
            'バラバラの変数にする',
            'ノートに手で書く',
            'まとめられない',
          ],
          correctIndex: 0,
          explanation: '{ } を使うと「じしょ（dictionary）」になって、なまえもHPも1つにまとめられるよ！monster["hp"] で、HPだけ取り出せるんだ。📒',
          hint: '{ } のなかに、なまえとHPをまとめてみよう！',
        ),
        const Question(
          id: 'q_57_2',
          text: 'ドラゴンが攻撃をうけて、HPが10へったよ。どう書く？',
          codeSnippet: 'monster = {"name": "ドラゴン", "hp": 100}\n# HPを10へらしたい！',
          options: [
            'monster["hp"] -= 10',
            'monster["hp"] = 10',
            'monster - 10',
            'HP - 10',
          ],
          correctIndex: 0,
          explanation: '「-=」は「いまの数から、へらす」というしるし。100から10へって、HPは90になったよ！⚔️',
          hint: '「-=」は、いまの数から引き算するしるしだよ。',
        ),
        const Question(
          id: 'q_57_3',
          text: 'ずかんのモンスターを、ぜんぶ順ばんに見せるには？',
          codeSnippet: 'zukan = ["ドラゴン", "スライム", "ゴースト"]\nfor monster in zukan:\n    print(monster)',
          options: [
            'for（くりかえし）を使う',
            '1ぴきずつ手で書く',
            'できない',
            'ランダムに選ぶ',
          ],
          correctIndex: 0,
          explanation: 'for を使えば、ずかんのモンスターを上から順ばんに、ぜんぶ見せられるよ！「ドラゴン→スライム→ゴースト」と表示されるんだ。✨',
          hint: '「くりかえし」のブロックを思い出そう！',
        ),
      ],
    ),
    Challenge(
      id: 'stage_58',
      stageNumber: 58,
      title: '⭐ マリオでコインを数えよう！',
      description: '🪙 マリオがコインをゲットすると、スコアがふえるよね？\n\nゲームの「とくてん（スコア）」は、ぜんぶ計算でできているんだ！\n\n✨ このステージでは…\n🎯 コインを集めたらスコアアップ\n⏰ はやくクリアするとボーナス！\n\nそんな「スコアのしくみ」を、自分でプログラミングしてみよう！',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '⭐',
      isFree: true,
      conceptExplanation: '''
⭐ ゲームのスコアを計算しよう！

マリオがコインをとるとスコアがふえるよね？
あのスコア計算も、プログラミングでできているんだ！

🪙 コインのスコア計算

coin_value = 10      ← コイン1まい = 10点
coin_count = 5       ← 5まい集めた
score = coin_value * coin_count

→ 10 × 5 = 50点！
（「*」はかけ算のしるし）

⏰ タイムボーナス

remaining_time = 20   ← のこり20秒
bonus = remaining_time * 10

→ 20 × 10 = 200点ボーナス！
はやくクリアするほどボーナスがふえる！

🔥 ボスたおしボーナス

boss_level = 5
boss_bonus = boss_level * 100

→ 5 × 100 = 500点ボーナス！
つよい敵ほど点数が高い！

💡 ゲームのスコアは全部こんな計算でできているんだよ！
「かけ算・たし算」だけでゲームが作れる！
''',
      questions: [
        const Question(
          id: 'q_58_1',
          text: 'コイン1まい10点。5まい集めたら何点？',
          codeSnippet: 'coin = 10      # コイン1まいの点数\ncount = 5      # 集めたコインの数\nscore = coin * count',
          options: [
            '15点',
            '50点',
            '10点',
            '5点',
          ],
          correctIndex: 1,
          explanation: '10点 × 5まい = 50点！「*」はかけ算のしるし。たくさん集めるほど、点数がふえるよ。🪙',
          hint: 'コイン1まいの点数 × まい数 で計算しよう！',
        ),
        const Question(
          id: 'q_58_2',
          text: 'ボス（つよい敵）をたおすと、点数が高い。なぜそうする？',
          codeSnippet: 'boss_level = 5\nbonus = boss_level * 100   # レベル × 100',
          options: [
            'つよい敵ほど、たおすとうれしいから',
            'いみはない',
            'ボスはよわいから',
            'てきとうに決めている',
          ],
          correctIndex: 0,
          explanation: 'つよい敵をたおすと高い点数がもらえると、プレイヤーは「がんばろう！」とワクワクするよね。これもゲームを楽しくする工夫なんだ！🔥',
          hint: 'つよい敵をたおしたら、たくさんごほうびがほしいよね？',
        ),
        const Question(
          id: 'q_58_3',
          text: 'はやくクリアするほどボーナス！残り20秒なら何点？',
          codeSnippet: 'remaining = 20    # のこり時間（秒）\ntime_bonus = remaining * 10',
          options: [
            '200点',
            '20点',
            '10点',
            '0点',
          ],
          correctIndex: 0,
          explanation: 'のこり20秒 × 10 = 200点のボーナス！はやくクリアするほど、ボーナスがふえる。これでドキドキのタイムアタックができるね！⏰',
          hint: 'のこり時間 × 10 で計算してみよう！',
        ),
      ],
    ),
    Challenge(
      id: 'stage_59',
      stageNumber: 59,
      title: '👾 モンスターをよびだそう！',
      description: '👻 ゲームをするたびに、ちがう敵が出てきたらドキドキするよね？\n\nそれは「ランダム（でたらめに選ぶ）」というしくみのおかげなんだ！\n\n✨ このステージでは…\n🎲 ランダムにモンスターをよびだす\n⚔️ たおした敵をきえさせる\n\nそんな「敵を出すしくみ」を作ってみよう！キミがゲームマスターだ！',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '👾',
      isFree: true,
      conceptExplanation: '''
👾 モンスターをよびだすしくみ

ゲームで毎回ちがう敵が出てくるのは「ランダム」のおかげ！
Pythonで同じしくみを作ってみよう。

🎲 ランダムに1ぴき選ぶ

import random
monsters = ["スライム", "ゴースト", "ドラゴン"]
enemy = random.choice(monsters)

→ 毎回ちがうモンスターが選ばれる！

（「choice」は英語で「えらぶ」という意味）

👾 たくさんの敵を出す（for ループ）

enemies = []
for i in range(5):                 ← 5回くりかえす
    enemies.append("モンスター")   ← リストに追加

→ 5ひきのモンスターが出てきた！

⚔️ HPをチェックしてたおす

monster_hp = 100
monster_hp -= 30    ← 30ダメージ！（70になる）

if monster_hp <= 0:
    print("モンスターをたおした！⚔️")

💡 この3つ（ランダム・くりかえし・if）を使えば
  ゲームの敵を出すしくみが作れる！
''',
      questions: [
        const Question(
          id: 'q_59_1',
          text: '3ひきの中から、ランダムに1ぴき敵を出すには？',
          codeSnippet: 'import random\nmonsters = ["スライム", "ゴースト", "ドラゴン"]\nenemy = random.____(monsters)',
          options: [
            'random.choice(monsters)',
            'random.print(monsters)',
            'random.get(monsters)',
            'random.pick(monsters)',
          ],
          correctIndex: 0,
          explanation: 'random.choice() を使うと、リストの中からランダムに1ぴき選んでくれる！毎回ちがう敵が出てきて、ワクワクするゲームになるよ。🎲',
          hint: '「choice」は英語で「えらぶ」っていういみだよ。',
        ),
        const Question(
          id: 'q_59_2',
          text: '敵を5ひき、まとめて出したい！どうする？',
          codeSnippet: 'enemies = []\nfor i in range(5):\n    enemies.append("モンスター")',
          options: [
            'for（くりかえし）で5回出す',
            '手で5回書く',
            '1ぴきしか出せない',
            'むり',
          ],
          correctIndex: 0,
          explanation: 'for で5回くりかえせば、一気に5ひきの敵を出せる！range(5) は「5回くりかえす」といういみだよ。たくさん敵が出てきたぞ！👾👾👾',
          hint: '「くりかえし」を使えば、一気にたくさん作れるよ！',
        ),
        const Question(
          id: 'q_59_3',
          text: 'モンスターのHPが0になった！どうなる？',
          codeSnippet: 'if monster_hp <= 0:\n    print("モンスターをたおした！")\n    # モンスターをきえさせる',
          options: [
            'たおれて、画面からきえる',
            'もっとつよくなる',
            'なにもおきない',
            'HPがふえる',
          ],
          correctIndex: 0,
          explanation: 'HPが0になったら「if（もし〜なら）」でチェックして、モンスターをきえさせるよ。これでバトルがちゃんと終わるんだ！⚔️✨',
          hint: '「もし〜なら」でHPをチェックしてみよう！',
        ),
      ],
    ),
    Challenge(
      id: 'stage_60',
      stageNumber: 60,
      title: '🎯 キミだけのゲームを作ろう！',
      description: '🎉 ついに最後のステージ！\n\nここまでで、キャラクター・スコア・敵……ゲームのパーツをぜんぶ学んだね。\n\n✨ 最後のひみつは「ゲームループ」！\nゲームは「ボタンをおす → うごく → 画面にうつす」を、ものすごいはやさでくりかえしているんだ。\n\n🏆 このステージをクリアすれば、キミはもう「ゲームクリエイター」！\nじぶんのアイデアを、ゲームにできる力を手に入れたよ！',
      type: ChallengeType.quiz,
      level: StageLevel.advanced,
      icon: '🎯',
      isFree: false,
      conceptExplanation: '''
🎯 ゲームを作るひみつ：ゲームループ

ゲームはどうやって動いているのか、最後のひみつを教えるよ！

🔄 ゲームループのしくみ

while ゲーム中:              ← ゲーム中はずっとくりかえす
    ① ボタンをチェックする
    ② キャラをうごかす
    ③ 画面にうつす

→ これを1秒間に60回くりかえしているんだ！
  だからキャラがなめらかに動いて見える！

🎮 キミがこのアプリで学んできたもの

• 変数       → スコア・HP・名前を記おく
• if/else   → ゲームオーバーの判定
• for       → 敵を一気に出す
• while     → ゲームループ
• def       → 「こうげき」のしくみを作る
• dict      → キャラクターデータをまとめる

🌟 ゲームクリエイターへのアドバイス

どんなすごいゲームも、最初は小さなゲームから始まった。
まずは「コインをとるゲーム」や
「数当てゲーム」から作ってみよう！

🏆 ここまで来たキミは、もうゲームを作る力を持っている！
''',
      questions: [
        const Question(
          id: 'q_60_1',
          text: 'ゲームを作るのにぜったい必要な3つは？',
          options: [
            'ボタンそうさ・うごき・画面表示',
            'お金・時間・ともだち',
            '3Dグラフィック・音楽・声',
            'パソコン・スマホ・テレビ',
          ],
          correctIndex: 0,
          explanation: 'ゲームは「ボタンをうけとる→うごきを計算する→画面にうつす」の3つでできているよ。マリオもポケモンも、ぜんぶこのしくみなんだ！🎮',
          hint: 'キミがコントローラーをおすと、何がおきる？',
        ),
        const Question(
          id: 'q_60_2',
          text: 'ゲームが「ぬるぬる動く」のは、なぜ？',
          codeSnippet: 'while ゲーム中:\n    ボタンをチェック()\n    キャラをうごかす()\n    画面にうつす()',
          options: [
            'このながれを、ものすごいはやさでくりかえすから',
            '1回だけうごかすから',
            'まほうだから',
            'ゆっくりうごかすから',
          ],
          correctIndex: 0,
          explanation: 'ゲームは1秒間に60回くらい、このながれをくりかえしているんだ！だからキャラがぬるぬる、なめらかに動いて見えるんだよ。すごいでしょ？⚡',
          hint: '「くりかえし（while）」がポイントだよ！',
        ),
        const Question(
          id: 'q_60_3',
          text: 'これからゲームを作るなら、まず何からはじめる？',
          options: [
            'まずは小さくてかんたんなゲームから',
            'いきなりすごい3Dゲーム',
            'プロになってから',
            'なにもしない',
          ],
          correctIndex: 0,
          explanation: 'どんなすごいゲームクリエイターも、さいしょは小さなゲームから始めたんだ。まずは「玉をよける」みたいなかんたんなゲームから作ってみよう。キミならできる！🌟🎮',
          hint: 'プロの人も、さいしょは小さなことからはじめたよ！',
        ),
      ],
    ),
  ];
  // stageNumber 順に並べ替えて一貫した順序を保証する
  list.sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
  return list;
}
