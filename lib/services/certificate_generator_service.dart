import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/certificate.dart';

class CertificateGeneratorService {
  static const String _fontAssetPath = 'assets/fonts/'; // 日本語フォント（後で追加）

  /// レベル別に認定証を生成
  static Future<Uint8List> generateCertificateImage(
    Certificate certificate,
  ) async {
    final pdf = pw.Document();

    final background = await _loadBackgroundImage(certificate.level);
    final template = _getCertificateTemplate(certificate, background);
    pdf.addPage(template);

    return await pdf.save();
  }

  /// レベル別の認定証背景画像を読み込む
  static Future<pw.MemoryImage?> _loadBackgroundImage(String level) async {
    final assetPath = switch (level) {
      '初級' => 'assets/certificates/cert_beginner.png',
      '中級' => 'assets/certificates/cert_intermediate.png',
      '上級' => 'assets/certificates/cert_advanced.png',
      _ => null,
    };
    if (assetPath == null) return null;
    try {
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      return null;
    }
  }

  /// 認定証テンプレート（レベル別）
  static pw.Page _getCertificateTemplate(
    Certificate certificate,
    pw.MemoryImage? background,
  ) {
    final (backgroundColor, accentColor, titleColor) =
        _getLevelColors(certificate.level);

    return pw.Page(
      pageFormat: PdfPageFormat(
        PdfPageFormat.a4.width * 0.8, // 縦向き、A4の80%
        PdfPageFormat.a4.height * 0.8,
      ),
      build: (pw.Context context) {
        final content = pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: accentColor, width: 3),
            color: background == null ? backgroundColor : null,
          ),
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ヘッダー
              pw.Text(
                '修了証',
                style: pw.TextStyle(
                  fontSize: 48,
                  fontWeight: pw.FontWeight.bold,
                  color: titleColor,
                ),
              ),

              // タイトル
              pw.Text(
                '小学コレ！プログラミング',
                style: const pw.TextStyle(
                  fontSize: 24,
                  color: PdfColors.black,
                ),
              ),

              // ステージ情報
              pw.Column(
                children: [
                  pw.Text(
                    'ステージ${certificate.stageNumber}',
                    style: const pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    certificate.stageName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),

              // 子ども名前
              pw.Column(
                children: [
                  pw.Text(
                    '認定者',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    certificate.childName,
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ],
              ),

              // 星表示
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < certificate.stars; i++)
                    pw.Text(
                      '★',
                      style: pw.TextStyle(
                        fontSize: 36,
                        color: accentColor,
                      ),
                    ),
                ],
              ),

              // レベル表示
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: pw.Text(
                  certificate.level,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              // 完了日
              pw.Text(
                '${certificate.completedAt.year}年${certificate.completedAt.month}月${certificate.completedAt.day}日 修了',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),

              // フッター
              pw.Text(
                'Petit Works Education',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        );

        if (background == null) return content;

        return pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Image(background, fit: pw.BoxFit.cover),
            ),
            content,
          ],
        );
      },
    );
  }

  /// レベル別カラースキーム
  static (PdfColor, PdfColor, PdfColor) _getLevelColors(String level) {
    switch (level) {
      case '初級':
        return (
          PdfColors.lightBlue50, // 背景: 薄い青
          const PdfColor.fromInt(0xFF2196F3), // アクセント: 青
          const PdfColor.fromInt(0xFF0D47A1), // タイトル: 濃い青
        );
      case '中級':
        return (
          const PdfColor.fromInt(0xFFF3E5F5), // 背景: 薄い紫
          const PdfColor.fromInt(0xFF9C27B0), // アクセント: 紫
          const PdfColor.fromInt(0xFF4A148C), // タイトル: 濃い紫
        );
      case '上級':
        return (
          const PdfColor.fromInt(0xFFFFE0B2), // 背景: 薄いオレンジ
          const PdfColor.fromInt(0xFFFFA500), // アクセント: オレンジ
          const PdfColor.fromInt(0xFFE65100), // タイトル: 濃いオレンジ
        );
      default:
        return (
          PdfColors.grey50,
          PdfColors.grey400,
          PdfColors.black,
        );
    }
  }

  /// 認定証画像をデバイスに保存
  static Future<String> saveCertificateToDevice(
    Uint8List pdfBytes,
    String certificateId,
  ) async {
    final directory = await getApplicationCacheDirectory();
    final fileName = 'certificate_$certificateId.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// デバイスから認定証を読み込み
  static Future<Uint8List?> loadCertificateFromDevice(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print('Error loading certificate: $e');
    }
    return null;
  }

  /// デバイスから認定証を削除
  static Future<void> deleteCertificateFromDevice(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting certificate: $e');
    }
  }
}
