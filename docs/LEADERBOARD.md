# Social Leaderboards & Ranking System

The Social Leaderboards & Ranking System provides competitive gamification through global and category-specific rankings, real-time ranking change notifications, and tier-based progression.

## Overview

This feature integrates with the Multiplayer System to create a comprehensive social competition framework:

- **Global Rankings**: Unified ranking across all users by XP, level, and match performance
- **Category Rankings**: Specialized rankings per learning category (variables, loops, etc.)
- **Ranking Tiers**: Four-tier system (Bronze, Silver, Gold, Platinum) based on rank position
- **Ranking Change Detection**: Real-time notifications when users advance or decline in rank
- **Time-Based Leaderboards**: Rankings filtered by time unit (all-time, monthly, weekly, daily)
- **Pagination Support**: Efficient leaderboard browsing with page-based retrieval

## Architecture

### Data Models (lib/models/leaderboard.dart)

#### Enums

**LeaderboardTimeUnit**
- `allTime`: Rankings across entire application history
- `monthly`: Ranked by performance in current month
- `weekly`: Ranked by performance in current week
- `daily`: Ranked by performance in current day

**RankingTier**
- `bronze`: Rank 1001+
- `silver`: Rank 101-1000
- `gold`: Rank 11-100
- `platinum`: Rank 1-10

**LeaderboardRegion**
- `global`: Worldwide rankings (reserved for future expansion)
- `japan`: Japan-region specific rankings
- `asia`: Asia-region specific rankings
- `other`: Other regions

#### GlobalLeaderboardEntry

Represents a user's position in the global ranking.

```dart
class GlobalLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final int level;
  final int totalXp;
  final double averageAccuracy;
  final int matchesWon;
  final int matchesPlayed;
  final double winRate;
  final int currentStreak;
  final int longestStreak;
  final RankingTier tier;
  final DateTime lastUpdatedAt;
}
```

**Key fields:**
- `rank`: Current position (1 = top)
- `tier`: Calculated from rank position
- `winRate`: matchesWon / matchesPlayed
- `currentStreak`: Consecutive wins in recent matches
- `longestStreak`: All-time best consecutive wins

**Static Methods:**
- `calculateTier(int rank)`: Returns tier based on rank position

#### CategoryLeaderboardEntry

Represents a user's ranking within a specific learning category.

```dart
class CategoryLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final LearningCategory category;
  final double accuracy;
  final int quizzesCompleted;
  final int correctAnswers;
  final DateTime lastUpdatedAt;
}
```

**Used for:** Category-specific competitive rankings (e.g., "Best Variables Quiz Players")

#### RankingChangeNotification

Triggered when a user's rank or tier changes.

```dart
class RankingChangeNotification {
  final String notificationId;
  final String userId;
  final LeaderboardTimeUnit timeUnit;
  final int previousRank;
  final int currentRank;
  final RankingTier previousTier;
  final RankingTier currentTier;
  final bool isPromotion; // true if rank improved
  final DateTime createdAt;
  final bool isRead;

  // Getters
  int get rankChange => previousRank - currentRank; // Positive = improvement
  bool get isTierPromotion => currentTier.index > previousTier.index;
  bool get isTierDemotion => currentTier.index < previousTier.index;
}
```

#### LeaderboardData

Aggregated leaderboard snapshot with all rankings for a time period.

```dart
class LeaderboardData {
  final LeaderboardTimeUnit timeUnit;
  final DateTime generatedAt;
  final List<GlobalLeaderboardEntry> globalRankings;
  final Map<LearningCategory, List<CategoryLeaderboardEntry>> categoryRankings;
  final List<RankingChangeNotification> recentChanges;
}
```

#### UserRankingPosition

User's current ranking information with comparison to previous state.

```dart
class UserRankingPosition {
  final String userId;
  final int globalRank;
  final RankingTier tier;
  final Map<LearningCategory, int> categoryRanks;
  final int previousGlobalRank;
  final DateTime lastUpdatedAt;

  // Getters
  bool get isRankImproved => globalRank < previousGlobalRank;
  bool get isRankDeclined => globalRank > previousGlobalRank;
  bool get isRankUnchanged => globalRank == previousGlobalRank;
}
```

### State Management (lib/providers/leaderboard_provider.dart)

#### LeaderboardState

Manages all leaderboard-related state.

```dart
class LeaderboardState {
  final LeaderboardData? leaderboardData;
  final UserRankingPosition? userRankingPosition;
  final Map<String, UserRankingPosition> userRankings;
  final List<RankingChangeNotification> notifications;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdatedAt;

  LeaderboardState copyWith({...});
  Map<String, dynamic> toJson() => {...};
  factory LeaderboardState.fromJson(Map<String, dynamic> json) => {...};
}
```

#### LeaderboardNotifier

Manages leaderboard generation, ranking calculations, and notifications.

**Key Methods:**

```dart
// Generate global leaderboard
Future<LeaderboardData> generateGlobalLeaderboard({
  required LeaderboardTimeUnit timeUnit,
  int limit = 100,
})

// Get user's ranking position
Future<UserRankingPosition> getUserRankingPosition(
  String userId,
  {required LeaderboardTimeUnit timeUnit}
)

// Get paginated leaderboard
Future<List<GlobalLeaderboardEntry>> getLeaderboardPage({
  required int pageSize,
  required int pageIndex,
  LeaderboardRegion region = LeaderboardRegion.global,
})

// Load cached leaderboard
Future<void> loadLocalLeaderboardData()

// Mark notification as read
Future<void> markNotificationAsRead(String notificationId)

// Get unread notification count
int getUnreadNotificationCount()
```

**Notification Flow:**

1. User's XP/level changes → ranking recalculated
2. New rank differs from previous rank → notification created
3. Notification added to state with `isRead: false`
4. UI displays notification to user
5. User dismisses notification → `markNotificationAsRead(id)` called
6. Notification persisted with `isRead: true`

**Persistence:**

- `leaderboard_data`: Serialized `LeaderboardData` to SharedPreferences
- `leaderboard_notifications`: Last 100 notifications persisted
- 100-item cache limit for memory efficiency

### Providers

```dart
// Main leaderboard provider
final leaderboardProvider = StateNotifierProvider.autoDispose<
  LeaderboardNotifier, 
  LeaderboardState
>

// Global leaderboard data (with caching)
final globalLeaderboardProvider = FutureProvider.autoDispose<LeaderboardData?>

// User's ranking position (family provider)
final userRankingPositionProvider = FutureProvider.autoDispose.family<
  UserRankingPosition?, 
  String // userId
>

// All ranking notifications
final rankingNotificationsProvider = Provider.autoDispose<List<RankingChangeNotification>>

// Unread notification count
final unreadNotificationCountProvider = Provider.autoDispose<int>

// Paginated leaderboard
final leaderboardPageProvider = FutureProvider.autoDispose.family<
  List<GlobalLeaderboardEntry>,
  ({int pageSize, int pageIndex})
>
```

## Tier Progression

### Tier Boundaries

| Tier | Rank Range | Badge |
|------|-----------|-------|
| Platinum ♦️ | 1-10 | ⭐⭐⭐⭐⭐ |
| Gold 🏆 | 11-100 | ⭐⭐⭐⭐ |
| Silver 🥈 | 101-1000 | ⭐⭐⭐ |
| Bronze 🥉 | 1001+ | ⭐⭐ |

### Tier Promotion/Demotion

Promotions occur when:
- Rank improves enough to cross tier boundary (e.g., rank 11 → rank 10)
- User receives "Tier Promotion" notification with visual celebration

Demotions occur when:
- Rank declines enough to cross tier boundary (e.g., rank 10 → rank 11)
- User receives "Tier Demotion" notification

Example:
```dart
final notification = RankingChangeNotification(...);
if (notification.isTierPromotion) {
  // Show celebration animation
  showTierPromotionDialog();
} else if (notification.isTierDemotion) {
  // Show decline message
  showTierDemotionMessage();
}
```

## Usage Examples

### Display User's Current Rank

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final position = ref.watch(
    userRankingPositionProvider('user-123')
  );

  return position.when(
    data: (ranking) => Text(
      'Rank: ${ranking?.globalRank ?? "N/A"}',
      style: TextStyle(
        color: _tierColor(ranking?.tier),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    loading: () => CircularProgressIndicator(),
    error: (err, stack) => Text('Error: $err'),
  );
}

Color _tierColor(RankingTier? tier) {
  switch (tier) {
    case RankingTier.platinum:
      return Colors.blue;
    case RankingTier.gold:
      return Colors.amber;
    case RankingTier.silver:
      return Colors.grey;
    case RankingTier.bronze:
      return Colors.brown;
    case null:
      return Colors.grey;
  }
}
```

### Display Global Leaderboard (Paginated)

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final page = ref.watch(
    leaderboardPageProvider((pageSize: 20, pageIndex: 0))
  );

  return page.when(
    data: (entries) => ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          leading: Text('${entry.rank}'),
          title: Text(entry.displayName),
          subtitle: Text('${entry.level} Level • ${entry.totalXp} XP'),
          trailing: Chip(label: Text(entry.tier.name)),
        );
      },
    ),
    loading: () => CircularProgressIndicator(),
    error: (err, stack) => Text('Error: $err'),
  );
}
```

### Handle Ranking Change Notifications

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final notifications = ref.watch(rankingNotificationsProvider);
  final unreadCount = ref.watch(unreadNotificationCountProvider);

  return Stack(
    children: [
      // Main content
      Scaffold(...),
      
      // Notification badge
      if (unreadCount > 0)
        Positioned(
          top: 16,
          right: 16,
          child: Badge(
            label: Text('$unreadCount'),
            child: FloatingActionButton(
              onPressed: () => _showNotifications(context, ref),
              child: Icon(Icons.notifications),
            ),
          ),
        ),
    ],
  );
}

void _showNotifications(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(leaderboardProvider.notifier);
  final notifications = ref.watch(rankingNotificationsProvider);

  showModalBottomSheet(
    context: context,
    builder: (context) => ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return ListTile(
          title: Text(
            notif.isTierPromotion ? '🎉 Tier Promotion!' : '😢 Tier Demotion',
          ),
          subtitle: Text(
            'Rank ${notif.previousRank} → ${notif.currentRank}',
          ),
          trailing: notif.isRead ? null : Chip(label: Text('New')),
          onTap: () async {
            await notifier.markNotificationAsRead(notif.notificationId);
          },
        );
      },
    ),
  );
}
```

### Generate Category Rankings

```dart
Future<void> _loadCategoryRankings(
  BuildContext context, 
  WidgetRef ref,
  LearningCategory category,
) async {
  final notifier = ref.read(leaderboardProvider.notifier);
  
  try {
    final leaderboard = await notifier.generateGlobalLeaderboard(
      timeUnit: LeaderboardTimeUnit.allTime,
    );
    
    final categoryEntries = leaderboard.categoryRankings[category] ?? [];
    
    // Display category-specific rankings
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${category.name} Rankings'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: categoryEntries.length,
            itemBuilder: (context, index) {
              final entry = categoryEntries[index];
              return ListTile(
                leading: Text('${entry.rank}'),
                title: Text(entry.displayName),
                subtitle: Text('${entry.accuracy.toStringAsFixed(1)}% accuracy'),
              );
            },
          ),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## Integration with Other Systems

### With Multiplayer System

The leaderboard system pulls ranking data from:
- **User profiles**: Level, XP, and match statistics from `MultiplayerUserProfile`
- **Match results**: Win/loss records and streaks from `MatchResult`
- **Live notifications**: Immediate rank updates after match completion

Example flow:
```
User Completes Match
  ↓
MatchResult recorded in multiplayerProvider
  ↓
learningAnalyticsProvider updates user XP
  ↓
leaderboardProvider recalculates global rankings
  ↓
getUserRankingPosition() detects rank change
  ↓
RankingChangeNotification created
  ↓
UI displays notification + updates leaderboard view
```

### With Learning Analytics System

The leaderboard system uses:
- **Category accuracy**: From `OverallLearningProgress.categoryStats`
- **Quiz completion data**: For category-specific rankings
- **Learning milestones**: Trigger leaderboard refresh

## Ranking Calculation Algorithm

### Global Rank Calculation

1. **Score Aggregation** (by TimeUnit):
   - XP contribution: 40%
   - Win rate: 30%
   - Accuracy: 20%
   - Streak bonus: 10%

2. **Final Score**: `score = (xp * 0.4) + (winRate * 30) + (accuracy * 20) + (streak * 10)`

3. **Sorting**: Users sorted by score descending
   - Ties broken by most recent XP gain
   - Secondary tie-break: user ID (alphabetical)

4. **Rank Assignment**: Sequential rank 1-N assigned to sorted users

### Category Rank Calculation

1. **Category-Specific Score**:
   - Accuracy: 60%
   - Quizzes completed: 30%
   - Consistency: 10% (completion frequency)

2. **Sorting & Ranking**: Same tie-breaking rules as global ranks

## Performance Considerations

### Caching Strategy

- **Leaderboard cache**: 5-minute TTL (recalculated periodically)
- **User position cache**: Per-user, 1-minute TTL
- **Notification cache**: Last 100 notifications in memory
- **Persistent cache**: SharedPreferences for offline access

### Pagination Benefits

- **Page size 20-50**: Optimal for mobile display
- **Lazy loading**: Only fetch visible pages
- **Infinite scroll**: Load next page on demand
- **Memory efficient**: Don't hold entire leaderboard in memory

### Optimization Techniques

1. **Incremental updates**: Only recalculate affected user's rank
2. **Batch operations**: Update multiple user ranks together
3. **Background calculation**: Generate rankings offline, serve cached results
4. **Regional filtering**: Calculate per-region to reduce dataset size

## Testing

### Test Coverage

See `test/models/leaderboard_test.dart`:
- Enum value verification
- Tier calculation correctness
- JSON serialization/deserialization
- Ranking tier boundary testing
- Notification creation and properties

See `test/providers/leaderboard_provider_test.dart`:
- Leaderboard generation
- User position retrieval
- Ranking change detection
- Notification state management
- Pagination functionality
- Local data persistence
- Error handling

### Running Tests

```bash
# Run all leaderboard tests
flutter test test/models/leaderboard_test.dart test/providers/leaderboard_provider_test.dart

# Run with coverage
flutter test --coverage test/models/leaderboard_test.dart test/providers/leaderboard_provider_test.dart
```

## Future Enhancements

### Planned Features

1. **Regional Leaderboards**: Separate rankings by geographic region (Japan, Asia, global)
2. **Seasonal Leaderboards**: Reset rankings monthly/quarterly with seasonal rewards
3. **Friend Leaderboards**: Show friends' positions relative to user
4. **Leaderboard Badges**: Special achievements for consistent top placements
5. **Predictive Ranking**: Show projected rank based on current trajectory
6. **Replay Analysis**: View leaderboard snapshots from past time periods
7. **Leaderboard Customization**: Users can choose ranking criteria preferences

### Advanced Features

1. **ELO Rating System**: Chess-style rating calculations for competitive balance
2. **Win Probability**: Calculate chance to beat specific opponents
3. **Historical Trends**: Chart user's rank over time
4. **Performance Streaks**: Track best/worst performing periods
5. **Comparisons**: "You're in top 1.5%" type analytics

## API Reference

### LeaderboardNotifier Methods

#### generateGlobalLeaderboard

Generates complete leaderboard for specified time unit.

```dart
Future<LeaderboardData> generateGlobalLeaderboard({
  required LeaderboardTimeUnit timeUnit,
  int limit = 100,
})
```

**Parameters:**
- `timeUnit`: Filter rankings by time period
- `limit`: Number of top entries to generate (default: 100)

**Returns:** `LeaderboardData` with global and category rankings

**Throws:** Exception if generation fails

#### getUserRankingPosition

Retrieves a specific user's ranking position.

```dart
Future<UserRankingPosition> getUserRankingPosition(
  String userId,
  {required LeaderboardTimeUnit timeUnit}
)
```

**Parameters:**
- `userId`: Target user's ID
- `timeUnit`: Ranking time period

**Returns:** `UserRankingPosition` with current and previous rank

**Throws:** Exception if user not found in rankings

#### getLeaderboardPage

Retrieves paginated leaderboard entries.

```dart
Future<List<GlobalLeaderboardEntry>> getLeaderboardPage({
  required int pageSize,
  required int pageIndex,
  LeaderboardRegion region = LeaderboardRegion.global,
})
```

**Parameters:**
- `pageSize`: Entries per page (typically 20-50)
- `pageIndex`: Zero-based page number
- `region`: Geographic region filter

**Returns:** List of `GlobalLeaderboardEntry` for page

#### markNotificationAsRead

Marks a ranking change notification as read.

```dart
Future<void> markNotificationAsRead(String notificationId)
```

**Parameters:**
- `notificationId`: Notification ID to mark as read

---

**Last Updated**: 2026-09-01  
**Version**: 1.0.0  
**Related Documentation**: [MULTIPLAYER.md](MULTIPLAYER.md), [LEARNING_ANALYTICS.md](../docs/LEARNING_ANALYTICS.md)
