import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_card.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/friend_model.dart';
import '../providers/friends_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

/// 受信中のフレンド申請一覧・承認/拒否画面
class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  String? _processingUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsProvider.notifier).loadReceivedRequests();
    });
  }

  Future<void> _accept(FriendRequestData request) async {
    HapticService.mediumImpact();
    SoundService().playTap();
    setState(() => _processingUid = request.fromUserId);

    final profile = ref.read(profileProvider);
    final points = ref.read(progressProvider.notifier).totalStarsEarned * 50;
    await ref.read(friendsProvider.notifier).acceptRequest(
          request,
          myNickname: profile.nickname,
          myAvatarEmoji: profile.avatarEmoji,
          myPoints: points,
        );

    if (!mounted) return;
    setState(() => _processingUid = null);
  }

  Future<void> _reject(FriendRequestData request) async {
    HapticService.lightImpact();
    setState(() => _processingUid = request.fromUserId);
    await ref.read(friendsProvider.notifier).rejectRequest(request);
    if (!mounted) return;
    setState(() => _processingUid = null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    ref.listen<FriendsState>(friendsProvider, (prev, next) {
      if (next.infoMessage != null && next.infoMessage != prev?.infoMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.infoMessage!), behavior: SnackBarBehavior.floating),
        );
        ref.read(friendsProvider.notifier).clearMessages();
      } else if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), behavior: SnackBarBehavior.floating),
        );
        ref.read(friendsProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: () => ref.read(friendsProvider.notifier).loadReceivedRequests(),
              child: state.receivedRequests.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: state.receivedRequests.length,
                      itemBuilder: (context, index) {
                        final req = state.receivedRequests[index];
                        return _RequestTile(
                          request: req,
                          isProcessing: _processingUid == req.fromUserId,
                          onAccept: () => _accept(req),
                          onReject: () => _reject(req),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryDark],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              '📬 フレンド申請',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
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
        const Text('📭', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          '届いているフレンド申請はありません',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  final FriendRequestData request;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestTile({
    required this.request,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

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
            child: Center(
              child: Text(request.fromAvatarEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              request.fromNickname,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          if (isProcessing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFE74C3C)),
              tooltip: '拒否',
              onPressed: onReject,
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: kPrimaryColor),
              tooltip: '承認',
              onPressed: onAccept,
            ),
          ],
        ],
      ),
    );
  }
}
