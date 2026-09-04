/// ランキングエントリ（基本）
class RankEntry {
  final int rank;
  final String name;
  final int points;
  final String icon;
  final bool isMe;
  final bool namePublic; // このユーザーが名前公開を許可しているか

  const RankEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.icon,
    this.isMe = false,
    this.namePublic = false, // デフォルトは非公開
  });

  /// 表示用の名前を取得
  /// namePublic が true の場合、実名を返す
  /// false の場合、匿名 ID を返す
  String getDisplayName({String? anonymousId}) {
    if (namePublic || isMe) {
      return name;
    }
    return anonymousId ?? 'ユーザー #$rank';
  }

  @override
  String toString() => 'RankEntry(rank: $rank, name: $name, points: $points, isMe: $isMe, namePublic: $namePublic)';
}
