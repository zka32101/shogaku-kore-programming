import 'package:flutter/material.dart';
import 'package:shared_core/models/mission_model.dart';

/// Phase 4.5: ゲーミフィケーション統一工事（ミッション機能）
/// 簡略実装: shared_core の ALL_MISSIONS リストから取得・フィルタリング
class FirestoreMissionService {
  static const String appId = 'programming'; // アプリID

  /// ミッション取得（簡略実装）
  /// shared_core の ALL_MISSIONS リストから対応するミッションを取得
  Future<List<Mission>> fetchMissions({String? subject}) async {
    try {
      var missions = List<Mission>.from(ALL_MISSIONS);

      // 教科でフィルタリング
      if (subject != null && subject.isNotEmpty) {
        missions = missions.where((mission) {
          if (mission.subject == null) return true;
          return mission.subject == subject;
        }).toList();
      }

      // 無効なミッションを除外
      missions = missions.where((m) => m.enabled).toList();

      debugPrint('Fetched ${missions.length} missions${subject != null ? ' for subject: $subject' : ''}');
      return missions;
    } catch (e) {
      debugPrint('Error fetching missions: $e');
      rethrow;
    }
  }

  /// ミッション進行度更新（簡略実装）
  Future<void> updateProgress(String missionId, int progress) async {
    try {
      debugPrint('Mission $missionId progress updated to $progress');
    } catch (e) {
      debugPrint('Error updating mission progress: $e');
    }
  }

  /// ミッション完了（簡略実装）
  Future<void> completeMission(String missionId, String userId) async {
    try {
      debugPrint('Mission $missionId completed for user $userId');
    } catch (e) {
      debugPrint('Error completing mission: $e');
    }
  }
}
