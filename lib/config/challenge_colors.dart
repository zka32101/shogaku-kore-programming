import 'package:flutter/material.dart';

/// ランキング「今週のチャレンジ」項目の配色(WCAG AA 4.5:1 以上を保つ)。
class ChallengeItemColors {
  final Color background;
  final Color title;
  final Color desc;
  const ChallengeItemColors(this.background, this.title, this.desc);

  static ChallengeItemColors of({required bool dark, required bool done}) {
    if (dark) {
      return done
          ? const ChallengeItemColors(
              Color(0xFF1F3A34), Color(0xFFE8E8E8), Color(0xFFC8D0CE))
          : const ChallengeItemColors(
              Color(0xFF2A2A2A), Color(0xFFE8E8E8), Color(0xFFBDBDBD));
    }
    return done
        ? const ChallengeItemColors(
            Color(0xFFE3F6F1), Color(0xFF333333), Color(0xFF4A5560))
        : const ChallengeItemColors(
            Color(0xFFF3F4F6), Color(0xFF333333), Color(0xFF5F6368));
  }
}
