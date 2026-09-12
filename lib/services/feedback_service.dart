import 'dart:convert';

import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// バグ報告・改善要望（[FeedbackNotifier]）の実際の送信処理。
///
/// このアプリは Firestore を導入しておらず、データ永続化はほぼ全て
/// SharedPreferences で完結する構成（認証のみ Firebase Auth の匿名認証）。
/// 実際にサーバーへ送信する手段を持たないため、`FeedbackFormPage` から送信された
/// 報告は SharedPreferences 上のローカルキュー（`pending_feedback_reports`）に
/// 蓄積し続けるだけの簡易実装とする。
///
/// 注意: [FeedbackNotifier] 自体にも「ハンドラ未登録時・送信失敗時にローカル退避
/// する」オフラインキュー（`feedback_pending_queue`キー）が既に組み込まれている。
/// このハンドラは例外を投げない（＝常に成功扱いになる）ため、そちらの二重の
/// キュー機構は使われない。ここでは別キー・別実装として意図的に分離している。
class FeedbackService {
  static const _queueKey = 'pending_feedback_reports';

  /// [FeedbackNotifier.setSubmitHandler] に登録するハンドラ本体。
  Future<void> submit(FeedbackReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? <String>[];
    queue.add(jsonEncode(report.toJson()));
    await prefs.setStringList(_queueKey, queue);
  }
}
