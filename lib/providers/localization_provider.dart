import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

enum AppLanguage {
  japanese('ja'),
  english('en'),
  chinese('zh');

  final String code;
  const AppLanguage(this.code);
}

class LocalizationStrings {
  final Map<String, String> _strings;

  LocalizationStrings(this._strings);

  String get(String key, {String? defaultValue}) {
    return _strings[key] ?? defaultValue ?? key;
  }

  String translate(String key) => get(key);
}

// ─── 言語別翻訳辞書 ──────────────────────────────────────────────────────

final _japaneseStrings = {
  // アプリ全体
  'app_title': '小学こーでプログラミング',
  'app_subtitle': 'ブロックでプログラミング学習',

  // ステップ実行
  'step_execution': 'ステップ実行',
  'step_forward': 'ステップ',
  'step_backward': '戻す',
  'step_reset': 'リセット',
  'step_ready': 'ステップ準備',
  'execution_speed': '実行速度',
  'speed_slow': '🐢 遅い',
  'speed_normal_slow': '🚶 普通遅',
  'speed_normal': '⚡ 普通',
  'speed_normal_fast': '🏃 普通速',
  'speed_fast': '🚀 速い',

  // 変数
  'variable_label': '変数',
  'no_variables': '変数はまだ使用されていません',

  // ブレークポイント
  'breakpoint_set': 'ブレークポイント設定',
  'breakpoint_remove': 'ブレークポイント削除',

  // 採点
  'scoring_title': '採点結果',
  'success': '✅ 成功！目標に到達しました！',
  'failure_position': '❌ 位置がずれています',
  'failure_angle': '❌ 角度が異なります',
  'failure_both': '❌ 位置と角度が異なります',
  'position': '位置',
  'current': '現在',
  'goal': '目標',
  'angle': '角度',
  'tolerance': '許容誤差',
  'congrats': '🎉 チャレンジ達成！おめでとうございます！',

  // 実行履歴
  'execution_history': '⏱️ 実行履歴',

  // チャレンジ
  'challenge_title': 'チャレンジ',
  'challenge_description': '説明',
  'challenge_hints': 'ヒント',
  'stage': 'ステージ',

  // ボタン
  'run': '実行',
  'submit': '回答する',
  'delete': '削除',
  'cancel': 'キャンセル',
};

final _englishStrings = {
  // App-wide
  'app_title': 'Shogaku Code Programming',
  'app_subtitle': 'Learn Programming with Blocks',

  // Step Execution
  'step_execution': 'Step Execution',
  'step_forward': 'Step',
  'step_backward': 'Back',
  'step_reset': 'Reset',
  'step_ready': 'Prepare Step',
  'execution_speed': 'Execution Speed',
  'speed_slow': '🐢 Slow',
  'speed_normal_slow': '🚶 Slower',
  'speed_normal': '⚡ Normal',
  'speed_normal_fast': '🏃 Faster',
  'speed_fast': '🚀 Fast',

  // Variables
  'variable_label': 'Variables',
  'no_variables': 'No variables used yet',

  // Breakpoints
  'breakpoint_set': 'Set Breakpoint',
  'breakpoint_remove': 'Remove Breakpoint',

  // Scoring
  'scoring_title': 'Scoring Result',
  'success': '✅ Success! You reached the goal!',
  'failure_position': '❌ Position is incorrect',
  'failure_angle': '❌ Angle is incorrect',
  'failure_both': '❌ Position and angle are incorrect',
  'position': 'Position',
  'current': 'Current',
  'goal': 'Goal',
  'angle': 'Angle',
  'tolerance': 'Tolerance',
  'congrats': '🎉 Challenge Complete! Congratulations!',

  // Execution History
  'execution_history': '⏱️ Execution History',

  // Challenges
  'challenge_title': 'Challenge',
  'challenge_description': 'Description',
  'challenge_hints': 'Hints',
  'stage': 'Stage',

  // Buttons
  'run': 'Run',
  'submit': 'Submit',
  'delete': 'Delete',
  'cancel': 'Cancel',
};

final _chineseStrings = {
  // 应用全局
  'app_title': '小学编程',
  'app_subtitle': '使用积木学习编程',

  // 步骤执行
  'step_execution': '分步执行',
  'step_forward': '前进',
  'step_backward': '后退',
  'step_reset': '重置',
  'step_ready': '准备步骤',
  'execution_speed': '执行速度',
  'speed_slow': '🐢 慢',
  'speed_normal_slow': '🚶 较慢',
  'speed_normal': '⚡ 正常',
  'speed_normal_fast': '🏃 较快',
  'speed_fast': '🚀 快',

  // 变量
  'variable_label': '变量',
  'no_variables': '尚未使用变量',

  // 断点
  'breakpoint_set': '设置断点',
  'breakpoint_remove': '删除断点',

  // 评分
  'scoring_title': '评分结果',
  'success': '✅ 成功！您到达了目标！',
  'failure_position': '❌ 位置不正确',
  'failure_angle': '❌ 角度不正确',
  'failure_both': '❌ 位置和角度都不正确',
  'position': '位置',
  'current': '当前',
  'goal': '目标',
  'angle': '角度',
  'tolerance': '容差',
  'congrats': '🎉 挑战完成！恭喜！',

  // 执行历史
  'execution_history': '⏱️ 执行历史',

  // 挑战
  'challenge_title': '挑战',
  'challenge_description': '描述',
  'challenge_hints': '提示',
  'stage': '阶段',

  // 按钮
  'run': '运行',
  'submit': '提交',
  'delete': '删除',
  'cancel': '取消',
};

// ─── 言語プロバイダー ──────────────────────────────────────────────────────

final appLanguageProvider = StateProvider<AppLanguage>((ref) {
  return AppLanguage.japanese; // デフォルト: 日本語
});

final localizationProvider = Provider<LocalizationStrings>((ref) {
  final lang = ref.watch(appLanguageProvider);

  final strings = switch (lang) {
    AppLanguage.japanese => _japaneseStrings,
    AppLanguage.english => _englishStrings,
    AppLanguage.chinese => _chineseStrings,
  };

  return LocalizationStrings(strings);
});

// ─── 便利な拡張 ───────────────────────────────────────────────────────────

extension LocalizationX on String {
  /// 翻訳キーから翻訳文字列を取得する
  /// 使用例: 'app_title'.tr(ref)
  String tr(WidgetRef ref) {
    return ref.read(localizationProvider).get(this);
  }
}
