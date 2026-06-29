import 'package:flutter/services.dart';

/// 振動フィードバックの有効/無効を一元管理するサービス
///
/// 使い方:
///   HapticService.lightImpact();   // 軽いタップ
///   HapticService.mediumImpact();  // 中程度のタップ
///   HapticService.heavyImpact();   // 強いフィードバック
///   HapticService.selectionClick(); // 選択音
class HapticService {
  HapticService._();

  static bool _enabled = true;

  static bool get enabled => _enabled;

  static void setEnabled(bool value) {
    _enabled = value;
  }

  static void lightImpact() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    if (_enabled) HapticFeedback.selectionClick();
  }
}
