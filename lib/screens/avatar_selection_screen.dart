import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/avatar.dart';
import '../providers/avatar_provider.dart';
import '../providers/coin_provider.dart';

/// Avatar selection screen for user profile customization
class AvatarSelectionScreen extends ConsumerWidget {
  final VoidCallback? onAvatarSelected;

  const AvatarSelectionScreen({
    this.onAvatarSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarState = ref.watch(avatarProvider);
    final coinState = ref.watch(coinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Selection'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current selection preview
              _buildCurrentAvatarPreview(
                context,
                avatarState.selectedAvatar,
              ),
              const SizedBox(height: 32),

              // Available avatars section
              _buildSection(
                title: 'Available Avatars',
                child: _buildAvatarGrid(
                  context,
                  ref,
                  avatarState.availableAvatars,
                  isSelectable: true,
                  coinState: coinState,
                  avatarState: avatarState,
                ),
              ),
              const SizedBox(height: 32),

              // Purchasable avatars section
              if (avatarState.purchasableAvatars.isNotEmpty)
                _buildSection(
                  title: 'Premium Avatars',
                  child: _buildAvatarGrid(
                    context,
                    ref,
                    avatarState.purchasableAvatars,
                    isSelectable: false,
                    coinState: coinState,
                    avatarState: avatarState,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build current avatar preview
  Widget _buildCurrentAvatarPreview(
    BuildContext context,
    Avatar avatar,
  ) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              avatar.emoji,
              style: const TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            avatar.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            'Currently selected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build section with title
  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        child,
      ],
    );
  }

  /// Build avatar grid
  Widget _buildAvatarGrid(
    BuildContext context,
    WidgetRef ref,
    List<Avatar> avatars,
    {
      required bool isSelectable,
      required CoinState coinState,
      required AvatarState avatarState,
    }
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final isSelected = avatar.id == avatarState.selectedAvatarId;

        return _buildAvatarCard(
          context,
          ref,
          avatar,
          isSelected: isSelected,
          isSelectable: isSelectable,
          canAfford: coinState.balance >= avatar.price,
        );
      },
    );
  }

  /// Build individual avatar card
  Widget _buildAvatarCard(
    BuildContext context,
    WidgetRef ref,
    Avatar avatar,
    {
      required bool isSelected,
      required bool isSelectable,
      required bool canAfford,
    }
  ) {
    return GestureDetector(
      onTap: () {
        if (isSelectable && !isSelected) {
          _selectAvatar(context, ref, avatar);
        } else if (!isSelectable && canAfford) {
          _purchaseAvatar(context, ref, avatar);
        }
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          )
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar emoji
              Text(
                avatar.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),

              // Avatar name
              Text(
                avatar.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (!isSelectable) ...[
                const SizedBox(height: 8),
                // Price or purchase button
                if (canAfford)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${avatar.price} 🪙',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${avatar.price} 🪙',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],

              if (isSelected) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Handle avatar selection
  Future<void> _selectAvatar(
    BuildContext context,
    WidgetRef ref,
    Avatar avatar,
  ) async {
    final notifier = ref.read(avatarProvider.notifier);
    final success = await notifier.selectAvatar(avatar.id);

    if (success && context.mounted) {
      onAvatarSelected?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${avatar.name} selected!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle avatar purchase
  Future<void> _purchaseAvatar(
    BuildContext context,
    WidgetRef ref,
    Avatar avatar,
  ) async {
    final notifier = ref.read(avatarProvider.notifier);
    final success = await notifier.purchaseAvatar(avatar.id);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${avatar.name} purchased!'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to purchase ${avatar.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
