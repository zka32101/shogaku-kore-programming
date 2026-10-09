import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../providers/coin_provider.dart';
import 'title_items.dart';
import 'title_provider.dart';

/// きせかえ画面の「称号」区分。買う・つける・鍵つき（条件表示）。
class TitleSection extends ConsumerWidget {
  const TitleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coin = ref.watch(coinProvider);
    final progress = ref.watch(titleProgressProvider);
    final equipped = ref.watch(titleProvider);
    final notifier = ref.read(titleProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('称号', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final t in kTitleItems)
          _TitleRow(
            item: t,
            available: isTitleAvailable(t, owned: coin.purchasedItemIds, progress: progress),
            selected: equipped == t.id,
            canAfford: t.isPurchasable && coin.balance >= t.coinCost!,
            onEquip: () => equipped == t.id ? notifier.unequip() : notifier.equip(t),
            onBuy: () => notifier.buy(t),
          ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.item,
    required this.available,
    required this.selected,
    required this.canAfford,
    required this.onEquip,
    required this.onBuy,
  });

  final TitleItem item;
  final bool available;
  final bool selected;
  final bool canAfford;
  final VoidCallback onEquip;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final String sub;
    final Widget trailing;
    if (available) {
      sub = item.description;
      trailing = OutlinedButton(
        key: ValueKey('title_equip_${item.id}'),
        onPressed: onEquip,
        child: Text(selected ? 'はずす' : 'つける'),
      );
    } else if (item.isPurchasable) {
      sub = item.description;
      trailing = FilledButton(
        key: ValueKey('title_buy_${item.id}'),
        onPressed: canAfford ? onBuy : null,
        child: Text('🪙 ${item.coinCost}'),
      );
    } else {
      sub = '🔒 ${item.condition}';
      trailing = const Icon(Icons.lock_outline, color: Colors.grey);
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? kPrimaryColor : Colors.grey.shade300, width: selected ? 2 : 1),
      ),
      child: ListTile(
        title: Text(
          selected ? '✓ ${item.name}' : item.name,
          style: TextStyle(fontWeight: FontWeight.bold, color: available ? null : Colors.grey),
        ),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: trailing,
      ),
    );
  }
}
