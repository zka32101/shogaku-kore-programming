import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/profile_provider.dart';
import '../services/sound_service.dart';
import '../main.dart';
import '../widgets/shortcut_help.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final FocusNode _focusNode = FocusNode();
  int _currentPage = 0;

  // ページ1: ニックネーム＋アバター
  final _nicknameController = TextEditingController(text: 'たんけんか');
  String _selectedAvatar = '🧑‍💻';

  // ページ2: 機能紹介
  // ページ3: 完了

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  static const List<String> _avatarList = [
    '🧑‍💻', '👦', '👧', '🧒', '🐱', '🐶', '🦊', '🐸',
    '🚀', '⭐', '🌟', '💡', '🎮', '🎯', '🏆', '💎',
    '🌈', '🔥', '⚡', '🎵', '🎨', '🦁', '🐯', '🐼',
  ];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _scaleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _nextPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (_currentPage < 2) {
        _nextPage();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      if (_currentPage > 0) {
        HapticService.lightImpact();
        _pageController.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        return KeyEventResult.handled;
      }
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('Enter / Space / →', '次のページへ'),
        ('← / Esc / BS', '前のページへ'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _nextPage() {
    HapticService.lightImpact();
    SoundService().playTap();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    HapticService.heavyImpact();
    SoundService().playComplete();
    await ref.read(profileProvider.notifier).completeOnboarding(
      nickname: _nicknameController.text,
      avatarEmoji: _selectedAvatar,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigator(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            // ページインジケーター
            _buildIndicator(),
            // ページ本体
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
            // ナビゲーションボタン
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Container(
      color: context.cardBg,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final isActive = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? kPrimaryColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  // ──────────── Page 1: ニックネーム＋アバター選択 ────────────
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: const Text('🧑‍💻', style: TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 16),
          Text(
            'あなたの名前を教えて！',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ランキングやバッジに表示されるよ',
            style: TextStyle(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 24),
          // ニックネーム入力
          TextField(
            controller: _nicknameController,
            maxLength: 12,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'ニックネーム（最大12文字）',
              hintStyle:
                  const TextStyle(fontSize: 14, color: kTextSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: kPrimaryColor, width: 2),
              ),
              filled: true,
              fillColor: context.subCardBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'アバターを選ぼう',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // アバターグリッド
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _avatarList.map((emoji) {
              final isSelected = emoji == _selectedAvatar;
              return GestureDetector(
                onTap: () {
                  HapticService.selectionClick();
                  setState(() => _selectedAvatar = emoji);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimaryColor.withValues(alpha: 0.15)
                        : context.subCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: isSelected ? 24 : 20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ──────────── Page 2: 機能紹介 ────────────
  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎓', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'こんなことができるよ！',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          _FeatureCard(
            emoji: '🧩',
            title: 'ブロックプログラミング',
            desc: 'ブロックを並べてロボットを動かそう！\nビジュアルで直感的に学べるよ',
            color: const Color(0xFF1ABC9C),
          ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 12),
          _FeatureCard(
            emoji: '🐍',
            title: 'Python入門',
            desc: '本物のコードを書いてみよう！\nクイズ形式で楽しく学べるよ',
            color: const Color(0xFF9B59B6),
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideX(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 12),
          _FeatureCard(
            emoji: '🏆',
            title: 'バッジ＆ランキング',
            desc: 'クリアするとバッジがもらえるよ！\n友達とポイントを競おう',
            color: const Color(0xFFF39C12),
          ).animate(delay: 200.ms).fadeIn(duration: 350.ms).slideX(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
          const SizedBox(height: 12),
          _FeatureCard(
            emoji: '🃏',
            title: 'フラッシュカード＆今日の復習',
            desc: '用語カードで単語を記憶しよう！\n苦手問題を毎日復習できるよ',
            color: const Color(0xFF3498DB),
          ).animate(delay: 300.ms).fadeIn(duration: 350.ms).slideX(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
        ],
      ),
    );
  }

  // ──────────── Page 3: 完了 ────────────
  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🚀', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text(
            '${_nicknameController.text.trim().isEmpty ? "たんけんか" : _nicknameController.text.trim()} さん、\nようこそ！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'コードの世界を探険しよう！\nステージをクリアしてプログラマーを目指せ！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // 選択したアバター表示
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryColor, kPrimaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _selectedAvatar,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ).animate().scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1.0, 1.0),
            curve: Curves.elasticOut,
            duration: 600.ms,
          ),
          const SizedBox(height: 12),
          Text(
            _nicknameController.text.trim().isEmpty
                ? 'たんけんか'
                : _nicknameController.text.trim(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    final isLastPage = _currentPage == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      color: context.cardBg,
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('戻る'),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: kPrimaryColor,
                elevation: 4,
                shadowColor: kPrimaryColor.withValues(alpha: 0.4),
              ),
              child: Text(
                isLastPage ? '🚀 はじめる！' : '次へ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final Color color;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextSecondary,
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
