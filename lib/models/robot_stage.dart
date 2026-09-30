/// ロボットゲームの1ステージ（内蔵ステージも、友だちと共有するステージも同じ形）。
///
/// [rows] は 5×5 の盤面。S=スタート G=ゴール #=かべ C=コイン .=空き
class RobotStage {
  static const int gridSize = 5;
  static const int maxBlocks = 24;

  final String id;
  final String title;
  final String hint;
  final List<String> rows;

  /// 3つ星になるブロック数。自作ステージは「作った人が自分でクリアしたブロック数」。
  final int par;

  const RobotStage({
    required this.id,
    required this.title,
    required this.rows,
    required this.par,
    this.hint = '',
  });

  /// ブロック [blocks] 個でクリアしたときの星の数（1〜3）。
  int starsFor(int blocks) {
    if (blocks <= par) return 3;
    if (blocks <= par * 2) return 2;
    return 1;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'rows': rows,
        'par': par,
      };

  /// 形式が正しくない場合は null（他人から届いたデータを信用しないため厳密に検証する）。
  static RobotStage? tryParse(Map<String, dynamic> data, {String? fallbackId}) {
    try {
      final id = (data['id'] as String?) ?? fallbackId;
      final title = data['title'] as String?;
      final rowsRaw = data['rows'];
      final par = data['par'];
      if (id == null || title == null || rowsRaw is! List || par is! int) {
        return null;
      }
      final rows = rowsRaw.cast<String>();
      if (validate(rows) != null) return null;
      if (par < 1 || par > maxBlocks) return null;
      return RobotStage(
        id: id,
        title: title.length > 20 ? title.substring(0, 20) : title,
        rows: rows,
        par: par,
      );
    } catch (_) {
      return null;
    }
  }

  /// 盤面の検証。問題がなければ null、あれば理由（子ども向けの言葉）を返す。
  static String? validate(List<String> rows) {
    if (rows.length != gridSize) return '盤面の大きさがちがうよ';
    var starts = 0;
    var goals = 0;
    var coins = 0;
    var walls = 0;
    for (final r in rows) {
      if (r.length != gridSize) return '盤面の大きさがちがうよ';
      for (final ch in r.split('')) {
        switch (ch) {
          case 'S':
            starts++;
          case 'G':
            goals++;
          case 'C':
            coins++;
          case '#':
            walls++;
          case '.':
            break;
          default:
            return '知らない マークがあるよ';
        }
      }
    }
    if (starts != 1) return '🤖スタートを 1 つ おいてね';
    if (goals != 1) return '🚩ゴールを 1 つ おいてね';
    if (coins > 5) return '🪙は 5 こまでだよ';
    if (walls > 12) return '🧱は 12 こまでだよ';
    if (!_reachable(rows)) return 'ゴールや🪙まで 道がつながっていないよ';
    return null;
  }

  /// スタートから、かべを通らずにゴールとすべてのコインへ行けるか。
  static bool _reachable(List<String> rows) {
    int sx = 0, sy = 0;
    for (var y = 0; y < gridSize; y++) {
      final x = rows[y].indexOf('S');
      if (x >= 0) {
        sx = x;
        sy = y;
      }
    }
    final seen = <int>{sy * gridSize + sx};
    final queue = <int>[sy * gridSize + sx];
    while (queue.isNotEmpty) {
      final cur = queue.removeLast();
      final cx = cur % gridSize;
      final cy = cur ~/ gridSize;
      for (final d in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = cx + d.$1;
        final ny = cy + d.$2;
        if (nx < 0 || ny < 0 || nx >= gridSize || ny >= gridSize) continue;
        if (rows[ny][nx] == '#') continue;
        if (seen.add(ny * gridSize + nx)) queue.add(ny * gridSize + nx);
      }
    }
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final ch = rows[y][x];
        if ((ch == 'G' || ch == 'C') && !seen.contains(y * gridSize + x)) {
          return false;
        }
      }
    }
    return true;
  }
}

/// 友だちから届いたステージ。
class SharedStage {
  final RobotStage stage;
  final String fromUid;
  final String fromName;
  final String fromAvatar;
  final DateTime createdAt;

  const SharedStage({
    required this.stage,
    required this.fromUid,
    required this.fromName,
    required this.fromAvatar,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        ...stage.toMap(),
        'fromUid': fromUid,
        'fromName': fromName,
        'fromAvatar': fromAvatar,
        'createdAt': createdAt.toIso8601String(),
      };

  static SharedStage? tryParse(String docId, Map<String, dynamic> data) {
    final stage = RobotStage.tryParse(data, fallbackId: docId);
    final fromUid = data['fromUid'];
    if (stage == null || fromUid is! String) return null;
    return SharedStage(
      stage: stage,
      fromUid: fromUid,
      fromName: (data['fromName'] as String?) ?? 'ともだち',
      fromAvatar: (data['fromAvatar'] as String?) ?? '🧑‍💻',
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// 友だちがあなたのステージを遊んだ結果。
class StageResult {
  final String stageId;
  final String playerUid;
  final String playerName;
  final String playerAvatar;
  final int stars;
  final int blocks;
  final DateTime at;

  const StageResult({
    required this.stageId,
    required this.playerUid,
    required this.playerName,
    required this.playerAvatar,
    required this.stars,
    required this.blocks,
    required this.at,
  });

  static StageResult? tryParse(Map<String, dynamic> data) {
    final stageId = data['stageId'];
    final playerUid = data['playerUid'];
    final stars = data['stars'];
    final blocks = data['blocks'];
    if (stageId is! String ||
        playerUid is! String ||
        stars is! int ||
        blocks is! int) {
      return null;
    }
    return StageResult(
      stageId: stageId,
      playerUid: playerUid,
      playerName: (data['playerName'] as String?) ?? 'ともだち',
      playerAvatar: (data['playerAvatar'] as String?) ?? '🧑‍💻',
      stars: stars.clamp(1, 3),
      blocks: blocks,
      at: DateTime.tryParse(data['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
