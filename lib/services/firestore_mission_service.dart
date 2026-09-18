import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/models/mission_model.dart';

/// Phase 4.5: ゲーミフィケーション統一工事（ミッション機能）
/// 実装: shared_core の ALL_MISSIONS リストから取得・フィルタリング
class FirestoreMissionService {
  static const String appId = 'programming'; // アプリID
  static List<Mission>? _cachedMissions; // キャッシュ

  /// ミッション取得
  /// shared_core の ALL_MISSIONS リストから対応するミッションを取得
  ///
  /// キャッシング機能付きで、パフォーマンス向上
  Future<List<Mission>> fetchMissions({String? subject}) async {
    try {
      // キャッシュから返す（初回のみ ALL_MISSIONS から取得）
      final missions = _cachedMissions ?? List<Mission>.from(ALL_MISSIONS);
      _cachedMissions = missions;

      // 難易度でソート（簡単→難しい）
      final sorted = _sortByDifficulty(missions);

      debugPrint('Fetched ${sorted.length} missions${subject != null ? ' for subject: $subject' : ''}');
      return sorted;
    } catch (e) {
      debugPrint('Error fetching missions: $e');
      rethrow;
    }
  }

  /// ミッションを難易度でソート
  List<Mission> _sortByDifficulty(List<Mission> missions) {
    return missions..sort((a, b) {
      final aDiff = a.difficulty?.toString().toLowerCase() ?? 'normal';
      final bDiff = b.difficulty?.toString().toLowerCase() ?? 'normal';

      const order = {'easy': 0, 'normal': 1, 'hard': 2};
      return (order[aDiff] ?? 1).compareTo(order[bDiff] ?? 1);
    });
  }

  /// ミッション進行度更新
  ///
  /// [missionId]: ミッション ID
  /// [progress]: 進行度（0-100 の値か、目標達成数）
  Future<void> updateProgress(String missionId, int progress) async {
    try {
      final db = FirebaseFirestore.instance;
      final userId = 'current_user'; // TODO: 実装時に実際のユーザーID取得

      await db
          .collection('users')
          .doc(userId)
          .collection('mission_progress')
          .doc(missionId)
          .set({
        'missionId': missionId,
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Mission $missionId progress updated to $progress (Firestore saved)');
    } catch (e) {
      debugPrint('Error updating mission progress: $e');
      rethrow;
    }
  }

  /// ミッション完了
  ///
  /// [missionId]: ミッション ID
  /// [userId]: ユーザー ID
  /// [reward]: 報酬（コイン）
  Future<void> completeMission(
    String missionId,
    String userId, {
    int reward = 0,
  }) async {
    try {
      final db = FirebaseFirestore.instance;

      // ミッション完了を記録
      await db
          .collection('users')
          .doc(userId)
          .collection('mission_progress')
          .doc(missionId)
          .set({
        'missionId': missionId,
        'progress': 100,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'reward': reward,
      }, SetOptions(merge: true));

      // 報酬を記録（コイン追加ログ）
      if (reward > 0) {
        await db
            .collection('users')
            .doc(userId)
            .collection('coin_transactions')
            .add({
          'type': 'mission_reward',
          'missionId': missionId,
          'amount': reward,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // ユーザーのコイン総数を更新
        await db.collection('users').doc(userId).set({
          'totalCoins': FieldValue.increment(reward),
          'lastRewardAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      debugPrint('Mission $missionId completed for user $userId (reward: $reward coins, Firestore saved)');
    } catch (e) {
      debugPrint('Error completing mission: $e');
      rethrow;
    }
  }

  /// キャッシュをクリア
  static void clearCache() {
    _cachedMissions = null;
    debugPrint('Mission cache cleared');
  }
}
