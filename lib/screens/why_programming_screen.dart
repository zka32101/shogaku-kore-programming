import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import 'programming_basics_screen.dart';

/// なぜプログラミングが必要か説明画面 (#13)
class WhyProgrammingScreen extends StatefulWidget {
  const WhyProgrammingScreen({super.key});

  @override
  State<WhyProgrammingScreen> createState() => _WhyProgrammingScreenState();
}

class _WhyProgrammingScreenState extends State<WhyProgrammingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      emoji: '🌍',
      title: 'プログラミングって何だろう？',
      description: 'プログラミングとは、コンピューターに「何をしてほしいか」を伝える言葉のこと。\n\nスマホのアプリ、ゲーム、ロボット…みんなプログラミングで動いているよ！',
      color: Color(0xFF3498DB),
    ),
    _PageData(
      emoji: '🎮',
      title: 'ゲームもアプリも！',
      description: 'あなたが毎日遊んでいるゲームも、友だちと話すアプリも、すべてプログラミングで作られているよ。\n\n将来、自分のゲームやアプリが作れるかも！',
      color: Color(0xFF9B59B6),
    ),
    _PageData(
      emoji: '🤖',
      title: 'ロボットや AI も！',
      description: '工場のロボット、自動で動く車、話しかけると答えてくれる AI…\n\nこれらもすべてプログラミングで動いているんだよ。',
      color: Color(0xFFE67E22),
    ),
    _PageData(
      emoji: '🧠',
      title: '考える力がつく！',
      description: 'プログラミングを学ぶと、\n\n✅ 問題を解く力\n✅ 順番に考える力\n✅ 創造する力\n\nが育つよ。将来どんな仕事にも役に立つんだ！',
      color: Color(0xFF27AE60),
    ),
    _PageData(
      emoji: '🚀',
      title: 'さあ始めよう！',
      description: 'ブロックを並べてロボットを動かしたり、Pythonでクイズに答えたり…\n\n楽しく遊びながらプログラミングを学ぼう！',
      color: kPrimaryColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cardBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'プログラミングってなに？',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ページビュー
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _pages.length,
              itemBuilder: (context, i) =>
                  _PageContent(data: _pages[i], index: i),
            ),
          ),
          // ドットインジケーター
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? _pages[_currentPage].color
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // ナビゲーションボタン
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('もどる'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _currentPage > 0 ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // 最後のページ → プログラミング基礎画面へ
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const ProgrammingBasicsScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? 'つぎへ ▶'
                            : '🚀 さっそく基礎を学ぶ',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _PageData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _PageContent extends StatelessWidget {
  final _PageData data;
  final int index;

  const _PageContent({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 絵文字アイコン
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                curve: Curves.elasticOut,
                duration: 600.ms,
              )
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 32),
          // タイトル
          Text(
            data.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: data.color,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 150.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),
          const SizedBox(height: 20),
          // 説明文
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: data.color.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              data.description,
              style: TextStyle(
                fontSize: 15,
                color: context.textPrimary,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(delay: 250.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOut),
        ],
      ),
    );
  }
}
