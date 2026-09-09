import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/friend_model.dart';
import '../providers/friends_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../utils/page_transitions.dart';
import 'add_friend_screen.dart';
import 'friend_requests_screen.dart';

/// フレンド一覧画面
class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider);
      final points = ref.read(progressProvider.notifier).totalStarsEarned * 50;
      ref.read(friendsProvider.notifier).syncMyPublicProfile(
            nickname: profile.nickname,
            avatarEmoji: profile.avatarEmoji,
            points: points,
          );
      ref.read(friendsProvider.notifier).loadFriends();
      ref.read(friendsProvider.notifier).loadReceivedRequests();
    });
  }

  Future<void> _refresh() async {
    await ref.read(friendsProvider.notifier).loadFriends();
    await ref.read(friendsProvider.notifier).loadReceivedRequests();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);
    final requestCount = ref.watch(pendingFriendRequestCountProvider);

    ref.listen<FriendsState>(friendsProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), behavior: SnackBarBehavior.floating),
        );
        ref.read(friendsProvider.notifier).clearMessages();
      } else if (next.infoMessage != null && next.infoMessage != prev?.infoMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.infoMessage!), behavior: SnackBarBehavior.floating),
        );
        ref.read(friendsProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, requestCount),
          Expanded(
            child: RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _refresh,
              child: state.isLoading && state.friends.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : state.friends.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: state.friends.length,
                          itemBuilder: (context, index) {
                            final friend = state.friends[index];
                            return _FriendTile(
                              friend: friend,
                              onRemove: () => _confirmRemove(context, friend),
                            ).animate(delay: Duration(milliseconds: 40 * index))
                                .fadeIn(duration: 250.ms)
                                .slideY(begin: 0.05, curve: Curves.easeOut, duration: 250.ms);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int requestCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryDark],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              '👫 フレンド',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline, color: Colors.white),
                tooltip: 'フレンド申請',
                onPressed: () {
                  HapticService.lightImpact();
                  SoundService().playTap();
                  Navigator.of(context).push(smoothPageRoute(const FriendRequestsScreen()));
                },
              ),
              if (requestCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE74C3C),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$requestCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            tooltip: 'フレンドを追加',
            onPressed: () {
              HapticService.lightImpact();
              SoundService().playTap();
              Navigator.of(context).push(smoothPageRoute(const AddFriendScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        const Text('👫', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          'まだフレンドがいません',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'ユーザーIDを知っている友だちを\n「フレンドを追加」から申請してみよう！',
          style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            HapticService.lightImpact();
            SoundService().playTap();
            Navigator.of(context).push(smoothPageRoute(const AddFriendScreen()));
          },
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('フレンドを追加'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, FriendData friend) async {
    HapticService.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('フレンドを削除しますか？'),
        content: Text('${friend.nickname} さんをフレンドから削除します。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('やめる')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除する', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(friendsProvider.notifier).removeFriend(friend.uid);
    }
  }
}

class _FriendTile extends StatelessWidget {
  final FriendData friend;
  final VoidCallback onRemove;

  const _FriendTile({required this.friend, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: context.shadowColor, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryDark]),
            ),
            child: Center(child: Text(friend.avatarEmoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.nickname,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '${friend.points}pt',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 20),
            color: context.textSecondary,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
