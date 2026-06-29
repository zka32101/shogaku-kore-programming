import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

/// プログラミング基礎説明画面 (#12)
class ProgrammingBasicsScreen extends StatefulWidget {
  const ProgrammingBasicsScreen({super.key});

  @override
  State<ProgrammingBasicsScreen> createState() =>
      _ProgrammingBasicsScreenState();
}

class _ProgrammingBasicsScreenState extends State<ProgrammingBasicsScreen> {
  int _selectedTab = 0;

  static const _tabs = [
    _TabData(label: '⬇️ じゅんばん', color: Color(0xFF3498DB)),
    _TabData(label: '🔀 もし～なら', color: Color(0xFF9B59B6)),
    _TabData(label: '🔁 くり返す', color: Color(0xFFE67E22)),
    _TabData(label: '🧩 ブロック操作', color: kPrimaryColor),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cardBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'プログラミング基礎',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // タブバー
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _tabs.length,
              itemBuilder: (context, i) {
                final tab = _tabs[i];
                final selected = i == _selectedTab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? tab.color
                          : tab.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? tab.color
                            : tab.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected ? Colors.white : tab.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // コンテンツ
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildContent(_selectedTab),
            ),
          ),
          // 閉じるボタン
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tabs[_selectedTab].color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '✅ わかった！ステージへ行く',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int tab) {
    switch (tab) {
      case 0:
        return _buildJunbanContent();
      case 1:
        return _buildMoshiContent();
      case 2:
        return _buildKurikaeshiContent();
      case 3:
        return _buildBlockContent();
      default:
        return const SizedBox();
    }
  }

  // ① じゅんばん（順次）
  Widget _buildJunbanContent() {
    return _ContentWrapper(
      key: const ValueKey('junban'),
      color: const Color(0xFF3498DB),
      emoji: '⬇️',
      title: 'じゅんばん（順次）',
      subtitle: 'プログラムは上から下へ、じゅんばんに動くよ！',
      children: [
        _CodeBlock(
          code: '① 前に進む\n② 右に曲がる\n③ 前に進む',
          color: const Color(0xFF3498DB),
          label: 'こんなふうに順番に動く！',
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: '💡',
          text: 'ロボットへの命令は、書いた順番に1つずつ実行されるよ。',
          color: const Color(0xFF3498DB),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: '🤖',
          text: 'ブロックを上から順番に並べることで、ロボットの動きを作れるよ！',
          color: const Color(0xFF3498DB),
        ),
      ],
    );
  }

  // ② もし～なら（条件分岐）
  Widget _buildMoshiContent() {
    return _ContentWrapper(
      key: const ValueKey('moshi'),
      color: const Color(0xFF9B59B6),
      emoji: '🔀',
      title: 'もし～なら（条件分岐）',
      subtitle: '状況によって違う動きができるよ！',
      children: [
        _CodeBlock(
          code: 'もし 壁があれば:\n  右に曲がる\nそうでなければ:\n  前に進む',
          color: const Color(0xFF9B59B6),
          label: '「もし壁があれば…」みたいに使う！',
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: '💡',
          text: '「もし～なら○○、そうでなければ××」というように、条件で動きを変えられるよ。',
          color: const Color(0xFF9B59B6),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: '🎮',
          text: 'ゲームで「体力が0になったらゲームオーバー」なのも、もし～ならの仕組みだよ！',
          color: const Color(0xFF9B59B6),
        ),
      ],
    );
  }

  // ③ くり返す（ループ）
  Widget _buildKurikaeshiContent() {
    return _ContentWrapper(
      key: const ValueKey('kurikaeshi'),
      color: const Color(0xFFE67E22),
      emoji: '🔁',
      title: 'くり返す（ループ）',
      subtitle: '同じ動きを何度もできるよ！',
      children: [
        _CodeBlock(
          code: '4回くり返す:\n  前に進む\n  右に曲がる',
          color: const Color(0xFFE67E22),
          label: '4回同じ動きをして四角を描ける！',
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: '💡',
          text: '同じ命令を何度も書かなくても「○回くり返す」で短く書けるよ。',
          color: const Color(0xFFE67E22),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: '🎵',
          text: '音楽のリピート再生も「くり返す」の仕組みで動いているよ！',
          color: const Color(0xFFE67E22),
        ),
      ],
    );
  }

  // ④ ブロック操作
  Widget _buildBlockContent() {
    return _ContentWrapper(
      key: const ValueKey('block'),
      color: kPrimaryColor,
      emoji: '🧩',
      title: 'ブロックの使い方',
      subtitle: 'タップしてブロックを並べてみよう！',
      children: [
        _HowToCard(
          step: '1',
          icon: '👆',
          title: 'パレットからブロックをタップ',
          description: '左側にあるブロックをタップすると、右側のスクリプトエリアに追加されるよ！',
          color: kPrimaryColor,
        ),
        const SizedBox(height: 10),
        _HowToCard(
          step: '2',
          icon: '✏️',
          title: 'ブロックをタップして数値を変える',
          description: 'スクリプトエリアのブロックをタップすると、歩数や角度を変えられるよ！',
          color: kPrimaryColor,
        ),
        const SizedBox(height: 10),
        _HowToCard(
          step: '3',
          icon: '↕️',
          title: 'ドラッグで順番を変える',
          description: 'ブロックをドラッグ＆ドロップして、順番を入れ替えられるよ！',
          color: kPrimaryColor,
        ),
        const SizedBox(height: 10),
        _HowToCard(
          step: '4',
          icon: '▶️',
          title: '「実行」→「回答する」でクリア！',
          description: 'ブロックを並べたら「実行」でプレビュー、「回答する」で答え合わせ！',
          color: kPrimaryColor,
        ),
      ],
    );
  }
}

class _TabData {
  final String label;
  final Color color;

  const _TabData({required this.label, required this.color});
}

class _ContentWrapper extends StatelessWidget {
  final Color color;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ContentWrapper({
    super.key,
    required this.color,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトルヘッダー
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideX(begin: -0.05, curve: Curves.easeOut),
          const SizedBox(height: 20),
          ...children
              .asMap()
              .entries
              .map((e) => e.value
                  .animate(delay: Duration(milliseconds: 80 * e.key))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOut)),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final Color color;
  final String label;

  const _CodeBlock({
    required this.code,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF4F4FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'monospace',
              color: context.textPrimary,
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: context.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  final String step;
  final String icon;
  final String title;
  final String description;
  final Color color;

  const _HowToCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
