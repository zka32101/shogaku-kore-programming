import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ranking_entry.dart';
import 'profile_provider.dart';

/// ランキング表示用の名前（プライバシー対応）
class RankingDisplayName {
  final String displayName;  // 表示される名前
  final bool isPublic;       // 名前が公開されているか
  final String? anonymousId; // 公開されていない場合の匿名 ID

  const RankingDisplayName({
    required this.displayName,
    required this.isPublic,
    this.anonymousId,
  });
}

/// ランキングエントリの プライバシー対応ラッパー
class PrivacyAwareRankEntry {
  final int rank;
  final RankingDisplayName displayName;
  final int points;
  final String icon;
  final bool isMe;
  final bool userMadeNamePublic; // そのユーザーが名前公表を許可しているか

  const PrivacyAwareRankEntry({
    required this.rank,
    required this.displayName,
    required this.points,
    required this.icon,
    this.isMe = false,
    this.userMadeNamePublic = false,
  });
}

/// ランキング表示用プロバイダ
/// 入力: 元のランキング、現在のユーザー情報
/// 出力: プライバシー対応済みのランキング
final rankingPrivacyProvider =
    FutureProvider.family<List<PrivacyAwareRankEntry>, List<RankEntry>>(
  (ref, rankEntries) async {
    final profile = ref.watch(profileProvider);

    return rankEntries.map((entry) {
      // 自分のエントリの場合は常に名前を表示
      if (entry.isMe) {
        return PrivacyAwareRankEntry(
          rank: entry.rank,
          displayName: RankingDisplayName(
            displayName: entry.name,
            isPublic: true,
          ),
          points: entry.points,
          icon: entry.icon,
          isMe: true,
          userMadeNamePublic: profile.rankingNamePublic,
        );
      }

      // 他のユーザーの場合は、名前が公開されている場合のみ表示
      // 実際のアプリでは、各ランキングエントリに
      // namePublic フラグがあるべき
      // ここではダミーとして、常に非公開と仮定
      return PrivacyAwareRankEntry(
        rank: entry.rank,
        displayName: RankingDisplayName(
          displayName: 'ユーザー #${entry.rank}',
          isPublic: false,
          anonymousId: 'USER_${entry.rank}',
        ),
        points: entry.points,
        icon: entry.icon,
        isMe: false,
        userMadeNamePublic: false,
      );
    }).toList();
  },
);

/// ランキング表示時に、自分が名前を公開しているかを確認するプロバイダ
final myRankingVisibilityProvider = FutureProvider<bool>((ref) async {
  final profile = ref.watch(profileProvider);
  return profile.rankingNamePublic;
});

/// 現在のユーザーの匿名 ID を取得
final myAnonymousIdProvider = FutureProvider<String>((ref) async {
  final profile = ref.watch(profileProvider);
  return profile.anonymousId;
});
