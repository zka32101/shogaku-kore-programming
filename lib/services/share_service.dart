import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../models/certificate.dart';

class ShareService {
  static const String _certificateSubject = '小学コレ！プログラミング 修了証';
  static const String _appNameSubject = '小学コレ！プログラミング';
  /// Twitter で共有
  static Future<void> shareToTwitter(Certificate certificate) async {
    final message = _buildTwitterMessage(certificate);
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: _certificateSubject,
      ),
    );
  }

  /// Instagram で共有（テキストのみ — Instagram はダイレクトシェア非対応）
  static Future<void> shareToInstagram(Certificate certificate) async {
    final message = _buildInstagramMessage(certificate);
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: _appNameSubject,
      ),
    );
  }

  /// 汎用シェア（システムシェアシート）
  static Future<void> shareGeneric(
    Certificate certificate, {
    String? filePath,
  }) async {
    final message = _buildGenericMessage(certificate);
    final files = (filePath != null && File(filePath).existsSync())
        ? [XFile(filePath, mimeType: 'application/pdf')]
        : <XFile>[];

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: _certificateSubject,
        files: files.isEmpty ? null : files,
      ),
    );
  }

  /// ファイル＋テキストでシェア
  static Future<void> shareWithFile(
    Certificate certificate,
    String filePath,
  ) async {
    if (!File(filePath).existsSync()) {
      throw Exception('Certificate file not found: $filePath');
    }

    final message = _buildGenericMessage(certificate);
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: _certificateSubject,
        files: [XFile(filePath, mimeType: 'application/pdf')],
      ),
    );
  }

  /// Twitter メッセージ生成
  static String _buildTwitterMessage(Certificate certificate) {
    final stars = '★' * certificate.stars;
    return '''🎉 小学コレ！プログラミング ステージ${certificate.stageNumber}をクリア！

📌 ${certificate.stageName}
⭐ $stars
🎓 修了者: ${certificate.childName}

プログラミングの力が身についたよ！
#小学コレ #プログラミング教育 #子ども向けプログラミング
''';
  }

  /// Instagram メッセージ生成
  static String _buildInstagramMessage(Certificate certificate) {
    final stars = '★' * certificate.stars;
    return '''🎉 小学コレ！プログラミング ステージ${certificate.stageNumber}をクリア！

📌 ${certificate.stageName}
⭐ $stars
🎓 修了者: ${certificate.childName}

プログラミングの力が身についたよ！
#小学コレ #プログラミング教育 #子ども向けプログラミング #Python #教育アプリ
''';
  }

  /// 汎用メッセージ生成
  static String _buildGenericMessage(Certificate certificate) {
    final stars = '★' * certificate.stars;
    return '''🎉 小学コレ！プログラミング ステージ${certificate.stageNumber}をクリア！

📌 ステージ: ${certificate.stageName}
⭐ 星数: $stars
🎓 修了者: ${certificate.childName}
📅 修了日: ${certificate.completedAt.year}年${certificate.completedAt.month}月${certificate.completedAt.day}日

プログラミングの力が身についたよ！
Petit Works Education - 小学コレシリーズ
''';
  }
}
