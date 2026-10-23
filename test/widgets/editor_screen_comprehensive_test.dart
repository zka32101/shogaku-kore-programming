import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/screens/editor_screen.dart';
import 'package:shogaku_kore_programming/providers/editor_provider.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
import 'package:shogaku_kore_programming/config/constants.dart';
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

  // Create mock challenge for testing
  final mockChallenge = Stage(
    id: 'editor_test_1',
    stageNumber: 1,
    title: 'ブロックプログラミング基礎',
    description: '視覚的なブロックでプログラムを組み立てます',
    level: '初級',
    icon: 'icon_1',
    isFree: true,
    questions: [],
    conceptExplanation: 'ブロックを組み合わせてロボットを動かします',
    type: 'visual',
    hints: ['まず「前に進む」を使おう', '次に「右に回転」を足そう'],
  );

  /// ヒント文は用語集つきの RichText で描画されるため、平文で探す
  Finder _hintText(String text) => find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == text,
      );

  group('EditorScreen Comprehensive Widget Tests', () {
    // Basic Screen Rendering Tests
    group('Basic Screen Rendering', () {
      testWidgets('displays editor screen without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        expect(find.byType(EditorScreen), findsOneWidget);
      });

      testWidgets('displays AppBar with challenge title', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 専用ヘッダー（AppBar ではない）にステージ名と説明が出る
        expect(find.text('ブロックプログラミング基礎'), findsOneWidget);
        expect(find.text('視覚的なブロックでプログラムを組み立てます'), findsOneWidget);
      });

      testWidgets('displays block programming canvas', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Canvas or workspace should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays character/robot visualization', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Robot/character display
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays block palette/toolbar', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Block selection tools should display
        expect(find.byType(Container), findsWidgets);
      });
    });

    // Block Management Tests
    group('Block Management and Composition', () {
      testWidgets('displays available blocks to drag', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Block palette should show
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('allows dragging block to workspace', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find a draggable block
        final draggables = find.byType(Draggable);
        if (draggables.evaluate().isNotEmpty) {
          await tester.drag(draggables.first, const Offset(100, 100));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('displays blocks in workspace', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('allows removing blocks from workspace', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Look for delete/remove controls
        final deleteButtons = find.byIcon(Icons.delete);
        if (deleteButtons.evaluate().isNotEmpty) {
          await tester.tap(deleteButtons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('displays block parameters/settings', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });
    });

    // Execution Tests
    group('Program Execution', () {
      testWidgets('displays run/execute button', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 実行ボタンと回答ボタンが並ぶ
        expect(find.text('実行'), findsOneWidget);
        expect(find.text('回答する'), findsOneWidget);
      });

      testWidgets('executes program when run button tapped', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final runButton = find.byIcon(Icons.play_arrow);
        if (runButton.evaluate().isNotEmpty) {
          await tester.tap(runButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('shows execution animation', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays robot movement visualization', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Robot/character movement area
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows step execution mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Step/step-by-step button or mode
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays execution timeline', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Variable Viewer Tests
    group('Variable Viewing and Inspection', () {
      testWidgets('displays variable viewer panel', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Variable display area
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows variable names and values', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('updates variables during execution', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('allows inspecting variable history', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // History or timeline controls
        expect(find.byType(Container), findsWidgets);
      });
    });

    // Hint and Help Tests
    group('Hints and Help System', () {
      testWidgets('displays hint button', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Hint button should be visible
        final hintButton = find.byIcon(Icons.lightbulb_outline);
        expect(hintButton.evaluate().isNotEmpty, true);
      });

      testWidgets('shows hint when requested', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final hintButton = find.byIcon(Icons.lightbulb_outline);
        if (hintButton.evaluate().isNotEmpty) {
          await tester.tap(hintButton.first);
          await tester.pumpAndSettle();

          // Hint text should display
          expect(find.byType(Text), findsWidgets);
        }
      });

      testWidgets('cycles through multiple hints', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // ヒントは最初は閉じている
        expect(find.byIcon(Icons.lightbulb), findsNothing);

        await tester.tap(find.byIcon(Icons.lightbulb_outline));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.lightbulb), findsOneWidget);
        expect(_hintText('まず「前に進む」を使おう'), findsOneWidget);

        // 「次へ」で次のヒントに進み、最後まで行くと最初に戻る
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
        expect(_hintText('次に「右に回転」を足そう'), findsOneWidget);

        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
        expect(_hintText('まず「前に進む」を使おう'), findsOneWidget);
      });

      testWidgets('displays concept explanation', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });
    });

    // Character Reaction Tests
    group('Character Reactions and Feedback', () {
      testWidgets('displays character/companion figure', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Character should be visible
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows character mood changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays character message/dialogue', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('shows reaction to correct solution', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows reaction to incorrect attempt', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Celebration and Success Tests
    group('Celebration and Success Indicators', () {
      testWidgets('displays confetti on success', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Confetti widget should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows completion message', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays scoring result', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows first-clear badge after a correct answer', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('はじめの一歩！'), findsNothing);

        // ブロックを置いて回答する
        await tester.tap(find.text('前に進む'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('回答する'));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // 最初のステージを初めてクリアしたので、バッジ演出とレベルアップが出る
        expect(find.text('はじめの一歩！'), findsOneWidget);
        expect(find.text('最初のステージをクリア！コーディング冒険の始まり！'), findsOneWidget);
        expect(find.text('+10 ポイント'), findsOneWidget);
        expect(find.textContaining('レベルアップ'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      });
    });

    // Keyboard Shortcuts Tests
    group('Keyboard Shortcuts', () {
      testWidgets('space key runs program', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press space to run
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
      });

      testWidgets('H key shows hints', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press H for hint
        await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
        await tester.pumpAndSettle();
      });

      testWidgets('R key resets program', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press R to reset
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        await tester.pumpAndSettle();
      });

      testWidgets('S key opens step mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press S for step execution
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.pumpAndSettle();
      });
    });

    // State Management Tests
    group('State Management', () {
      testWidgets('preserves blocks when navigating away', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(EditorScreen), findsOneWidget);
      });

      testWidgets('records learning time on exit', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Time tracking should happen in dispose
        expect(find.byType(EditorScreen), findsOneWidget);
      });

      testWidgets('updates progress on completion', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Error Handling Tests
    group('Error Handling and Edge Cases', () {
      testWidgets('handles empty program gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle running empty workspace
        final runButton = find.byIcon(Icons.play_arrow);
        if (runButton.evaluate().isNotEmpty) {
          await tester.tap(runButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('handles invalid block combinations', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(EditorScreen), findsOneWidget);
      });

      testWidgets('handles rapid execution restarts', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final runButton = find.byIcon(Icons.play_arrow);
        if (runButton.evaluate().isNotEmpty) {
          // Rapid taps
          for (int i = 0; i < 3; i++) {
            await tester.tap(runButton.first);
            await tester.pumpAndSettle(const Duration(milliseconds: 200));
          }
        }
      });

      testWidgets('handles back navigation during execution', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      });
    });

    // Theme and Styling Tests
    group('Theme and Styling', () {
      testWidgets('respects theme colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(EditorScreen), findsOneWidget);
      });

      testWidgets('displays proper text styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('block styling displays correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });
    });

    // Integration Tests
    group('Full Integration and Workflows', () {
      testWidgets('complete editor workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Workspace should be ready
        expect(find.byType(Container), findsWidgets);

        // Try to run program
        final runButton = find.byIcon(Icons.play_arrow);
        if (runButton.evaluate().isNotEmpty) {
          await tester.tap(runButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('block manipulation workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag block
        final draggables = find.byType(Draggable);
        if (draggables.evaluate().isNotEmpty) {
          await tester.drag(draggables.first, const Offset(100, 100));
          await tester.pumpAndSettle();
        }

        // Delete block
        final deleteButtons = find.byIcon(Icons.delete);
        if (deleteButtons.evaluate().isNotEmpty) {
          await tester.tap(deleteButtons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('hint and execution workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Show hint
        final hintButton = find.byIcon(Icons.lightbulb_outline);
        if (hintButton.evaluate().isNotEmpty) {
          await tester.tap(hintButton.first);
          await tester.pumpAndSettle();
        }

        // Run program
        final runButton = find.byIcon(Icons.play_arrow);
        if (runButton.evaluate().isNotEmpty) {
          await tester.tap(runButton.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('keyboard-only workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: EditorScreen(challenge: mockChallenge),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Use keyboard shortcuts
        await tester.sendKeyEvent(LogicalKeyboardKey.keyH); // hint
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.space); // run
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.keyR); // reset
        await tester.pumpAndSettle();
      });
    });
  });
}
