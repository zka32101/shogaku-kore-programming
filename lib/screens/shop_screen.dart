import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/shop_item.dart';
import '../providers/coin_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

/// コインショップ画面 (#15)
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ShopCategory? _selectedCategory; // null = 全て

  List<ShopItem> get _filteredItems {
    if (_selectedCategory == null) return kShopItems;
    return kShopItems.where((i) => i.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final coinState = ref.watch(coinProvider);

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
          '🏪 コインショップ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // コイン残高バッジ
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CoinBadge(balance: coinState.balance, large: false),
          ),
        ],
      ),
      body: Column(
        children: [
          // カテゴリフィルター
          _buildCategoryFilter(),
          // アイテムリスト
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('アイテムがありません'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, i) {
                      final item = _filteredItems[i];
                      final purchased = coinState.isPurchased(item.id);
                      return _ShopItemCard(
                        item: item,
                        purchased: purchased,
                        canAfford: coinState.balance >= item.price,
                        hintCount: coinState.hintCount,
                        onBuy: () => _onBuy(item, coinState.balance),
                      )
                          .animate(delay: Duration(milliseconds: 50 * i))
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.08, curve: Curves.easeOut);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [null, ...ShopCategory.values];
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = _selectedCategory == cat;
          final label = cat == null ? '🛒 全て' : cat.label;
          return GestureDetector(
            onTap: () {
              HapticService.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? kPrimaryColor
                    : kPrimaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? kPrimaryColor
                      : kPrimaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.white : kPrimaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onBuy(ShopItem item, int balance) async {
    if (balance < item.price) {
      // 残高不足ダイアログ
      HapticService.mediumImpact();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('コインが足りないよ！'),
          content: Text(
            '${item.name}は${item.price}コイン必要だけど、\n今は$balanceコインしかないよ。\n\nクイズをクリアしてコインを貯めよう！',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('わかった'),
            ),
          ],
        ),
      );
      return;
    }

    // 購入確認ダイアログ
    HapticService.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.emoji} ${item.name}を買う？'),
        content: Text(
          '${item.price}コインで「${item.name}」を購入しますか？\n\n残高: $balanceコイン → ${balance - item.price}コイン',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('やめる'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text(
              '買う！',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bool success;
    if (item.isConsumable) {
      // ヒント消耗品の場合
      final hintCount = item.id == 'hint_x3' ? 3 : 1;
      success = await ref.read(coinProvider.notifier)
          .purchaseHint(item.id, item.price, hintCount);
    } else {
      success = await ref.read(coinProvider.notifier)
          .purchaseItem(item.id, item.price);
    }

    if (!mounted) return;
    if (success) {
      HapticService.heavyImpact();
      SoundService().playComplete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name}をゲット！',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '−${item.price}コイン',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: kPrimaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// ─── コインバッジ（残高表示） ───

class CoinBadge extends StatelessWidget {
  final int balance;
  final bool large;

  const CoinBadge({super.key, required this.balance, this.large = false});

  @override
  Widget build(BuildContext context) => _CoinBadge(balance: balance, large: large);
}

class _CoinBadge extends StatelessWidget {
  final int balance;
  final bool large;

  const _CoinBadge({required this.balance, required this.large});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🪙',
            style: TextStyle(fontSize: large ? 18 : 14),
          ),
          const SizedBox(width: 4),
          Text(
            '$balance',
            style: TextStyle(
              fontSize: large ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B6914),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ショップアイテムカード ───

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool purchased;
  final bool canAfford;
  final int hintCount;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.item,
    required this.purchased,
    required this.canAfford,
    required this.hintCount,
    required this.onBuy,
  });

  Color get _categoryColor {
    switch (item.category) {
      case ShopCategory.character:  return const Color(0xFF9B59B6);
      case ShopCategory.background: return const Color(0xFF3498DB);
      case ShopCategory.sound:      return const Color(0xFF27AE60);
      case ShopCategory.hint:       return const Color(0xFFE67E22);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alreadyBought = purchased && !item.isConsumable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alreadyBought
              ? _categoryColor.withValues(alpha: 0.5)
              : _categoryColor.withValues(alpha: 0.2),
          width: alreadyBought ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 絵文字アイコン
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 情報エリア
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    // カテゴリチップ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.category.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: _categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textPrimary.withValues(alpha: 0.65),
                    height: 1.3,
                  ),
                ),
                // ヒント残り枚数（消耗品のみ）
                if (item.isConsumable && hintCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '現在のヒント残り: $hintCount 枚',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE67E22),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 購入ボタン or 購入済み表示
          if (alreadyBought)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _categoryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '✅',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'ゲット済み',
                    style: TextStyle(
                      fontSize: 9,
                      color: _categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: onBuy,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: canAfford
                      ? kPrimaryColor
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '🪙${item.price}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? Colors.white : Colors.grey,
                      ),
                    ),
                    Text(
                      'こうにゅう',
                      style: TextStyle(
                        fontSize: 9,
                        color: canAfford
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.grey,
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
