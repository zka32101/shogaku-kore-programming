import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/avatar_provider.dart';

/// Simple widget to display current user avatar
class AvatarDisplayWidget extends ConsumerWidget {
  final double size;
  final VoidCallback? onTap;

  const AvatarDisplayWidget({
    this.size = 48.0,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarState = ref.watch(avatarProvider);
    final selectedAvatar = avatarState.selectedAvatar;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            selectedAvatar.emoji,
            style: TextStyle(fontSize: size * 0.6),
          ),
        ),
      ),
    );
  }
}

/// Avatar display card showing name and emoji
class AvatarCardWidget extends ConsumerWidget {
  final double size;

  const AvatarCardWidget({
    this.size = 64.0,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarState = ref.watch(avatarProvider);
    final selectedAvatar = avatarState.selectedAvatar;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedAvatar.emoji,
              style: TextStyle(fontSize: size),
            ),
            const SizedBox(height: 8),
            Text(
              selectedAvatar.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
