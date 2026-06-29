import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/shortcut_help.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPlan = 1; // 0=月額, 1=年額（推奨）
  late AnimationController _starController;
  late Animation<double> _starAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _starAnimation = CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _starController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      setState(() => _selectedPlan = 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      setState(() => _selectedPlan = 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    // ? → キーボードショートカット一覧
    if (key == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed) {
      showShortcutsHelpDialog(context, shortcuts: const [
        ('1', '月額プランを選択'),
        ('2', '年額プランを選択'),
        ('Esc / BS', '戻る'),
        ('?', 'このヘルプを表示'),
      ]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            // グラジェントヘッダー
            _buildHeader(context),
          // スクロールコンテンツ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  // 特徴リスト
                  _buildFeatureList(context)
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut, duration: 350.ms),
                  const SizedBox(height: 20),
                  // 料金プラン
                  _PricingCard(
                    isSelected: _selectedPlan == 0,
                    title: '月額プラン',
                    price: '¥999',
                    unit: '/ 月',
                    description: '毎月自動更新',
                    badge: null,
                    onTap: () => setState(() => _selectedPlan = 0),
                  ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(
                        begin: 0.1,
                        curve: Curves.easeOut,
                        duration: 300.ms,
                      ),
                  const SizedBox(height: 10),
                  _PricingCard(
                    isSelected: _selectedPlan == 1,
                    title: '年額プラン',
                    price: '¥5,980',
                    unit: '/ 年',
                    description: '月あたり約¥498（お得！）',
                    badge: '2ヶ月分お得',
                    onTap: () => setState(() => _selectedPlan = 1),
                  ).animate(delay: 180.ms).fadeIn(duration: 300.ms).slideY(
                        begin: 0.1,
                        curve: Curves.easeOut,
                        duration: 300.ms,
                      ),
                  const SizedBox(height: 16),
                  // 保護者向けメモ
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.isDark ? context.subCardBg : const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(10),
                      border: const Border(
                        left: BorderSide(color: Color(0xFFF39C12), width: 3),
                      ),
                    ),
                    child: Text(
                      '💡 保護者のクレジットカードでのお支払いです。\n課金前にご確認ください。',
                      style: TextStyle(
                          fontSize: 12, color: context.textPrimary, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 登録ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('まもなく開始予定です！お楽しみに 🎉'),
                            backgroundColor: kPrimaryColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: kPrimaryColor.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        _selectedPlan == 1
                            ? '年額プランで始める（¥5,980）'
                            : '月額プランで始める（¥999/月）',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '今は無料で続ける',
                      style: TextStyle(color: kTextSecondary, fontSize: 14),
                    ),
                  ),
                  const Text(
                    '初月7日間無料トライアル · いつでもキャンセル可',
                    style: TextStyle(fontSize: 11, color: kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      ),  // closes Scaffold (child of Focus)
    );    // closes Focus return
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
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        24,
      ),
      child: Column(
        children: [
          // 閉じるボタン
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // アニメーション付きアイコン
          AnimatedBuilder(
            animation: _starAnimation,
            builder: (_, child) => Transform.scale(
              scale: 1.0 + _starAnimation.value * 0.08,
              child: child,
            ),
            child: const Text('⭐', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 12),
          const Text(
            'プレミアムプラン',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'すべてのステージを解放して\nプログラミングを極めよう！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'プレミアム特典',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureItem(
              emoji: '🚀',
              text: '全${AppConstants.totalStages}ステージ解放！上級Python も学べる'),
          const _FeatureItem(
              emoji: '🐍',
              text: 'ファイル操作・文字列処理・クラス応用'),
          const _FeatureItem(
              emoji: '🏆',
              text: 'バッジ・実績を全て獲得できる'),
          const _FeatureItem(emoji: '🔕', text: '広告なしで集中して学習'),
          const _FeatureItem(
              emoji: '👨‍👩‍👧',
              text: '保護者ダッシュボードで詳細な学習管理'),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String emoji;
  final String text;

  const _FeatureItem({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: context.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String price;
  final String unit;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  const _PricingCard({
    required this.isSelected,
    required this.title,
    required this.price,
    required this.unit,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8E44AD) : context.borderColor,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF8E44AD).withValues(alpha: 0.2)
                  : context.shadowColor,
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 選択インジケーター
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8E44AD)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF8E44AD) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // プラン情報
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
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            // 価格
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(
                          fontSize: 11, color: kTextSecondary),
                    ),
                  ],
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E44AD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
