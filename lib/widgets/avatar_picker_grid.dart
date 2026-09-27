import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show AvatarModel, AvatarUnlockType, allAvatars;

import '../providers/coin_provider.dart';
import '../services/haptic_service.dart';

/// 国語など他アプリと同じ、コインで解放する共通アバターカタログの
/// うちプレミアム（課金）枠を除いたもの（無料4種＋コイン解放8種）。
List<AvatarModel> get kAvailableAvatars =>
    allAvatars.where((a) => a.unlockType != AvatarUnlockType.premium).toList();

/// 国語など他アプリと同じ仕組みのアバター選択グリッド。
/// 無料アバターはそのまま選択でき、コイン解放アバターは鍵アイコン付きで
/// 表示され、タップするとコインを消費して解放（→選択）できる。
class AvatarPickerGrid extends ConsumerWidget {
  final String selectedEmoji;
  final ValueChanged<AvatarModel> onSelect;
  final int crossAxisCount;

  const AvatarPickerGrid({
    super.key,
    required this.selectedEmoji,
    required this.onSelect,
    this.crossAxisCount = 6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasedIds = ref.watch(coinProvider).purchasedItemIds;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: kAvailableAvatars.map((avatar) {
        final isUnlocked = avatar.unlockType == AvatarUnlockType.free ||
            purchasedIds.contains(avatar.id);
        final isSelected = avatar.emoji == selectedEmoji;

        return GestureDetector(
          onTap: () => isUnlocked
              ? _select(avatar)
              : _tryUnlock(context, ref, avatar),
          child: _AvatarCell(
            avatar: avatar,
            isUnlocked: isUnlocked,
            isSelected: isSelected,
          ),
        );
      }).toList(),
    );
  }

  void _select(AvatarModel avatar) {
    HapticService.selectionClick();
    onSelect(avatar);
  }

  Future<void> _tryUnlock(
      BuildContext context, WidgetRef ref, AvatarModel avatar) async {
    final cost = avatar.coinCost ?? 0;
    final balance = ref.read(coinProvider).balance;

    if (balance < cost) {
      HapticService.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('コインが足りないよ！（あと${cost - balance}コイン）'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${avatar.emoji} ${avatar.name}'),
        content: Text('$cost コインを使ってこのアバターを解放する？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('解放する'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success =
        await ref.read(coinProvider.notifier).purchaseItem(avatar.id, cost);
    if (success) {
      HapticService.heavyImpact();
      _select(avatar);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('コインが足りないよ！')),
      );
    }
  }
}

class _AvatarCell extends StatelessWidget {
  final AvatarModel avatar;
  final bool isUnlocked;
  final bool isSelected;

  const _AvatarCell({
    required this.avatar,
    required this.isUnlocked,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: isUnlocked ? 1.0 : 0.35,
            child: Text(
              avatar.emoji,
              style: TextStyle(fontSize: isSelected ? 24 : 20),
            ),
          ),
          if (!isUnlocked)
            Positioned(
              bottom: 2,
              right: 2,
              child: Icon(
                Icons.lock,
                size: 11,
                color: Colors.grey.shade700,
              ),
            ),
          if (!isUnlocked && avatar.coinCost != null)
            Positioned(
              top: 1,
              child: Text(
                '🪙${avatar.coinCost}',
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
