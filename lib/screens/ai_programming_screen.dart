import 'package:flutter/material.dart';

import '../config/theme.dart';

/// 「AIとプログラミング」: 解説・試す・注意点・悪い例（実例）をまとめた学習画面。
///
/// 通信は行わない。「ためす」の AI の答えはあらかじめ用意した「れい」で、
/// 実際の AI の出力ではないことを画面内で明示する。
class AiProgrammingScreen extends StatefulWidget {
  const AiProgrammingScreen({super.key});

  @override
  State<AiProgrammingScreen> createState() => _AiProgrammingScreenState();
}

class _AiProgrammingScreenState extends State<AiProgrammingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIとプログラミング'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'かいせつ'),
            Tab(text: 'ためす'),
            Tab(text: 'ちゅうい'),
            Tab(text: 'わるいれい'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ExplainTab(),
          _TryTab(),
          _CautionTab(),
          _BadExampleTab(),
        ],
      ),
    );
  }
}

// ─── 共通パーツ ───────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String emoji;
  final String title;
  final List<Widget> children;
  final Color? accent;

  const _Section({
    required this.emoji,
    required this.title,
    required this.children,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? kPrimaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, height: 1.7, color: context.textPrimary),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final String mark;
  const _Bullet(this.text, {this.mark = '・'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mark, style: TextStyle(fontSize: 14, color: context.textPrimary)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.6, color: context.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String code;
  final bool bad;
  const _CodeBox(this.code, {this.bad = false});

  @override
  Widget build(BuildContext context) {
    final color = bad ? const Color(0xFFE74C3C) : kPrimaryColor;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF121212) : const Color(0xFFF3F6F8),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: context.textPrimary,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

// ─── 1. かいせつ ─────────────────────────────────────────────────────────────

class _ExplainTab extends StatelessWidget {
  const _ExplainTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Section(
          emoji: '🤖',
          title: 'AIってなに？',
          children: [
            _Body('AIは、たくさんの文章やプログラムを読んで、「つぎに来そうな言葉」を予想して答えを作るしくみだよ。'),
            _Body('だから、上手に答えてくれることもあるけれど、自信まんまんに まちがえることもあるんだ。'),
          ],
        ),
        _Section(
          emoji: '✨',
          title: 'プログラミングで、AIにできること',
          children: [
            _Bullet('コードを書く手伝い（下書きを作ってもらう）'),
            _Bullet('エラーのいみを、やさしく教えてもらう'),
            _Bullet('わからない言葉を、たとえ話で説明してもらう'),
            _Bullet('ゲームやアプリのアイデアを出してもらう'),
          ],
        ),
        _Section(
          emoji: '🧑‍🏫',
          title: 'AIは「先生」じゃなくて「お手伝いさん」',
          children: [
            _Body('AIの答えは、いつも正しいとはかぎらないよ。答えをもらったら、かならず自分で読んで、動かして、たしかめよう。'),
            _Body('プロのプログラマーもAIを使うけれど、最後にたしかめて決めるのは人間の仕事なんだ。'),
          ],
        ),
        _Section(
          emoji: '📝',
          title: 'じょうずなおねがいの書き方（4つのコツ）',
          children: [
            _Bullet('なにを作りたいか', mark: '1️⃣'),
            _Bullet('どの言葉（Pythonなど）で書くか', mark: '2️⃣'),
            _Bullet('だれ向けか（「小学生にもわかるように」など）', mark: '3️⃣'),
            _Bullet('ほしい形（「コメントつきで」「短く」など）', mark: '4️⃣'),
            _Body('「ためす」タブで、書き方のちがいをくらべてみよう！'),
          ],
        ),
      ],
    );
  }
}

// ─── 2. ためす ───────────────────────────────────────────────────────────────

class _Prompt {
  final String label;
  final String request;
  final String answer;
  final String? code;
  final String verdict;
  final bool good;

  const _Prompt({
    required this.label,
    required this.request,
    required this.answer,
    this.code,
    required this.verdict,
    required this.good,
  });
}

const _prompts = <_Prompt>[
  _Prompt(
    label: 'A',
    request: 'ゲームつくって',
    answer: 'どんなゲームですか？ すうじあてゲーム、じゃんけん、シューティング…たくさんあって、'
        'どれを作ればいいかわかりません。',
    verdict: '「なにを・どうやって」がないと、AIも迷ってしまうよ。',
    good: false,
  ),
  _Prompt(
    label: 'B',
    request: 'Pythonで、1から10までの数字を1つずつ表示するプログラムを、'
        '小学生にもわかるようにコメントつきで書いて',
    answer: 'こんなプログラムはどうでしょう。',
    code: '# 1から10までを順番に表示する\n'
        'for i in range(1, 11):  # 1から10（11はふくまない）\n'
        '    print(i)',
    verdict: '作りたいもの・言葉・だれ向け・ほしい形が入っていて、いいおねがいだね！',
    good: true,
  ),
  _Prompt(
    label: 'C',
    request: '宿題ぜんぶやっておいて',
    answer: 'なにをすればいいか わかりません。それに、自分でやってみないと力がつかないよ。'
        'わからないところを教えてくれたら、いっしょに考えるよ。',
    verdict: '丸なげはNG。「ここがわからない」と聞くのが、じょうずな使い方。',
    good: false,
  ),
];

class _TryTab extends StatefulWidget {
  const _TryTab();

  @override
  State<_TryTab> createState() => _TryTabState();
}

class _TryTabState extends State<_TryTab> {
  int? _selected;
  int? _quizChoice;

  @override
  Widget build(BuildContext context) {
    final selected = _selected == null ? null : _prompts[_selected!];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          emoji: '💬',
          title: 'おねがいの書き方くらべ',
          children: [
            const _Body('AIにおねがいするとき、どの書き方がいいかな？ ひとつえらんで、AIの答え（れい）を見てみよう。'),
            for (var i = 0; i < _prompts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => setState(() => _selected = i),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(12),
                    side: BorderSide(
                      color: _selected == i
                          ? kPrimaryColor
                          : Colors.grey.withValues(alpha: 0.5),
                      width: _selected == i ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '${_prompts[i].label}. 「${_prompts[i].request}」',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
            if (selected != null) ...[
              const SizedBox(height: 4),
              const _Label('🤖 AIの答え（れい）', kPrimaryColor),
              _Body(selected.answer),
              if (selected.code != null) _CodeBox(selected.code!),
              _Label(
                selected.good ? '⭕ いいおねがい' : '⚠️ もうひとくふう',
                selected.good ? kPrimaryColor : const Color(0xFFE67E22),
              ),
              _Body(selected.verdict),
              const _Body('※ これは説明のために作った「れい」で、じっさいのAIの答えとはちがうことがあるよ。'),
            ],
          ],
        ),
        _Section(
          emoji: '🔍',
          title: 'AIのコードをチェックしよう',
          accent: const Color(0xFF8E44AD),
          children: [
            const _Body('「1から5までを全部たした数を出して」とAIにおねがいしたら、このコードが返ってきたよ。'),
            const _CodeBox(
              'total = 0\n'
              'for i in range(1, 5):\n'
              '    total = total + i\n'
              'print(total)',
            ),
            const _Body('このコードを動かすと、何が表示されるかな？'),
            Wrap(
              spacing: 8,
              children: [
                for (final v in [5, 10, 15])
                  ChoiceChip(
                    label: Text('$v'),
                    selected: _quizChoice == v,
                    onSelected: (_) => setState(() => _quizChoice = v),
                  ),
              ],
            ),
            if (_quizChoice != null) ...[
              const SizedBox(height: 10),
              _Label(
                _quizChoice == 10 ? '⭕ 正解！' : '❌ おしい！ 正解は 10',
                _quizChoice == 10 ? kPrimaryColor : const Color(0xFFE74C3C),
              ),
              const _Body('range(1, 5) は 1, 2, 3, 4 までで、5 はふくまれないよ。'
                  'だから 1+2+3+4 = 10 になる。'),
              const _Body('1から5をたしたいなら range(1, 6) が正しいんだ。'
                  'AIもこんなふうに数えまちがえることがあるから、自分で動かして たしかめよう！'),
              const _CodeBox(
                'total = 0\n'
                'for i in range(1, 6):  # ← 6 にすると 5 までたされる\n'
                '    total = total + i\n'
                'print(total)  # 15',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── 3. ちゅうい ─────────────────────────────────────────────────────────────

class _CautionTab extends StatelessWidget {
  const _CautionTab();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE74C3C);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Section(
          emoji: '🔒',
          title: '1. 自分や友だちのことを入れない',
          accent: red,
          children: [
            _Body('名前・住所・学校名・電話番号・顔がわかる写真は、AIに入力しないよ。'
                '入力したものが、どう使われるかわからないからね。'),
          ],
        ),
        _Section(
          emoji: '🔑',
          title: '2. パスワードや「ひみつのカギ」をはらない',
          accent: red,
          children: [
            _Body('パスワードやAPIキー（ひみつのカギ）を、AIに見せたり、コードにそのまま書いてネットに出したりしない。'
                '見つかると、他の人に使われてしまうよ。'),
          ],
        ),
        _Section(
          emoji: '✅',
          title: '3. 答えをうのみにしない',
          children: [
            _Bullet('かならず動かして、答えがあっているか たしかめる'),
            _Bullet('わからない言葉は、ほかの本やサイト、先生にも聞く'),
            _Bullet('「たぶん」で使わない。あやしいと思ったらやり直す'),
          ],
        ),
        _Section(
          emoji: '🧠',
          title: '4. まず自分で考える',
          children: [
            _Body('先にAIに答えをもらうと、考える力が育たないよ。まず自分で考えて、'
                'つまずいたときに ヒントをもらう使い方がおすすめ。宿題では、先生のルールも守ろう。'),
          ],
        ),
        _Section(
          emoji: '👨‍👩‍👧',
          title: '5. 使う前に、おうちの人に相談',
          children: [
            _Body('AIのサービスには、年れいの決まりや、利用のルールがあるよ。'
                '使う前に、かならずおうちの人といっしょに確認しよう。'),
          ],
        ),
        _Section(
          emoji: '💾',
          title: '6. 大事なものは、コピー（バックアップ）を取る',
          children: [
            _Body('AIに作業をまかせるときは、大事なデータのコピーを別の場所に残しておこう。'
                'まちがって消されても、もどせるようにするためだよ。'),
          ],
        ),
        _Section(
          emoji: '🤝',
          title: '7. 人をきずつけるものは作らない',
          children: [
            _Body('ほかの人の作品をまねしたり、いやがらせに使ったりしない。'
                'AIを使っても、作ったものの責任は自分にあるよ。'),
          ],
        ),
      ],
    );
  }
}

// ─── 4. わるいれい ───────────────────────────────────────────────────────────

class _BadExampleTab extends StatelessWidget {
  const _BadExampleTab();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE74C3C);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Body('ここでは、AIの使い方をまちがえて起きたことを紹介するよ。'
            '「実例」はニュースなどで報じられたできごと、「れい」は説明のために作った例だよ。'
            '（くわしい内容は、あとから変わることがあるよ）'),
        SizedBox(height: 8),
        _Section(
          emoji: '👻',
          title: '存在しない命令を作りだす',
          accent: red,
          children: [
            _Label('れい', Color(0xFF8E44AD)),
            _Body('AIが、こんなコードを自信まんまんに書いたとするよ。'),
            _CodeBox('numbers = [3, 1, 2]\nprint(numbers.sum_all())', bad: true),
            _Body('実行すると、エラーになる。Pythonのリストに sum_all() という命令は、そもそも無いんだ。'),
            _Label('実例', red),
            _Body('AIが「存在しないライブラリ（部品）の名前」をすすめることがあると、研究者から報告されているよ。'
                'その名前でにせ物を公開して、コピーした人をだます悪い手口も心配されている。'),
            _Label('どうすればよかった？', kPrimaryColor),
            _Bullet('知らない命令や部品は、公式の説明で本当にあるか調べる'),
            _Bullet('入れる前に、おうちの人や先生に聞く'),
          ],
        ),
        _Section(
          emoji: '📤',
          title: '会社のプログラムをAIに入力してしまった',
          accent: red,
          children: [
            _Label('実例', red),
            _Body('2023年、ある大手企業で、社員がAIに会社のプログラムを入力してしまい、'
                '情報が外にもれる心配があるとして、社内でのAIの利用を制限した、と報じられたよ。'),
            _Label('なぜダメ？', red),
            _Body('AIに入力した内容は、サービスによっては保存されたり、'
                '改善に使われたりすることがあるんだ。'),
            _Label('どうすればよかった？', kPrimaryColor),
            _Bullet('ひみつの情報・個人の情報は入力しない'),
            _Bullet('使っていいかどうか、ルールを先に確認する'),
          ],
        ),
        _Section(
          emoji: '🗑️',
          title: 'AIにまかせきりで、大事なデータが消えた',
          accent: red,
          children: [
            _Label('実例', red),
            _Body('2025年、AIに開発をまかせていた人が「変更しないで」と伝えていたのに、'
                'AIが大事なデータベースのデータを消してしまった、と報告して話題になったよ。'),
            _Label('なぜダメ？', red),
            _Body('AIは、まちがった作業を「いい考えだ」と思って実行してしまうことがあるんだ。'),
            _Label('どうすればよかった？', kPrimaryColor),
            _Bullet('大事なデータは、先にバックアップを取る'),
            _Bullet('AIが作業する場所を、練習用に分けておく'),
            _Bullet('やってほしくないことは、はっきり伝えて、結果も自分で確認する'),
          ],
        ),
        _Section(
          emoji: '⚖️',
          title: 'AIが作った「ウソの事例」をそのまま使った',
          accent: red,
          children: [
            _Label('実例', red),
            _Body('2023年、アメリカで弁護士がAIに調べてもらい、AIが作った「存在しない裁判の例」を'
                'そのまま裁判所に出して、責任を問われたと報じられたよ。'),
            _Label('学べること', kPrimaryColor),
            _Body('AIは、ほんとうのように見えるウソ（ハルシネーション）を作ることがある。'
                'プログラムでも同じで、かならず自分で確かめよう。'),
          ],
        ),
        _Section(
          emoji: '📋',
          title: 'コピペして、意味がわからなくなった',
          accent: red,
          children: [
            _Label('れい', Color(0xFF8E44AD)),
            _Body('AIが書いたコードをそのままコピーしたら、エラーが出た。'),
            _CodeBox('print("Hello, World!)', bad: true),
            _Body('でも、どこがまちがっているのか自分ではわからず、直せない…。'
                'ダブルクォート（"）が閉じていないのが原因だよ。'),
            _CodeBox('print("Hello, World!")'),
            _Label('どうすればよかった？', kPrimaryColor),
            _Bullet('コピーする前に、1行ずつ「これは何をしているかな？」と読む'),
            _Bullet('わからない行は、AIに「この行の意味を教えて」と聞く'),
          ],
        ),
        _Section(
          emoji: '🔓',
          title: 'ひみつのカギを、コードに書いてしまった',
          accent: red,
          children: [
            _Label('れい', Color(0xFF8E44AD)),
            _CodeBox('api_key = "sk-abc123-ひみつ"  # ← 書いてはダメ！', bad: true),
            _Body('こういうコードをネットに公開すると、だれでもそのカギを見られてしまう。'
                'カギを使われて、お金がかかったり、データを見られたりする心配があるよ。'),
            _Label('どうすればよかった？', kPrimaryColor),
            _Bullet('カギは、コードとは別の場所（設定ファイルなど）にしまう'),
            _Bullet('うっかり公開したら、すぐおうちの人に伝えて、カギを作りなおす'),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
