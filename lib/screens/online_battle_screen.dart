import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/providers/premium_provider.dart';
import 'package:shared_core/widgets/premium_gate_widget.dart';

const _primaryColor = Colors.deepPurple;

class OnlineBattleScreen extends ConsumerStatefulWidget {
  const OnlineBattleScreen({super.key});

  @override
  ConsumerState<OnlineBattleScreen> createState() =>
      _OnlineBattleScreenState();
}

class _OnlineBattleScreenState extends ConsumerState<OnlineBattleScreen> {
  bool _isMatching = false;
  BattleOpponent? _opponent;

  @override
  Widget build(BuildContext context) {
    // TODO: PremiumState API integration needed with shared_core
    // Placeholder while premium features are being integrated
    return Scaffold(
      appBar: AppBar(
        title: const Text('オンライン対戦'),
        centerTitle: true,
        backgroundColor: _primaryColor,
      ),
      body: const Center(
        child: Text('オンライン対戦: 準備中'),
      ),
    );

    // Original code below (commented out pending shared_core API clarification):
    // final premiumState = ref.watch(premiumProvider);
    //
    // if (!premiumState.isSubscribed) {
    //   return Scaffold(
    //     appBar: AppBar(
    //       title: const Text('オンライン対戦'),
    //       centerTitle: true,
    //       backgroundColor: _primaryColor,
    //     ),
    //     body: PremiumGateWidget(
    //       featureName: 'オンライン対戦',
    //       onPremiumAccess: () => _showSubscriptionDialog(context),
    //     ),
    //   );
    // }

    /*
    return Scaffold(
      appBar: AppBar(
        title: const Text('オンライン対戦'),
        centerTitle: true,
        backgroundColor: _primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // マッチロビー
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isMatching)
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(_primaryColor),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'プレイヤーマッチング中...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '同じスキルレベルの対戦相手を探しています',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    )
                  else
                    const Text(
                      'オンライン対戦に参加',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 対戦相手情報
          if (_opponent != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '対戦相手',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _primaryColor.withOpacity(0.2),
                          child: Text(
                            _opponent!.name[0],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _opponent!.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'レート: ${_opponent!.rating}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_opponent!.winRate}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '勝率',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (_opponent == null && !_isMatching)
            Column(
              children: [
                const SizedBox(height: 24),
                // ここに難易度選択など追加可能
              ],
            ),

          const SizedBox(height: 24),

          // マッチ開始/キャンセルボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isMatching ? null : _handleBattleAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _opponent != null ? Colors.green : _primaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isMatching
                    ? 'マッチング中...'
                    : _opponent != null
                        ? '対戦開始'
                        : 'マッチング開始',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          if (_opponent != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _opponent = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('マッチングをやり直す'),
              ),
            ),
        ],
      ),
    );
    */
  }

  Future<void> _handleBattleAction() async {
    if (_opponent != null) {
      // 対戦開始
      await _startBattle();
    } else {
      // マッチング開始
      await _startMatching();
    }
  }

  Future<void> _startMatching() async {
    setState(() {
      _isMatching = true;
    });

    try {
      final db = FirebaseFirestore.instance;
      final matchRequestId = db.collection('match_requests').doc().id;

      // マッチリクエスト作成
      await db.collection('match_requests').doc(matchRequestId).set({
        'userId': 'current_user',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'skill_level': 'intermediate',
      });

      // マッチング検索（Firestore クエリ）
      final querySnapshot = await db
          .collection('match_requests')
          .where('status', isEqualTo: 'waiting')
          .where('userId', isNotEqualTo: 'current_user')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final opponentDoc = querySnapshot.docs.first;
        final opponentId = opponentDoc['userId'];

        // マッチング成功時にバトルレコード作成
        await db.collection('battles').add({
          'player1_id': 'current_user',
          'player2_id': opponentId,
          'status': 'waiting_to_start',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // リクエスト削除
        await db.collection('match_requests').doc(matchRequestId).delete();
        await db
            .collection('match_requests')
            .doc(opponentDoc.id)
            .delete();

        // ダミー対戦相手情報を設定
        setState(() {
          _isMatching = false;
          _opponent = BattleOpponent(
            id: opponentId,
            name: 'オンラインプレイヤー',
            rating: 1200,
            winRate: 65,
          );
        });
      } else {
        // マッチング対象なし（タイムアウト後ダミー相手を返す）
        await Future.delayed(const Duration(seconds: 5));

        setState(() {
          _isMatching = false;
          _opponent = BattleOpponent(
            id: 'bot_001',
            name: 'プログラマー太郎',
            rating: 1250,
            winRate: 72,
          );
        });
      }
    } catch (e) {
      debugPrint('マッチング失敗: $e');
      setState(() {
        _isMatching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('マッチング失敗: $e')),
        );
      }
    }
  }

  Future<void> _startBattle() async {
    if (_opponent == null) return;

    try {
      final db = FirebaseFirestore.instance;

      // バトル開始ログを Firestore に記録
      await db.collection('battles').add({
        'player1_id': 'current_user',
        'opponent_id': _opponent!.id,
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_opponent!.name} と対戦開始！')),
      );

      // TODO: battle_screen へナビゲート（画面未実装）
      // context.push('/battle/${_opponent!.id}');
    } catch (e) {
      debugPrint('バトル開始エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('バトル開始失敗: $e')),
        );
      }
    }
  }

  Future<void> _showSubscriptionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアム機能'),
        content: const Text(
          'オンライン対戦は月額¥120のプレミアム会員向けです。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: RevenueCat の購入フロー
            },
            child: const Text('今すぐ購読'),
          ),
        ],
      ),
    );
  }
}

/// 対戦相手情報モデル
class BattleOpponent {
  final String id;
  final String name;
  final int rating;
  final int winRate;

  BattleOpponent({
    required this.id,
    required this.name,
    required this.rating,
    required this.winRate,
  });
}
