import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/friend_model.dart';
import '../models/robot_stage.dart';
import '../providers/friends_provider.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../services/stage_share_service.dart';
import 'add_friend_screen.dart';
import 'robot_game_screen.dart';
import 'robot_stage_editor_screen.dart';

/// 「ともだちステージ」: 友だちが作って送ってくれたステージで遊ぶ／
/// 自分が作ったステージを友だちに送って、遊んだ結果を見る。
///
/// 送れる相手はフレンド登録した友だちだけ。自由に書けるコメントは無い。
class StageShareScreen extends ConsumerStatefulWidget {
  const StageShareScreen({super.key});

  @override
  ConsumerState<StageShareScreen> createState() => _StageShareScreenState();
}

class _StageShareScreenState extends ConsumerState<StageShareScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _created = CreatedStageStore();
  final _played = PlayedStageStore();
  final _service = StageShareService.instance;

  List<SharedStage>? _inbox;
  List<RobotStage> _mine = [];
  Map<String, int> _playedStars = {};
  String? _inboxError;
  bool _loading = true; // 端末内のデータの読み込み
  bool _inboxLoading = true; // 友だちからの受信（通信）の読み込み

  /// Firebase が使えない状況（未初期化・オフライン等）でも例外にせず null を返す。
  String? get _uid {
    try {
      return AuthService().currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsProvider.notifier).loadFriends();
    });
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    if (e is TimeoutException) {
      return 'つながらなかったよ。ネットを 見なおして、もう一度ためしてね。';
    }
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'まだ つかえないみたい。少しまってから もう一度ためしてね。';
    }
    return 'つながらなかったよ。ネットを 見なおして、もう一度ためしてね。';
  }

  Future<void> _reload() async {
    // 端末内のデータ（自分が作ったステージ）は通信なしですぐに表示する
    final mine = await _created.load();
    final played = await _played.load();
    if (!mounted) return;
    setState(() {
      _mine = mine;
      _playedStars = played;
      _loading = false;
      _inboxLoading = true;
      _inboxError = null;
    });

    // 友だちから届いたステージは通信して取得する（失敗しても他は使える）
    List<SharedStage>? inbox;
    String? error;
    final uid = _uid;
    if (uid == null) {
      error = 'ネットに つながっていないよ。';
    } else {
      try {
        inbox = await _service.fetchInbox(uid);
      } catch (e) {
        error = _friendlyError(e);
      }
    }
    if (!mounted) return;
    setState(() {
      _inbox = inbox;
      _inboxError = error;
      _inboxLoading = false;
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _play(SharedStage shared) async {
    HapticService.lightImpact();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RobotGamePlay(
          stages: [shared.stage],
          onCleared: (i, stars, blocks) => _onCleared(shared, stars, blocks),
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _onCleared(SharedStage shared, int stars, int blocks) async {
    await _played.save(shared.stage.id, stars);
    final uid = _uid;
    if (uid == null) return;
    final profile = ref.read(profileProvider);
    try {
      await _service.submitResult(
        ownerUid: shared.fromUid,
        stageId: shared.stage.id,
        playerUid: uid,
        playerName: profile.nickname,
        playerAvatar: profile.avatarEmoji,
        stars: stars,
        blocks: blocks,
      );
      if (mounted) _snack('${shared.fromName}さんに けっかを おくったよ！');
    } catch (_) {
      // 結果が送れなくても、遊んだ記録は端末に残っている
      if (mounted) _snack('けっかは おくれなかったけど、クリアは きろくしたよ。');
    }
  }

  Future<void> _deleteInbox(SharedStage shared) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.deleteInboxItem(uid, shared.stage.id);
      await _reload();
    } catch (e) {
      _snack(_friendlyError(e));
    }
  }

  Future<void> _sendDialog(RobotStage stage) async {
    final friends = ref.read(friendsProvider).friends;
    if (friends.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ともだちがいないよ'),
          content: const Text('ステージを送るには、先に ともだちを追加してね。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('とじる')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AddFriendScreen()),
                );
              },
              child: const Text('ともだちを追加'),
            ),
          ],
        ),
      );
      return;
    }
    final selected = <String>{};
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '「${stage.title}」を だれに送る？',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final FriendData f in friends)
                        CheckboxListTile(
                          value: selected.contains(f.uid),
                          onChanged: (v) => setLocal(() {
                            if (v == true) {
                              selected.add(f.uid);
                            } else {
                              selected.remove(f.uid);
                            }
                          }),
                          title: Text('${f.avatarEmoji} ${f.nickname}'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(ctx, selected.toList()),
                    child: Text('${selected.length}人に送る'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    final uid = _uid;
    if (uid == null) {
      _snack('ネットに つながっていないよ。');
      return;
    }
    final profile = ref.read(profileProvider);
    try {
      final sent = await _service.sendStage(
        stage: stage,
        fromUid: uid,
        fromName: profile.nickname,
        fromAvatar: profile.avatarEmoji,
        toUids: picked,
      );
      if (mounted) _snack('$sent人に ステージを送ったよ！');
    } catch (e) {
      if (mounted) _snack(_friendlyError(e));
    }
  }

  Future<void> _showResults(RobotStage stage) async {
    final uid = _uid;
    if (uid == null) {
      _snack('ネットに つながっていないよ。');
      return;
    }
    List<StageResult> results;
    try {
      results = await _service.fetchResults(uid, stage.id);
    } catch (e) {
      _snack(_friendlyError(e));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('「${stage.title}」の けっか'),
        content: SizedBox(
          width: double.maxFinite,
          child: results.isEmpty
              ? const Text('まだ だれも あそんでいないよ。')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in results)
                      ListTile(
                        dense: true,
                        leading: Text(r.playerAvatar, style: const TextStyle(fontSize: 22)),
                        title: Text(r.playerName),
                        subtitle: Text('ブロック ${r.blocks} こ'),
                        trailing: Text(
                          '★' * r.stars + '☆' * (3 - r.stars),
                          style: const TextStyle(color: Colors.amber),
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('とじる')),
        ],
      ),
    );
  }

  Future<void> _deleteMine(RobotStage stage) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('このステージを消す？'),
        content: Text('「${stage.title}」を 消すよ。もう送れなくなるよ。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('やめる')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('消す')),
        ],
      ),
    );
    if (ok != true) return;
    await _created.remove(stage.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤝 ともだちステージ'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'もらったステージ'), Tab(text: 'つくったステージ')],
        ),
        actions: [
          IconButton(
            tooltip: '読みこみなおす',
            icon: const Icon(Icons.refresh),
            onPressed: _loading || _inboxLoading ? null : _reload,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [_buildInbox(context), _buildMine(context)],
            ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }

  Widget _buildInbox(BuildContext context) {
    if (_inboxLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_inboxError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_inboxError!, textAlign: TextAlign.center),
        ),
      );
    }
    final inbox = _inbox ?? const <SharedStage>[];
    if (inbox.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'まだ ステージが届いていないよ。\n友だちに「ステージを作って送ってね」と おねがいしてみよう！',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.6, color: context.textSecondary),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in inbox)
          _card(
            context,
            child: Row(
              children: [
                Text(s.fromAvatar, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.stage.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '${s.fromName} さんより ・ ⭐3つは ${s.stage.par} こ',
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                if ((_playedStars[s.stage.id] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '★' * _playedStars[s.stage.id]!,
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => _play(s),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('あそぶ'),
                ),
                IconButton(
                  tooltip: '消す',
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => _deleteInbox(s),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMine(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const RobotStageEditorScreen()),
            );
            if (mounted) _reload();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.add),
          label: const Text('あたらしくステージを作る'),
        ),
        const SizedBox(height: 12),
        if (_mine.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'まだ ステージがないよ。\n作って、自分でクリアして、友だちに送ろう！',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6, color: context.textSecondary),
            ),
          ),
        for (final s in _mine)
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '消す',
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () => _deleteMine(s),
                    ),
                  ],
                ),
                Text(
                  '⭐3つは ブロック ${s.par} こ',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sendDialog(s),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('ともだちに送る'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showResults(s),
                        icon: const Icon(Icons.emoji_events_outlined, size: 16),
                        label: const Text('けっか'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
