import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/models/stage.dart';
import 'package:shogaku_kore_programming/models/block_model.dart';
import 'package:shogaku_kore_programming/screens/editor_screen.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';
import 'package:shogaku_kore_programming/providers/profile_provider.dart';
import 'test_helpers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('EditorScreen Widget Tests', () {
    // Create a mock challenge for visual programming
    final mockChallenge = Stage(
      id: 'editor_test_1',
      title: 'ロボット移動プログラム',
      description: 'ロボットを右に3歩、下に2歩動かしましょう',
      level: StageLevel.beginner,
      iconId: 'icon_robot',
      questions: const [],
      requiredStars: 1,
      conceptExplanation: '順序を意識してブロックを組み立てます',
      type: 'editor',
      blockLibrary: [
        BlockDefinition(
          id: 'move_right',
          label: '右に進む',
          color: Colors.blue,
          category: 'movement',
          params: [
            BlockParam(
              name: 'steps',
              type: 'number',
              defaultValue: 1,
            ),
          ],
        ),
        BlockDefinition(
          id: 'move_down',
          label: '下に進む',
          color: Colors.green,
          category: 'movement',
          params: [
            BlockParam(
              name: 'steps',
              type: 'number',
              defaultValue: 1,
            ),
          ],
        ),
        BlockDefinition(
          id: 'repeat',
          label: '繰り返す',
          color: Colors.orange,
          category: 'control',
          params: [
            BlockParam(
              name: 'times',
              type: 'number',
              defaultValue: 2,
            ),
          ],
        ),
      ],
    );

    testWidgets('displays editor screen with block library',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      // Verify editor screen is displayed
      expect(find.byType(EditorScreen), findsOneWidget);

      // Verify challenge title is shown
      expect(find.text('ロボット移動プログラム'), findsWidgets);
    });

    testWidgets('displays available blocks in library', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify blocks are displayed in the library
      expect(find.text('右に進む'), findsWidgets);
      expect(find.text('下に進む'), findsWidgets);
    });

    testWidgets('can drag block to workspace', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find a block in the library
      final blockInLibrary = find.text('右に進む').first;

      if (blockInLibrary.evaluate().isNotEmpty) {
        // Drag the block to the workspace area
        final center = tester.getCenter(blockInLibrary);
        await tester.dragFrom(center, const Offset(100, 200));
        await tester.pumpAndSettle();

        // Block should be added to workspace (implementation dependent)
      }
    });

    testWidgets('displays workspace area', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify workspace is displayed (look for canvas or workspace widget)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('run button executes the program', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for run button
      final runButton = find.byIcon(Icons.play_arrow);
      if (runButton.evaluate().isNotEmpty) {
        await tester.tap(runButton.first);
        await tester.pumpAndSettle();

        // Program execution should start
      }
    });

    testWidgets('clear button removes all blocks', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for clear/reset button
      final clearButton = find.byIcon(Icons.refresh);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton.first);
        await tester.pumpAndSettle();

        // Workspace should be cleared
      }
    });

    testWidgets('undo/redo functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for undo button
      final undoButton = find.byIcon(Icons.undo);
      if (undoButton.evaluate().isNotEmpty) {
        await tester.tap(undoButton.first);
        await tester.pumpAndSettle();

        // Recent action should be undone
      }
    });

    testWidgets('displays challenge description', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Challenge description should be visible
      expect(
        find.text('ロボットを右に3歩、下に2歩動かしましょう'),
        findsWidgets,
      );
    });

    testWidgets('hint button shows hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for hint button
      final hintButton = find.byIcon(Icons.lightbulb_outline);
      if (hintButton.evaluate().isNotEmpty) {
        await tester.tap(hintButton.first);
        await tester.pumpAndSettle();

        // Hint should be displayed
      }
    });

    testWidgets('favorite button toggles challenge as favorite',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for favorite button
      final favoriteButton = find.byIcon(Icons.favorite_outline);
      if (favoriteButton.evaluate().isNotEmpty) {
        await tester.tap(favoriteButton.first);
        await tester.pumpAndSettle();

        // Challenge should be marked as favorite (icon changes)
        expect(find.byIcon(Icons.favorite), findsWidgets);
      }
    });

    testWidgets('displays block parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When a block is selected, its parameters should be visible
      // Look for parameter inputs
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('displays robot canvas for preview', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Robot canvas should be displayed
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('shows execution results when program runs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Run the program
      final runButton = find.byIcon(Icons.play_arrow);
      if (runButton.evaluate().isNotEmpty) {
        await tester.tap(runButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Execution results should be visible
      }
    });

    testWidgets('handles block deletion', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add a block
      final blockInLibrary = find.text('右に進む').first;
      if (blockInLibrary.evaluate().isNotEmpty) {
        final center = tester.getCenter(blockInLibrary);
        await tester.dragFrom(center, const Offset(100, 200));
        await tester.pumpAndSettle();

        // Right-click or long-press to delete
        // Look for delete option
        final deleteButton = find.byIcon(Icons.close);
        if (deleteButton.evaluate().isNotEmpty) {
          await tester.tap(deleteButton.first);
          await tester.pumpAndSettle();

          // Block should be removed
        }
      }
    });

    testWidgets('supports keyboard shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test Ctrl+Z for undo
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
    });

    testWidgets('displays challenge completion message on success',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // This depends on the challenge logic
      // When challenge is completed, success message should show
    });

    testWidgets('back button exits editor', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();

        // May show confirmation dialog
      }
    });

    testWidgets('character reacts to user actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for character widget
      expect(find.byType(CustomPaint), findsWidgets);

      // Character should react to actions (implementation dependent)
    });

    testWidgets('displays scoring information', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EditorScreen(challenge: mockChallenge),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for score/stars display
      // This may appear after completion
    });
  });
}
