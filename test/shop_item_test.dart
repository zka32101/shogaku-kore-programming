import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/models/shop_item.dart';

void main() {
  group('kShopItems データ整合性', () {
    test('アイテム総数は11個', () {
      expect(kShopItems.length, 11);
    });

    test('全アイテムのIDが一意', () {
      final ids = kShopItems.map((i) => i.id).toList();
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, ids.length);
    });

    test('全アイテムの価格は50以上', () {
      for (final item in kShopItems) {
        expect(item.price, greaterThanOrEqualTo(50),
            reason: '${item.name} の価格が50未満');
      }
    });

    test('消耗品はhintカテゴリのみ', () {
      for (final item in kShopItems) {
        if (item.isConsumable) {
          expect(item.category, ShopCategory.hint,
              reason: '${item.name} は消耗品だがhintカテゴリでない');
        }
      }
    });

    test('hintカテゴリの消耗品数は2個', () {
      final hints = kShopItems.where((i) => i.category == ShopCategory.hint).toList();
      expect(hints.length, 2);
    });

    test('characterカテゴリのアイテム数は4個', () {
      final chars = kShopItems.where((i) => i.category == ShopCategory.character).toList();
      expect(chars.length, 4);
    });

    test('全アイテムのemoji・name・descriptionが空でない', () {
      for (final item in kShopItems) {
        expect(item.emoji, isNotEmpty, reason: '${item.id} のemojiが空');
        expect(item.name, isNotEmpty, reason: '${item.id} のnameが空');
        expect(item.description, isNotEmpty, reason: '${item.id} のdescriptionが空');
      }
    });
  });

  group('ShopCategoryLabel', () {
    test('各カテゴリのlabelが正しい', () {
      expect(ShopCategory.character.label, '🥷 キャラ');
      expect(ShopCategory.background.label, '🖼️ 背景');
      expect(ShopCategory.sound.label, '🎵 サウンド');
      expect(ShopCategory.hint.label, '💡 ヒント');
    });
  });
}
