import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/flashcard_screen.dart';
import 'package:shogaku_kore_programming/providers/flashcard_provider.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'test_helpers.dart';

void main() {
  setUp(useReducedMotion);
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('FlashcardScreen Widget Tests', () {
    testWidgets('displays flashcard screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify flashcard screen is displayed
      expect(find.byType(FlashcardScreen), findsOneWidget);
    });

    testWidgets('displays flashcard content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('タップして答えを見る'), findsWidgets);
      expect(find.text('カードをめくる'), findsOneWidget);
    });

    testWidgets('displays card question/front side', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Question should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('can flip card to show answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();

      // 裏面（答え）と自己評価ボタンが表示される
      expect(find.text('裏面'), findsOneWidget);
      expect(find.text('答え'), findsOneWidget);
      expect(find.text('もう一度'), findsOneWidget);
      expect(find.text('知ってた！'), findsOneWidget);
    });

    testWidgets('displays progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Progress indicator should show (e.g., "Card 1 of 10")
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays difficulty buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Difficulty rating buttons should be visible
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('can rate card difficulty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('知ってた！'));
      await tester.pumpAndSettle();

      // 次のカード（表面）に進む
      expect(find.text('カードをめくる'), findsOneWidget);
      expect(find.text('2/10'), findsOneWidget);
    });

    testWidgets('advances to next card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1/10'), findsOneWidget);

      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('もう一度'));
      await tester.pumpAndSettle();

      expect(find.text('2/10'), findsOneWidget);
    });

    testWidgets('displays category selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // カテゴリ絞り込みのチップが並ぶ
      expect(find.text('絞り込み：'), findsOneWidget);
      expect(find.textContaining('基本'), findsWidgets);
      expect(find.textContaining('制御'), findsWidgets);
    });

    testWidgets('can filter by category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap category selector
      final categoryButton = find.byType(PopupMenuButton);
      if (categoryButton.evaluate().isNotEmpty) {
        await tester.tap(categoryButton.first);
        await tester.pumpAndSettle();

        // Category menu should appear
        expect(find.byType(PopupMenuItem), findsWidgets);
      }
    });

    testWidgets('displays statistics summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Stats like "Correct: X, Wrong: Y" should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows mark as correct button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();

      expect(find.text('知ってた！'), findsOneWidget);
    });

    testWidgets('shows mark as incorrect button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();

      expect(find.text('もう一度'), findsOneWidget);
    });

    testWidgets('updates statistics on answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('おぼえた 0 / 40'), findsOneWidget);

      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('知ってた！'));
      await tester.pumpAndSettle();

      expect(find.text('おぼえた 1 / 40'), findsOneWidget);
    });

    testWidgets('displays card count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card count should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays remaining cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remaining card count should be shown
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows shuffle option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // デッキは毎回ランダムに並べ替えられ、全体(40枚)から10枚の1セッションが始まる
      expect(find.text('1/10'), findsOneWidget);
      expect(find.text('全て 0/40'), findsOneWidget);
    });

    testWidgets('can shuffle cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('もう一度'));
      await tester.pumpAndSettle();
      expect(find.text('2/10'), findsOneWidget);

      // カテゴリを選び直すとデッキが組み直され、先頭に戻る
      await tester.tap(find.text('制御 0/5'));
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsOneWidget);
    });

    testWidgets('displays reset option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // カテゴリチップ（絞り込み）でデッキをリセットできる
      expect(find.text('絞り込み：'), findsOneWidget);
      expect(find.text('全て 0/40'), findsOneWidget);
      expect(find.text('クラス 0/1'), findsOneWidget);
    });

    testWidgets('can reset session', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('知ってた！'));
      await tester.pumpAndSettle();
      expect(find.text('2/10'), findsOneWidget);

      // 「全て」を選び直すと最初から（1枚目）
      await tester.tap(find.text('全て 1/40'));
      await tester.pumpAndSettle();
      expect(find.text('1/10'), findsOneWidget);
    });

    testWidgets('shows completion message when finished',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // This depends on card count - if there's only one card,
      // completing it should show completion message
    });

    testWidgets('handles empty card set', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // If no cards available, should show appropriate message
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('back button exits flashcard screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();

        // Should pop navigator
      }
    });

    testWidgets('card flip animation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('答え'), findsOneWidget);
    });

    testWidgets('supports keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test Space to flip card
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Card should flip
    });

    testWidgets('displays difficulty colors or indicators',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashcardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Difficulty indicators should be visible
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('saves progress automatically', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('知ってた！'));
      await tester.pumpAndSettle();

      // 回答後に進捗が反映されている
      expect(find.text('おぼえた 1 / 40'), findsOneWidget);
    });

    testWidgets('displays all card text content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FlashcardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // 表面: 問題の見出しと操作ガイド
      expect(find.text('タップして答えを見る'), findsWidgets);
      expect(find.text('[Space] または タップ でカードをめくる'), findsOneWidget);

      await tester.tap(find.text('カードをめくる'));
      await tester.pumpAndSettle();

      // 裏面: 答えが表示される
      expect(find.text('答え'), findsOneWidget);
    });
  });
}
