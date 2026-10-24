import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart' show AvatarUnlockType;
import 'package:shogaku_kore_programming/widgets/avatar_picker_grid.dart';
import 'package:shogaku_kore_programming/widgets/profile_avatar.dart';

void main() {
  test('16 avatars: first 4 free, the other 12 need coins', () {
    expect(kAvailableAvatars.length, 16);
    final free = kAvailableAvatars.where((a) => a.unlockType == AvatarUnlockType.free);
    expect(free.length, 4);
    for (final a in kAvailableAvatars.where((a) => a.unlockType != AvatarUnlockType.free)) {
      expect(avatarCoinCost(a), isNotNull);
      expect(avatarCoinCost(a)!, greaterThan(0));
    }
    for (final a in free) {
      expect(avatarCoinCost(a), isNull);
    }
  });

  test('saved emoji resolves to an illustrated avatar', () {
    final a = kAvailableAvatars.first;
    expect(ProfileAvatar.byEmoji(a.emoji)?.id, a.id);
    expect(ProfileAvatar.byEmoji('🧑‍💻'), isNull);
  });
}
