import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

// ─── Phase 4.1: CharacterProfile統合版 ────────────────────────────────────

/// プログラミングコレ！キャラクター管理（Phase 4.1: CharacterProfile対応）
class CharacterNotifier extends BaseCharacterProfileNotifier {
  @override
  List<BaseCharacter> get characterList => []; // プログラミングではキャラ使用なし

  @override
  String get storageKey => 'shogaku-kore-programming_character_profiles';

  @override
  Subject get appSubject => Subject.programming;
}

/// 統一キャラクタープロバイダー（Phase 4.1）
final characterProvider = NotifierProvider<CharacterNotifier, CharacterProfileMap>(
  CharacterNotifier.new,
);
