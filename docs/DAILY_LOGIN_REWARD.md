# Daily Login Reward System

## Overview

The Daily Login Reward System is a gamification feature that encourages user engagement through consecutive daily logins. Users receive increasing rewards as they maintain their login streak, with milestone bonuses at specific days (3, 7, 14, 30 days). The system tracks streaks, prevents duplicate claims on the same day, and persists all data locally using SharedPreferences.

## Architecture

### State Management Pattern

The system uses Riverpod's `StateNotifier` pattern for reactive state management:

```
DailyLoginRewardNotifier (StateNotifier)
    ↓
DailyLoginRewardState (Immutable)
    ├── rewardData: DailyLoginRewardData
    ├── userStreak: LoginStreak
    ├── stats: LoginRewardStats
    ├── isLoading: bool
    ├── error: String?
    └── lastUpdatedAt: DateTime?
```

### Data Flow

1. **Initialization**: `initializeLoginRewards(userId)` loads or creates user data
2. **Daily Claim**: `claimDailyReward(userId)` processes reward claims with automatic streak calculation
3. **Persistence**: `_persistRewardData(userId)` saves state to SharedPreferences
4. **Consumption**: Multiple Riverpod providers expose derived state

## Core Models

### RewardLevel Enum

Defines milestone levels for reward progression:

```dart
enum RewardLevel {
  day1,      // Day 1 baseline
  day3,      // 3-day streak bonus
  day7,      // 7-day streak bonus
  day14,     // 14-day streak bonus
  day30,     // 30-day streak bonus
  milestone, // Future milestone support
}
```

### DailyLoginReward

Represents a single reward tier:

```dart
class DailyLoginReward {
  final String rewardId;           // Unique identifier
  final RewardLevel level;         // Milestone level
  final int xpAmount;              // XP reward
  final int coinAmount;            // Coin reward
  final String? badgeId;           // Optional badge unlock
  final String description;        // Reward description (Japanese)
  final bool isStreakBonus;        // Streak milestone indicator
}
```

**Default Reward Configuration:**

| Level | XP | Coins | Badge | Description |
|-------|----|----|-------|-------------|
| day1  | 10 | 5 | - | 1日目ボーナス |
| day3  | 30 | 15 | streak_3days | 3日連続ボーナス |
| day7  | 70 | 35 | streak_7days | 7日連続ボーナス |
| day14 | 140 | 70 | streak_14days | 14日連続ボーナス |
| day30 | 300 | 150 | streak_30days | 30日連続ボーナス |

### LoginStreak

Tracks user's consecutive login streaks:

```dart
class LoginStreak {
  final String userId;
  final int currentStreak;           // Current consecutive days
  final int longestStreak;           // Best streak achieved
  final DateTime lastLoginDate;      // Most recent login
  final DateTime? streakStartDate;   // When current streak began
  final List<DateTime> loginHistory; // Last 90 logins
}
```

**Computed Properties:**

- `isStreakActive`: Returns `true` if last login was within 1 day (today or yesterday)
- `isLoggedInToday`: Returns `true` if last login was today (same calendar day)

### LoginRewardClaim

Records individual reward claims:

```dart
class LoginRewardClaim {
  final String claimId;            // Unique claim identifier
  final String userId;             // User who claimed
  final String rewardId;           // Reward ID
  final RewardLevel level;         // Milestone level
  final int xpEarned;              // XP awarded
  final int coinEarned;            // Coins awarded
  final DateTime claimedAt;        // Claim timestamp
  final int streakDayAtClaim;      // Streak length at claim time
}
```

### LoginRewardStats

Aggregated user statistics:

```dart
class LoginRewardStats {
  final String userId;
  final int totalRewardsClaimed;          // Total claims made
  final int totalXpEarned;                // Total XP accumulated
  final int totalCoinEarned;              // Total coins accumulated
  final DateTime? firstLoginDate;         // Initial login date
  final DateTime lastResetDate;           // Last streak reset
  final List<LoginRewardClaim> recentClaims; // Last 30 claims
}
```

### DailyLoginRewardData

Aggregates all reward data:

```dart
class DailyLoginRewardData {
  final List<DailyLoginReward> availableRewards;
  final LoginStreak userStreak;
  final LoginRewardStats stats;
  final DateTime generatedAt;
}
```

**Methods:**

- `getNextReward()`: Returns the next achievable reward based on current streak
- `canClaimToday()`: Returns `true` if user hasn't claimed today

## State Management

### DailyLoginRewardNotifier

Implements core business logic:

#### Key Methods

**initializeLoginRewards(String userId)**

Loads existing user data from SharedPreferences or creates new user:

```dart
await notifier.initializeLoginRewards('user123');
```

Process:
1. Sets `isLoading = true`
2. Attempts to load `login_streak_$userId` from SharedPreferences
3. If not found, creates new `LoginStreak` with `currentStreak = 0`
4. Attempts to load `login_stats_$userId` from SharedPreferences
5. If not found, creates new `LoginRewardStats`
6. Creates `DailyLoginRewardData` with generated default rewards
7. Updates state and persists data
8. Sets `isLoading = false`

**claimDailyReward(String userId)**

Main claim logic with automatic streak calculation:

```dart
final claim = await notifier.claimDailyReward('user123');
```

Process:
1. Validates user data is initialized
2. Checks `isLoggedInToday` - rejects if already claimed
3. Calculates new streak:
   - If `isStreakActive = false`: Reset to 1
   - If `isStreakActive = true`: Increment by 1
4. Awards reward based on streak milestone:
   - Day 1: 10 XP, 5 coins
   - Day 3: 30 XP, 15 coins (badge: streak_3days)
   - Day 7: 70 XP, 35 coins (badge: streak_7days)
   - Day 14: 140 XP, 70 coins (badge: streak_14days)
   - Day 30: 300 XP, 150 coins (badge: streak_30days)
   - Other days: Day 1 rewards
5. Creates `LoginRewardClaim` record
6. Updates `LoginStreak`:
   - Sets `currentStreak = newStreak`
   - Updates `longestStreak = max(oldLongest, newStreak)`
   - Sets `lastLoginDate = now()`
   - Appends to `loginHistory` (max 90)
7. Updates `LoginRewardStats`:
   - Increments `totalRewardsClaimed`
   - Adds XP/coin amounts
   - Prepends claim to `recentClaims` (max 30)
8. Persists data
9. Returns `LoginRewardClaim` or `null` on error

**resetStreak(String userId)**

Resets broken streaks:

```dart
await notifier.resetStreak('user123');
```

Process:
1. Gets current streak
2. Sets `currentStreak = 0`
3. Preserves `longestStreak`
4. Sets `lastLoginDate = 2 days ago` (to prevent false reactivation)
5. Updates `lastResetDate` in stats
6. Persists data

**Getter Methods:**

- `getCurrentStreak()`: Returns `userStreak?.currentStreak ?? 0`
- `getLongestStreak()`: Returns `userStreak?.longestStreak ?? 0`
- `getTotalXpEarned()`: Returns `stats?.totalXpEarned ?? 0`
- `getTotalCoinEarned()`: Returns `stats?.totalCoinEarned ?? 0`
- `canClaimToday()`: Returns `rewardData?.canClaimToday() ?? false`

## Riverpod Providers

All providers use `autoDispose` for automatic cleanup:

### Main Provider

```dart
final dailyLoginRewardProvider = StateNotifierProvider.autoDispose<
    DailyLoginRewardNotifier,
    DailyLoginRewardState>((ref) => DailyLoginRewardNotifier());
```

Provides full state access and notifier for methods.

### Derived Providers

```dart
// Current streak (int)
final currentStreakProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(dailyLoginRewardProvider).userStreak?.currentStreak ?? 0;
});

// Longest streak (int)
final longestStreakProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(dailyLoginRewardProvider).userStreak?.longestStreak ?? 0;
});

// Can claim today (bool)
final canClaimTodayProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(dailyLoginRewardProvider).rewardData?.canClaimToday() ?? false;
});

// Next reward (DailyLoginReward?)
final nextRewardProvider = Provider.autoDispose<DailyLoginReward?>((ref) {
  return ref.watch(dailyLoginRewardProvider).rewardData?.getNextReward();
});

// Stats object (LoginRewardStats?)
final loginRewardStatsProvider = Provider.autoDispose<LoginRewardStats?>((ref) {
  return ref.watch(dailyLoginRewardProvider).stats;
});

// Streak object (LoginStreak?)
final loginStreakProvider = Provider.autoDispose<LoginStreak?>((ref) {
  return ref.watch(dailyLoginRewardProvider).userStreak;
});
```

## Usage Examples

### Basic Integration

```dart
class DailyRewardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardState = ref.watch(dailyLoginRewardProvider);
    final currentStreak = ref.watch(currentStreakProvider);
    final canClaim = ref.watch(canClaimTodayProvider);

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text('Current Streak: $currentStreak days'),
            if (canClaim)
              ElevatedButton(
                onPressed: () => _claimReward(context, ref),
                child: Text('Claim Reward'),
              )
            else
              Text('Already claimed today!'),
          ],
        ),
      ),
    );
  }

  Future<void> _claimReward(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(dailyLoginRewardProvider.notifier);
    final claim = await notifier.claimDailyReward('user_id');
    
    if (claim != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '+${claim.xpEarned} XP, +${claim.coinEarned} Coins',
          ),
        ),
      );
    }
  }
}
```

### Initialization

```dart
class AppInitializer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _initialize(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MainApp();
        }
        return LoadingScreen();
      },
    );
  }

  Future<void> _initialize(WidgetRef ref) async {
    final notifier = ref.read(dailyLoginRewardProvider.notifier);
    await notifier.initializeLoginRewards('user_id');
  }
}
```

### Streak Display Widget

```dart
class StreakCounter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStreak = ref.watch(currentStreakProvider);
    final longestStreak = ref.watch(longestStreakProvider);
    
    return Row(
      children: [
        Streak Indicator('Current', currentStreak),
        SizedBox(width: 16),
        StreakIndicator('Best', longestStreak),
      ],
    );
  }
}
```

### Reward Preview

```dart
class NextRewardPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextReward = ref.watch(nextRewardProvider);

    if (nextReward == null) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Next Reward: ${nextReward.description}'),
            Text('+${nextReward.xpAmount} XP, +${nextReward.coinAmount} Coins'),
            if (nextReward.badgeId != null)
              Text('🏆 Badge Unlock'),
          ],
        ),
      ),
    );
  }
}
```

## Persistence Strategy

### SharedPreferences Keys

All data stored with user ID prefix:

- `login_streak_$userId`: Serialized `LoginStreak.toJson()`
- `login_stats_$userId`: Serialized `LoginRewardStats.toJson()`
- `login_reward_last_updated_$userId`: ISO8601 timestamp

### JSON Serialization

All models implement `toJson()` and `fromJson()` factories:

```dart
// Save
final json = streak.toJson();
await prefs.setString('login_streak_$userId', json.toString());

// Load
final json = jsonDecode(prefs.getString('login_streak_$userId')!);
final streak = LoginStreak.fromJson(json);
```

## Error Handling

The system gracefully handles errors:

1. **Uninitialized data**: Methods return `null` or default values
2. **JSON parsing errors**: Silently fall back to initialization
3. **SharedPreferences errors**: Silently ignored (data not persisted)

Example error state:

```dart
final state = ref.watch(dailyLoginRewardProvider);
if (state.error != null) {
  // Display error to user
  showErrorDialog(context, state.error!);
}
if (state.isLoading) {
  // Show loading indicator
  return LoadingSpinner();
}
```

## Testing

### Model Tests

`test/models/daily_login_reward_test.dart` includes:

- 40+ test cases covering:
  - Model instantiation
  - JSON serialization/deserialization
  - Computed properties (`isStreakActive`, `isLoggedInToday`, `canClaimToday`)
  - Round-trip JSON preservation
  - Edge cases (empty history, null dates)

### Provider Tests

`test/providers/daily_login_reward_provider_test.dart` includes:

- 45+ test cases covering:
  - State initialization
  - Daily reward claiming
  - Streak calculation and reset
  - Milestone reward distribution
  - Statistics updates
  - SharedPreferences persistence
  - Riverpod provider derivation
  - Error handling

### Running Tests

```bash
flutter test test/models/daily_login_reward_test.dart
flutter test test/providers/daily_login_reward_provider_test.dart
```

## Performance Considerations

1. **Compute Efficiency**: All computations are O(1) except:
   - `getNextReward()`: O(n) where n = number of rewards (≤ 6)
   - `claimDailyReward()`: O(n) for list updates

2. **Memory Usage**:
   - `loginHistory`: Fixed at 90 entries (max ~2KB)
   - `recentClaims`: Fixed at 30 entries (max ~3KB)
   - Total per-user state: ~5KB

3. **Persistence**: 
   - AsyncOperations: Single prefs instance (shared)
   - Data size: ~5KB per user
   - Frequency: Only on initialization and claims

## Future Enhancements

1. **Milestone Expansions**: Add day 60, 90, 365 milestones
2. **Seasonal Bonuses**: Holiday-specific reward multipliers
3. **Social Bonuses**: Group streak bonuses
4. **Leaderboard Integration**: Track top streaks
5. **Cloud Sync**: Backup streak data to server
6. **Custom Rewards**: Admin-configurable reward tiers

## Debugging

### Print Streak Status

```dart
final streak = ref.watch(loginStreakProvider);
print('Current: ${streak?.currentStreak}, Longest: ${streak?.longestStreak}');
print('Active: ${streak?.isStreakActive}, Today: ${streak?.isLoggedInToday}');
```

### Inspect State

```dart
final state = ref.watch(dailyLoginRewardProvider);
print('Loading: ${state.isLoading}');
print('Error: ${state.error}');
print('Updated: ${state.lastUpdatedAt}');
```

### Clear Local Data (Debug Only)

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('login_streak_$userId');
await prefs.remove('login_stats_$userId');
await prefs.remove('login_reward_last_updated_$userId');
```

## See Also

- [Gamification System Overview](./GAMIFICATION.md)
- [Riverpod Documentation](https://riverpod.dev)
- [Flutter SharedPreferences](https://pub.dev/packages/shared_preferences)
