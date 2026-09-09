import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/profile_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

/// フレンド追加画面（ユーザーID入力方式）
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final targetUid = _controller.text.trim();
    if (targetUid.isEmpty || _submitting) return;

    HapticService.lightImpact();
    SoundService().playTap();
    setState(() => _submitting = true);

    final profile = ref.read(profileProvider);
    final success = await ref.read(friendsProvider.notifier).sendFriendRequestTo(
          targetUid,
          myNickname: profile.nickname,
          myAvatarEmoji: profile.avatarEmoji,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    final state = ref.read(friendsProvider);
    if (success) {
      HapticService.mediumImpact();
      _controller.clear();
    }
    final message = success ? state.infoMessage : state.error;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      ref.read(friendsProvider.notifier).clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(currentUserProvider)?.uid ?? '';

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildMyIdCard(context, myUid),
                const SizedBox(height: 24),
                Text(
                  '追加したい相手のユーザーIDを入力してね',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  autofocus: false,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: '相手のユーザーIDを入力',
                    filled: true,
                    fillColor: context.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_submitting ? '送信中…' : 'フレンド申請を送る'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
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
              '➕ フレンドを追加',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // 左のIconButtonとバランスを取るためのスペーサー
        ],
      ),
    );
  }

  Widget _buildMyIdCard(BuildContext context, String myUid) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🆔', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'あなたのユーザーID',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
                Text(
                  myUid.isEmpty ? '取得中…' : myUid,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: kPrimaryColor,
            tooltip: 'コピー',
            onPressed: myUid.isEmpty
                ? null
                : () {
                    HapticService.lightImpact();
                    Clipboard.setData(ClipboardData(text: myUid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 コピーしました！友だちに教えてあげよう'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
