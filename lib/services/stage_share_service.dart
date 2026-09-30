import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/robot_stage.dart';

/// 自分が作ったステージの端末内保存（作った人が自分でクリアしたものだけが入る）。
class CreatedStageStore {
  static const _key = 'robot_created_stages_v1';
  static const int maxStages = 20;

  Future<List<RobotStage>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return [
        for (final m in list) ?RobotStage.tryParse(m),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<RobotStage> stages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final s in stages) s.toMap()]));
  }

  /// 追加する。上限を超える場合は false。
  Future<bool> add(RobotStage stage) async {
    final stages = await load();
    if (stages.length >= maxStages) return false;
    stages.insert(0, stage);
    await _write(stages);
    return true;
  }

  Future<void> remove(String id) async {
    final stages = await load()..removeWhere((s) => s.id == id);
    await _write(stages);
  }
}

/// 友だちが遊んだステージの記録（端末内）。stageId → 星の数。
class PlayedStageStore {
  static const _key = 'robot_played_shared_stages_v1';

  Future<Map<String, int>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map).cast<String, int>();
    } catch (_) {
      return {};
    }
  }

  Future<void> save(String stageId, int stars) async {
    final map = await load();
    if ((map[stageId] ?? 0) >= stars) return;
    map[stageId] = stars;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }
}

/// ステージを友だちに送る／結果を受け取る Firestore アクセス層。
///
/// データ構造（フレンドの `users/{uid}/friends` を前提にしたフレンド限定の設計）:
/// - `users/{相手}/inbox/{stageId}`              : 相手に届いたステージ（送り主が書く）
/// - `users/{作者}/stageResults/{stageId}_{遊んだ人}` : 遊んだ結果（遊んだ人が書く）
///
/// どちらもフレンド同士でなければ書き込めない（firestore.rules で強制）。
/// 自由入力のテキストはステージ名（定型の候補から選ぶ）だけで、
/// コメントなどの自由文は扱わない。
class StageShareService {
  StageShareService._();
  static final StageShareService instance = StageShareService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// 通信が切れていると Firestore は待ち続けるため、一定時間で打ち切る。
  static const _timeout = Duration(seconds: 10);
  Future<T> _t<T>(Future<T> f) => f.timeout(_timeout);

  /// [stage] を [toUids] のフレンドに送る。送れた人数を返す。
  Future<int> sendStage({
    required RobotStage stage,
    required String fromUid,
    required String fromName,
    required String fromAvatar,
    required List<String> toUids,
  }) async {
    final shared = SharedStage(
      stage: stage,
      fromUid: fromUid,
      fromName: fromName,
      fromAvatar: fromAvatar,
      createdAt: DateTime.now(),
    );
    var sent = 0;
    for (final uid in toUids) {
      if (uid == fromUid) continue;
      await _t(_db
          .collection('users')
          .doc(uid)
          .collection('inbox')
          .doc(stage.id)
          .set(shared.toMap()));
      sent++;
    }
    return sent;
  }

  /// 自分に届いたステージ（新しい順）。
  Future<List<SharedStage>> fetchInbox(String myUid) async {
    final snap = await _t(_db
        .collection('users')
        .doc(myUid)
        .collection('inbox')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get());
    return [
      for (final d in snap.docs) ?SharedStage.tryParse(d.id, d.data()),
    ];
  }

  Future<void> deleteInboxItem(String myUid, String stageId) {
    return _t(_db
        .collection('users')
        .doc(myUid)
        .collection('inbox')
        .doc(stageId)
        .delete());
  }

  /// 遊んだ結果を、ステージを作った人に送る。
  Future<void> submitResult({
    required String ownerUid,
    required String stageId,
    required String playerUid,
    required String playerName,
    required String playerAvatar,
    required int stars,
    required int blocks,
  }) {
    return _t(_db
        .collection('users')
        .doc(ownerUid)
        .collection('stageResults')
        .doc('${stageId}_$playerUid')
        .set({
      'stageId': stageId,
      'playerUid': playerUid,
      'playerName': playerName,
      'playerAvatar': playerAvatar,
      'stars': stars,
      'blocks': blocks,
      'at': DateTime.now().toIso8601String(),
    }));
  }

  /// 自分のステージ [stageId] を遊んだ友だちの結果。
  Future<List<StageResult>> fetchResults(String myUid, String stageId) async {
    final snap = await _t(_db
        .collection('users')
        .doc(myUid)
        .collection('stageResults')
        .where('stageId', isEqualTo: stageId)
        .get());
    final results = [
      for (final d in snap.docs) ?StageResult.tryParse(d.data()),
    ]..sort((a, b) {
        final byStars = b.stars.compareTo(a.stars);
        return byStars != 0 ? byStars : a.blocks.compareTo(b.blocks);
      });
    return results;
  }
}
