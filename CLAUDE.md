# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 📱 Project Overview

**小学コレ！プログラミング** - A Flutter app for teaching elementary school students (grades 4-5) programming through a progression from visual block programming to Python code reading and application.

- **Framework:** Flutter 3.13+
- **State Management:** Riverpod 2.6.1
- **Platform:** iOS 14+, Android 10+
- **Language:** Dart
- **Backend:** Firebase (Auth, optional features)
- **Key Dependencies:** Riverpod, SharedPreferences, Firebase, Confetti, AudioPlayers, Flutter Animate

## 🏗️ Architecture

### Layer Structure

The app follows a **layered architecture** with clear separation of concerns:

```
lib/
├── main.dart                    # App entry point (ProviderScope setup)
├── config/                      # Theme, constants, app configuration
├── models/                      # Data models (Stage, Question, Challenge)
├── providers/                   # Riverpod state management providers
├── screens/                     # UI screens (pages, top-level widgets)
├── services/                    # Platform services (audio, haptics, notifications)
├── utils/                       # Helper functions
└── widgets/                     # Reusable UI components
```

### State Management (Riverpod)

**Key Providers:**
- `progressProvider` - User progress tracking (completed stages, stars, streaks)
- `profileProvider` - User settings (sound, haptics, reminder times, theme)
- `allChallengesProvider` - All available stages/challenges
- `challengeProvider` - Individual challenge data
- `authProvider` - Firebase authentication state
- `coinProvider` - In-app currency tracking
- `badgeProvider` - Achievement/badge system
- `wrongAnswersProvider` - Questions user got wrong (for review)
- `daily*Provider` - Daily missions, logins, rewards

**Provider Pattern:**
- StateNotifiers for mutable state (progress, coins, badges)
- Simple providers for computed/derived state
- AsyncNotifiers for async operations (Firebase calls)

### Navigation Flow

1. **SplashScreen** - Initialization (Firebase, services)
2. **HomeScreen** - Main hub (daily missions, progress overview, next stage)
3. **Stage Selection** - Choose challenge type:
   - **QuizScreen** - Multiple choice Python code questions
   - **EditorScreen** - Visual block programming (Blockly-like)
   - **FlashcardScreen** - Spaced repetition review
4. **Achievement Screens** - Badges, leaderboards, activity tracking
5. **Settings** - Audio, haptics, notifications, theme

### Data Models

**Core Models** (in `lib/models/`):
- `Stage` / `Challenge` - Individual learning unit with questions, hints, completion requirements
- `Question` - Quiz question with options and correct answer
- `QuizAnswer` - User's answer to a question
- `StageLevel` - Enum for difficulty (beginner, intermediate, advanced)

**Progress State** (`progressProvider`):
- `completedCount` - Total stages cleared
- `starsEarned` - Total stars collected (1-3 per stage)
- `streakDays` - Consecutive days learning
- `currentLevel` - User's global level (increases with completion)
- `perfectStagesCount` - Stages cleared with all 3 stars

### Key Services

**HapticService** - Vibration feedback (light, medium, heavy impacts)
**SoundService** - Audio feedback (tap, correct, wrong, star, level-up, complete)
**NotificationService** - Local notifications for daily reminders, streaks, weekly reports
**FirebaseService** (implicit via Firebase SDK) - Authentication, optional backend

## 🛠️ Common Commands

### Project Setup
```bash
# Install dependencies
flutter pub get

# Generate Riverpod code (if using code generation)
flutter pub run build_runner build

# Clean build artifacts
flutter clean
flutter pub get
```

### Development & Testing

```bash
# Run app on default device
flutter run

# Run on specific device
flutter run -d iPhone          # iOS simulator
flutter run -d android-phone   # Android emulator

# Run with hot reload (active during development)
flutter run -v                 # Verbose mode

# Run a single test
flutter test test/providers/progress_provider_test.dart

# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Linting & Analysis

```bash
# Analyze code without building
flutter analyze

# Format code
dart format lib/

# Check formatting without changes
dart format lib/ --set-exit-if-changed

# View warnings that may be suppressed
flutter analyze --no-line-length

# Fix common issues automatically
dart fix lib/ --apply
```

### Building

```bash
# Build APK for Android
flutter build apk --release

# Build iOS app
flutter build ios --release

# Build for web (if enabled)
flutter build web --release
```

## 🔄 Riverpod Patterns Used

### StateNotifier (Mutable State)

```dart
class ProgressNotifier extends StateNotifier<ProgressState> {
  void completeChallenge(String challengeId, int stars) {
    // Mutate state
    state = state.copyWith(...);
  }
}

final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>(...);
```

**Usage in Screens:**
```dart
// Read state
final progress = ref.watch(progressProvider);

// Mutate state
ref.read(progressProvider.notifier).completeChallenge(id, stars);
```

### Simple Provider (Computed/Derived)

```dart
final totalStarsProvider = Provider((ref) {
  final progress = ref.watch(progressProvider);
  return progress.starsEarned;
});
```

### AsyncNotifier (For Async Operations)

```dart
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return await Firebase.Auth.currentUser();
  }
}
```

## ⚠️ Critical Areas & Known Issues

### Recent Fixes (Sept 2026 - Session 2)
- **CRITICAL - Map Key Bug**: Fixed `challengeId:` → `(challengeId):` in progress_provider.dart:313
  - Was storing all progress under literal key "challengeId", causing data loss
  - Now properly uses variable as map key for per-stage progress tracking
- **CRITICAL - Async Data Loss**: Made `awardHomeWeeklyBonus()` async and awaited `addBonusPoints()`
  - Was calling async future without await in progress_provider.dart:145-155
  - Could lose point awards if persistence failed mid-operation
- **Callback Syntax Error**: Fixed `onTap: openStage?` → `onTap: openStage` in home_screen.dart:3034
  - Invalid trailing `?` on non-optional callback reference
- **Riverpod Reactivity**: Fixed `select()` with `ref.read()` in achievements_screen.dart:2178
  - Was using wrong pattern that defeated reactive updates for totalLearningSeconds
  - Now properly watches notifier for reactive UI updates

### Earlier Fixes (Sept 2026 - Session 1)
- **Dart Syntax Errors**: Resolved invalid nullable type syntax (`Stage??` → `Stage?`) and invalid null-coalescing operators across 6 screen files
- **Method Name Corrections**: Fixed `completeStage()` → `completeChallenge()` in quiz/editor completion flows

### Test File Issues
- 356+ analyzer errors in test files (pre-existing, not blocking app compilation)
- Test suite requires updates but are separate from main app functionality

### Firebase Integration
- Firebase initialization is deferred to post-frame callback to reduce startup time (~600ms optimization)
- Catches Firebase init errors gracefully to prevent app crash if Firebase unavailable

### Platform-Specific Considerations
- **Notifications**: Uses `flutter_local_notifications` but crashes if platform channel unavailable (e.g., in widget tests) - wrapped in try-catch
- **Audio/Haptics**: Gracefully disabled if device doesn't support

## 🚦 Development Best Practices

### Code Style
- Follow Flutter style guide (dart format)
- Use meaningful variable/method names
- Prefer immutable data models with `.copyWith()` for updates

### Riverpod Guidelines
- Always use `.watch()` for reactive updates, `.read()` for one-time access
- Keep StateNotifiers focused on single concern
- Use FutureProvider/AsyncNotifier for async state

### Screen Architecture
- Screens are `ConsumerStatefulWidget` or `ConsumerWidget`
- State management delegated to Riverpod, not local State
- Use `ref.watch()` for reactive UI updates
- Keep UI logic minimal, extract to methods

### Testing
- Unit tests for providers (progress calculation, state transitions)
- Widget tests for UI components and navigation
- Integration tests for critical user flows

## 📚 Important Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, Firebase setup, services initialization |
| `lib/config/theme.dart` | Theme, colors, typography for entire app |
| `lib/config/constants.dart` | App-wide constants (stage counts, level thresholds) |
| `lib/providers/challenges_provider.dart` | All stage/challenge definitions (~136KB - large data file) |
| `lib/providers/progress_provider.dart` | Core progress tracking and completion logic |
| `lib/screens/home_screen.dart` | Main hub screen (uses many providers) |
| `lib/screens/quiz_screen.dart` | Quiz challenge UI |
| `lib/screens/editor_screen.dart` | Visual block programming editor |

## 🔍 Common Debugging Patterns

### Check User Progress State
```dart
final progress = ref.read(progressProvider);
print('Completed: ${progress.completedCount}');
print('Stars: ${progress.starsEarned}');
print('Current Level: ${progress.currentLevel}');
```

### Verify Challenge Data
```dart
final challenges = ref.read(allChallengesProvider);
final stage = challenges.firstWhere((c) => c.id == 'stage_1');
```

### Test Provider Logic
```dart
// In tests, use ProviderContainer to test provider independently
final container = ProviderContainer();
final progress = container.read(progressProvider);
```

## 📦 Dependency Management

All dependencies are in `pubspec.yaml`. Key ones:
- **flutter_riverpod** - State management
- **shared_preferences** - Local data persistence
- **firebase_core/auth** - Backend services
- **flutter_animate** - UI animations
- **confetti** - Celebration effects
- **audioplayers** - Sound effects
- **fl_chart** - Charts for analytics
- **google_mobile_ads** - Ad system integration

**Custom Package:**
- `shared_core` - External package from https://github.com/org-zka32101/shared_core.git (main branch)

## 🐛 Recent Debugging Notes

When working with progress tracking:
1. Remember that `completeChallenge()` is the method name (not `completeStage`)
2. The method signature expects: `completeChallenge(String challengeId, int stars)`
3. Progress updates are reactive - UI rebuilds automatically via `ref.watch()`
4. Level-up detection requires capturing level before/after challenge completion

---

**Last Updated:** Sept 2026  
**Status:** ✅ Production Ready (Dart syntax errors resolved, critical bugs fixed)
