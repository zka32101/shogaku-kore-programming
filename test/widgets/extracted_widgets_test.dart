import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/widgets/stat_item.dart';
import 'package:shogaku_kore_programming/widgets/mini_stat_card.dart';
import 'package:shogaku_kore_programming/widgets/quality_mini_card.dart';
import 'package:shogaku_kore_programming/widgets/completed_stage_card.dart';
import 'package:shogaku_kore_programming/widgets/filter_chip.dart';
import 'package:shogaku_kore_programming/config/theme.dart';
import 'package:shogaku_kore_programming/models/stage.dart';

void main() {
  group('Extracted Widget Tests', () {
    // StatItem Widget Tests
    group('StatItem Widget', () {
      testWidgets('displays icon, value, and label correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatItem(
                icon: '🧩',
                value: '42',
                label: 'Puzzles Solved',
              ),
            ),
          ),
        );

        expect(find.text('🧩'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        expect(find.text('Puzzles Solved'), findsOneWidget);
      });

      testWidgets('renders with correct text styles',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatItem(
                icon: '📊',
                value: '100',
                label: 'Total Score',
              ),
            ),
          ),
        );

        final valueFinder = find.text('100');
        expect(valueFinder, findsOneWidget);

        final valueWidget = tester.widget<Text>(valueFinder);
        expect(valueWidget.style?.fontSize, 20);
        expect(valueWidget.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('handles emoji icons correctly',
          (WidgetTester tester) async {
        const emoji = '⭐';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatItem(
                icon: emoji,
                value: '999',
                label: 'Stars',
              ),
            ),
          ),
        );

        expect(find.text(emoji), findsOneWidget);
      });
    });

    // MiniStatCard Widget Tests
    group('MiniStatCard Widget', () {
      testWidgets('displays emoji, value, and label correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MiniStatCard(
                emoji: '🎯',
                value: '15',
                label: 'Accuracy',
                color: kPrimaryColor,
              ),
            ),
          ),
        );

        expect(find.text('🎯'), findsOneWidget);
        expect(find.text('15'), findsOneWidget);
        expect(find.text('Accuracy'), findsOneWidget);
      });

      testWidgets('renders with correct container decoration',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MiniStatCard(
                emoji: '📈',
                value: '85',
                label: 'Progress',
                color: Colors.blue,
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);
      });

      testWidgets('applies custom color to text and border',
          (WidgetTester tester) async {
        const customColor = Color(0xFF9B59B6);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MiniStatCard(
                emoji: '🌟',
                value: '50',
                label: 'Level',
                color: customColor,
              ),
            ),
          ),
        );

        final textFinders = find.text('50');
        expect(textFinders, findsOneWidget);
      });

      testWidgets('renders row layout with horizontal alignment',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MiniStatCard(
                emoji: '🏆',
                value: '10',
                label: 'Achievements',
                color: Colors.orange,
              ),
            ),
          ),
        );

        final rowFinder = find.byType(Row);
        expect(rowFinder, findsWidgets);
      });
    });

    // QualityMiniCard Widget Tests
    group('QualityMiniCard Widget', () {
      testWidgets('displays all components correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QualityMiniCard(
                emoji: '📚',
                value: '75%',
                label: 'Comprehension',
                color: kPrimaryColor,
                progress: 0.75,
              ),
            ),
          ),
        );

        expect(find.text('📚'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('Comprehension'), findsOneWidget);
      });

      testWidgets('renders animated progress bar',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QualityMiniCard(
                emoji: '🚀',
                value: '100%',
                label: 'Speed',
                color: Colors.green,
                progress: 1.0,
              ),
            ),
          ),
        );

        expect(find.byType(TweenAnimationBuilder), findsOneWidget);
      });

      testWidgets('handles progress values between 0 and 1',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QualityMiniCard(
                emoji: '⚡',
                value: '50%',
                label: 'Energy',
                color: Colors.yellow,
                progress: 0.5,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('50%'), findsOneWidget);
        expect(find.text('Energy'), findsOneWidget);
      });

      testWidgets('renders LinearProgressIndicator',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QualityMiniCard(
                emoji: '💪',
                value: '90%',
                label: 'Strength',
                color: Colors.red,
                progress: 0.9,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('uses custom color for progress indicator',
          (WidgetTester tester) async {
        const customColor = Color(0xFFE67E22);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QualityMiniCard(
                emoji: '🎨',
                value: '80%',
                label: 'Creativity',
                color: customColor,
                progress: 0.8,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    // CompletedStageCard Widget Tests
    group('CompletedStageCard Widget', () {
      testWidgets('displays stage information correctly',
          (WidgetTester tester) async {
        final testStage = Stage(
          id: 'stage_1',
          title: 'Hello World',
          description: 'Learn the basics',
          icon: '🧩',
          stageNumber: 1,
          level: '初級',
          questions: const [],
          hints: const [],
          maxStars: 3,
          estimatedTime: '5 min',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CompletedStageCard(
                challenge: testStage,
                starsEarned: 3,
              ),
            ),
          ),
        );

        expect(find.text('Hello World'), findsOneWidget);
        expect(find.text('Stage 1'), findsOneWidget);
      });

      testWidgets('displays correct number of stars',
          (WidgetTester tester) async {
        final testStage = Stage(
          id: 'stage_2',
          title: 'Variables',
          description: 'Learn variables',
          icon: '📦',
          stageNumber: 2,
          level: '中級',
          questions: const [],
          hints: const [],
          maxStars: 3,
          estimatedTime: '10 min',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CompletedStageCard(
                challenge: testStage,
                starsEarned: 2,
              ),
            ),
          ),
        );

        final starIcons = find.byIcon(Icons.star);
        final starBorderIcons = find.byIcon(Icons.star_border);

        expect(starIcons, findsWidgets);
        expect(starBorderIcons, findsWidgets);
      });

      testWidgets('displays completion date when provided',
          (WidgetTester tester) async {
        final testStage = Stage(
          id: 'stage_3',
          title: 'Loops',
          description: 'Learn loops',
          icon: '🔄',
          stageNumber: 3,
          level: '上級',
          questions: const [],
          hints: const [],
          maxStars: 3,
          estimatedTime: '15 min',
        );

        final completedDate = DateTime(2026, 9, 5);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CompletedStageCard(
                challenge: testStage,
                starsEarned: 3,
                completedAt: completedDate,
              ),
            ),
          ),
        );

        expect(find.text('2026/09/05 クリア'), findsOneWidget);
      });

      testWidgets('renders with stage level color indicator',
          (WidgetTester tester) async {
        final testStage = Stage(
          id: 'stage_4',
          title: 'Functions',
          description: 'Learn functions',
          icon: '⚙️',
          stageNumber: 4,
          level: '初級',
          questions: const [],
          hints: const [],
          maxStars: 3,
          estimatedTime: '12 min',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CompletedStageCard(
                challenge: testStage,
                starsEarned: 1,
              ),
            ),
          ),
        );

        expect(find.byType(Container), findsWidgets);
      });
    });

    // CustomFilterChip Widget Tests
    group('CustomFilterChip Widget', () {
      testWidgets('displays label text correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomFilterChip(
                label: 'All',
                selected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('All'), findsOneWidget);
      });

      testWidgets('shows selected state with visual feedback',
          (WidgetTester tester) async {
        bool isSelected = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MaterialApp(
                home: Scaffold(
                  body: CustomFilterChip(
                    label: 'Selected',
                    selected: isSelected,
                    onTap: () {
                      setState(() => isSelected = !isSelected);
                    },
                  ),
                ),
              );
            },
          ),
        );

        expect(find.text('Selected'), findsOneWidget);

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();
      });

      testWidgets('calls onTap callback when tapped',
          (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomFilterChip(
                label: 'Tap Me',
                selected: false,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);

        expect(tapped, isTrue);
      });

      testWidgets('applies custom color when provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomFilterChip(
                label: 'Colored',
                selected: true,
                onTap: () {},
                selectedColor: Colors.purple,
              ),
            ),
          ),
        );

        expect(find.text('Colored'), findsOneWidget);
      });

      testWidgets('animates between selected and unselected states',
          (WidgetTester tester) async {
        bool isSelected = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MaterialApp(
                home: Scaffold(
                  body: CustomFilterChip(
                    label: 'Animate',
                    selected: isSelected,
                    onTap: () {
                      setState(() => isSelected = !isSelected);
                    },
                  ),
                ),
              );
            },
          ),
        );

        final animatedContainerBefore =
            find.byType(AnimatedContainer).first;
        expect(animatedContainerBefore, findsOneWidget);

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        final animatedContainerAfter =
            find.byType(AnimatedContainer).first;
        expect(animatedContainerAfter, findsOneWidget);
      });

      testWidgets('renders with correct border styling in selected state',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomFilterChip(
                label: 'Bordered',
                selected: true,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedContainer), findsOneWidget);
      });
    });

    // Integration Tests
    group('Widget Integration Tests', () {
      testWidgets('MiniStatCard works in a row layout',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: MiniStatCard(
                      emoji: '🎯',
                      value: '10',
                      label: 'Left',
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: MiniStatCard(
                      emoji: '📊',
                      value: '20',
                      label: 'Right',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Left'), findsOneWidget);
        expect(find.text('Right'), findsOneWidget);
      });

      testWidgets('StatItem displays correctly in a column',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  StatItem(icon: '1️⃣', value: 'First', label: 'Item'),
                  StatItem(icon: '2️⃣', value: 'Second', label: 'Item'),
                  StatItem(icon: '3️⃣', value: 'Third', label: 'Item'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsOneWidget);
        expect(find.text('Third'), findsOneWidget);
      });

      testWidgets('Filter chips work in a scrollable row',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CustomFilterChip(
                      label: 'All',
                      selected: true,
                      onTap: () {},
                    ),
                    CustomFilterChip(
                      label: 'Active',
                      selected: false,
                      onTap: () {},
                    ),
                    CustomFilterChip(
                      label: 'Completed',
                      selected: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('All'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });
    });
  });
}
