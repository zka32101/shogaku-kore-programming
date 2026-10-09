import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../providers/coin_provider.dart';
import 'decor_items.dart';
import 'decor_provider.dart';
import 'decor_scope.dart';

/// 買ったきせかえ（背景・フレーム・エフェクト）をえらんでつける画面。
class DecorScreen extends ConsumerWidget {
  const DecorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(coinProvider).purchasedItemIds;
    final active = ref.watch(activeDecorProvider);
    final mine = [for (final i in kDecorItems) if (owned.contains(i.id)) i];

    return Scaffold(
      backgroundColor: DecorScope.pageBg(context, context.cardBg),
      appBar: AppBar(
        title: const Text('きせかえ'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: mine.isEmpty
          ? const _Empty()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final kind in DecorKind.values) ...[
                  _Section(
                    kind: kind,
                    items: [for (final i in mine) if (i.kind == kind) i],
                    activeId: active.of(kind),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/illustrations/empty_closet.webp',
              key: const ValueKey('decor_empty_illustration'),
              width: 160,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'まだきせかえをもっていないよ。\nショップでコインとこうかんして、背景やフレームをゲットしよう！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.kind, required this.items, required this.activeId});

  final DecorKind kind;
  final List<DecorItem> items;
  final String? activeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    final notifier = ref.read(decorProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kind.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Tile(
              label: 'なし',
              selected: activeId == null,
              onTap: () => notifier.unequip(kind),
              child: const Icon(Icons.block, color: Colors.grey),
            ),
            for (final item in items)
              _Tile(
                label: item.name,
                selected: activeId == item.id,
                onTap: () => notifier.equip(item),
                child: Image.asset(
                  item.thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(child: Text(item.emoji, style: const TextStyle(fontSize: 26))),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.selected, required this.onTap, required this.child});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label${selected ? '、つけています' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 92,
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? kPrimaryColor : Colors.grey.shade300, width: selected ? 3 : 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
              const SizedBox(height: 4),
              Text(
                selected ? '✓ $label' : label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
