# Test Guide - 小学コレ！プログラミング

**Status:** ✅ Test Suite Refactored (Sept 2026)

## 📋 Overview

This guide covers running, writing, and maintaining tests for the Flutter app.

## 🧪 Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/providers/progress_provider_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

### Run Tests Verbosely
```bash
flutter test -v
```

### Run Tests on Specific Device
```bash
flutter test -d <device_id>
```

### Run Widget Tests Only
```bash
flutter test test/widgets/
```

### Run Specific Widget Test
```bash
flutter test test/widgets/quiz_screen_test.dart
flutter test test/widgets/home_screen_test.dart
flutter test test/widgets/editor_screen_test.dart
```

### Run Tests for Critical Screens (Priority 1)
```bash
flutter test test/widgets/quiz_screen_test.dart \
  test/widgets/editor_screen_test.dart \
  test/widgets/home_screen_test.dart \
  test/widgets/quiz_result_screen_test.dart
```

## 🏗️ Test Structure

Tests are organized by layer:

```
test/
├── providers/              # State management (Riverpod)
│   ├── achievement_provider_test.dart
│   ├── progress_provider_test.dart
│   ├── badge_provider_test.dart
│   └── ...
└── widgets/               # UI component tests
    ├── test_helpers.dart   # Shared test utilities and fixtures
    ├── quiz_screen_test.dart          # Multiple choice quiz UI
    ├── editor_screen_test.dart        # Visual block programming editor
    ├── home_screen_test.dart          # Main hub navigation
    ├── quiz_result_screen_test.dart   # Result display and scoring
    ├── login_screen_test.dart         # Authentication UI
    ├── splash_screen_test.dart        # App initialization
    ├── achievements_screen_test.dart  # Badges and statistics
    ├── settings_screen_test.dart      # User preferences
    ├── flashcard_screen_test.dart     # Spaced repetition review
    └── ...
```

### Test Types

| Type | Purpose | Location | Command |
|------|---------|----------|---------|
| **Unit** | Test individual providers/functions | `test/providers/` | `flutter test` |
| **Widget** | Test UI components and navigation | `test/widgets/` | `flutter test` |
| **Integration** | Test complete user flows | `integration_test/` | `flutter drive` |

## ✍️ Writing Tests

### Provider Unit Test Template

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/providers/progress_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('ProgressNotifier', () {
    test('initializes with empty progress', () {
      final progress = container.read(progressProvider);
      expect(progress.completedCount, 0);
      expect(progress.starsEarned, 0);
    });

    test('completeChallenge updates state correctly', () {
      final notifier = container.read(progressProvider.notifier);
      notifier.completeChallenge('stage_1', 3);

      final progress = container.read(progressProvider);
      expect(progress.completedCount, 1);
      expect(progress.starsEarned, 3);
    });
  });
}
```

### Widget Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/screens/quiz_screen.dart';

void main() {
  testWidgets('QuizScreen displays question', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuizScreen(challenge: /* ... */),
      ),
    );

    // Find and verify widget
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('Question text'), findsOneWidget);
  });
}
```

## 🎯 Widget Tests (New - Sept 2026)

Comprehensive widget tests have been implemented for critical screens:

| Screen | Tests | Coverage | Status |
|--------|-------|----------|--------|
| QuizScreen | 15+ | Question display, answer selection, submission | ✅ Complete |
| EditorScreen | 16+ | Block library, workspace, execution, parameters | ✅ Complete |
| HomeScreen | 24+ | Progress stats, daily missions, navigation | ✅ Complete |
| QuizResultScreen | 23+ | Results display, scoring, animations | ✅ Complete |
| LoginScreen | 24+ | Form validation, password entry, auth | ✅ Complete |
| SplashScreen | 17+ | Logo animation, routing, app initialization | ✅ Complete |
| AchievementsScreen | 27+ | Badges, tabs, statistics, leaderboard | ✅ Complete |
| SettingsScreen | 26+ | Toggles, preferences, navigation | ✅ Complete |
| FlashcardScreen | 24+ | Card flipping, difficulty rating, progress | ✅ Complete |

**Total Widget Tests Created:** 195+ test cases

### Test Helpers
- **test_helpers.dart** - Reusable utilities for screen testing
  - `TestApp` widget for Riverpod provider setup
  - `pumpTestWidget()` for pumping widgets with dependencies
  - Finder helpers: `findText()`, `findByType()`, `findByKey()`
  - Assertion helpers: `expectExists()`, `expectNotExists()`, `expectText()`
  - User interaction helpers: `tap()`, `enterText()`

## 🐛 Known Test Issues

### Fixed Issues (Sept 2026)
- ✅ **Variable naming inconsistency** - Changed `final _notifier =` to `final notifier =` across all test files
- ✅ **Unused variable warnings** - Removed unnecessary underscore prefixes
- ✅ **Test structure compliance** - All tests now follow consistent patterns
- ✅ **Widget test infrastructure** - Created test_helpers.dart with reusable test utilities
- ✅ **Critical screen coverage** - Implemented 9 comprehensive screen test suites

### Remaining Issues
- 356+ analyzer errors (pre-existing, mostly in unused test helper files)
- Some tests may have incorrect assertions that need review
- Integration tests still needed for full user flows

## 📊 Test Coverage Goals

| Component | Target | Status |
|-----------|--------|--------|
| **Providers** | 80%+ | 🟡 In Progress |
| **Screens** | 60%+ | 🔴 Needs Work |
| **Widgets** | 70%+ | 🔴 Needs Work |
| **Utils** | 90%+ | 🟡 In Progress |

## 🚀 Improving Test Coverage

### Priority 1 (Critical)
- [ ] Progress tracking tests (completedCount, stars, streaks)
- [ ] Challenge completion logic
- [ ] Badge/achievement calculations

### Priority 2 (Important)
- [ ] Quiz screen navigation
- [ ] Editor screen validation
- [ ] Progress persistence

### Priority 3 (Nice to have)
- [ ] Animation tests
- [ ] Accessibility tests
- [ ] Performance tests

## 🔍 Debugging Tests

### Enable Debug Output
```bash
flutter test -v
```

### Run Single Test in Isolation
```bash
flutter test test/providers/progress_provider_test.dart::ProgressNotifier::completeChallenge
```

### Common Test Failures

**Error: "ProviderContainer is already disposed"**
- Solution: Ensure `tearDown()` properly disposes container

**Error: "SharedPreferences is not mocked"**
- Solution: Add `SharedPreferences.setMockInitialValues({})` in `setUp()`

**Error: "Platform channel unavailable"**
- Solution: Mock platform channels or skip platform-dependent tests

```dart
setUp(() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Mock platform channels
});
```

## 📈 Continuous Integration

### GitHub Actions Workflow
Tests can be automated via `.github/workflows/test.yml`:

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```

## 🎯 Next Steps

1. **Fix existing test assertions** - Review and correct test expectations
2. **Add missing tests** - Target 80%+ coverage for providers
3. **Set up CI/CD** - Automate test runs on every push
4. **Add performance tests** - Monitor build and animation performance
5. **Add integration tests** - Test complete user flows

## 📝 Test Maintenance

### When Adding New Features
- [ ] Write test FIRST (TDD approach)
- [ ] Ensure test covers happy path + error cases
- [ ] Run all tests to verify no regressions
- [ ] Update coverage report

### When Refactoring
- [ ] Run full test suite before changes
- [ ] Update tests if behavior changes
- [ ] Verify coverage doesn't decrease
- [ ] Commit tests with refactoring

### Regular Maintenance
- [ ] Review test coverage monthly
- [ ] Remove obsolete tests
- [ ] Consolidate duplicate tests
- [ ] Update mocks/stubs as needed

---

**Last Updated:** Sept 2026  
**Status:** 🟡 Tests refactored, coverage needs improvement
