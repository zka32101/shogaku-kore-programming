import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final premiumState = ref.watch(premiumProvider);

    if (!premiumState.isSubscribed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('オンライン対戦'),
          centerTitle: true,
          backgroundColor: _primaryColor,
        ),
        body: PremiumGateWidget(
          featureName: 'オンライン対戦',
          onPremiumAccess: () => _showSubscriptionDialog(context),
        ),
      );
    }

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

    // TODO: Firestore でマッチリクエスト作成
    await Future.delayed(const Duration(seconds: 3));

    // ダミー対戦相手（本来は Firestore から取得）
    setState(() {
      _isMatching = false;
      _opponent = BattleOpponent(
        id: 'user_001',
        name: 'プログラマー太郎',
        rating: 1250,
        winRate: 72,
      );
    });
  }

  Future<void> _startBattle() async {
    if (_opponent == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('対戦を開始しました')),
    );

    // TODO: battle_screen へナビゲート
    // context.push('/battle/${_opponent!.id}');
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
