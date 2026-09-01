# Social/Friend System Documentation

## Overview

The Social/Friend System enables users to connect with other learners, create competitive challenges, and view activity feeds of their friends. This feature enhances the learning experience through social engagement and friendly competition.

## Features

### 1. Friend Management
- Add and remove friends
- Accept or reject friend requests
- Block/unblock users
- View online status of friends
- Track friend levels and XP

### 2. Friend Requests
- Send friend requests with custom messages
- Track pending requests
- Mark requests as read
- Accept or reject requests

### 3. Friend Challenges
- Create competitive challenges with friends
- Track progress towards challenge goals
- Determine challenge winners
- Set challenges to expire after 7 days
- Challenge can be on any metric (quizzes, XP, etc.)

### 4. Activity Feed
- Track friend activities (level ups, quiz completions, badge unlocks)
- View personalized activity feeds
- Historical record of friend achievements
- Real-time notifications of friend activities

### 5. Online Status
- Track whether friends are online, away, or offline
- Update status in real-time
- See last seen time

## Data Models

### Friend
```dart
Friend(
  userId: 'user-123',
  username: 'john_doe',
  displayName: 'John Doe',
  profileImageUrl: 'https://...',
  level: 5,
  totalXp: 2500,
  lastSeenAt: DateTime.now(),
  onlineStatus: UserOnlineStatus.online,
  status: FriendshipStatus.accepted,
  connectedAt: DateTime.now(),
  blockedAt: null,
)
```

**Properties:**
- `isActive`: Returns true if friendship status is accepted (not blocked/rejected)
- `isBlocked`: Returns true if user is blocked

**Friend Status Values:**
- `pending`: Awaiting acceptance
- `accepted`: Active friendship
- `blocked`: User has blocked this friend
- `rejected`: Request was rejected

**Online Status Values:**
- `online`: Currently active
- `away`: Away/idle
- `offline`: Not currently connected

### FriendRequest
```dart
FriendRequest(
  requestId: 'req-123',
  senderId: 'user-1',
  senderUsername: 'jane_doe',
  recipientId: 'user-2',
  message: 'Let\'s study together!',
  sentAt: DateTime.now(),
  isRead: false,
)
```

### ActivityFeed
```dart
ActivityFeed(
  activityId: 'act-123',
  userId: 'user-1',
  activityType: 'level_up',
  description: 'Reached Level 6',
  relatedUserId: 'user-2',
  createdAt: DateTime.now(),
)
```

**Activity Types:**
- `level_up`: Friend reached new level
- `quiz_complete`: Friend completed quizzes
- `badge_unlock`: Friend unlocked a badge
- `friend_request_sent`: Friend request sent
- `friend_accepted`: Friend request accepted
- `challenge_created`: Challenge created
- `challenge_completed`: Challenge completed

### FriendChallenge
```dart
FriendChallenge(
  challengeId: 'fc-123',
  initiatorId: 'user-1',
  challengedId: 'user-2',
  description: 'Solve 20 quiz questions first',
  targetAmount: 20,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(Duration(days: 7)),
  initiatorProgress: 15,
  challengedProgress: 12,
  isCompleted: false,
)
```

**Properties:**
- `isActive`: Returns true if challenge hasn't expired
- `initiatorWon`: Returns true if initiator has more progress

## State Management

### SocialState
The main state container for the social system:

```dart
SocialState(
  friends: [],
  pendingRequests: [],
  activeChallenges: [],
  activityFeed: [],
  friendsMap: {},
  isLoading: false,
  error: null,
  lastUpdatedAt: null,
)
```

### SocialNotifier
Main state notifier for managing social operations:

```dart
// Load all social data for a user
await notifier.loadFriendsData(userId);

// Send friend request
await notifier.sendFriendRequest(
  senderId,
  senderUsername,
  recipientId,
  message,
);

// Accept friend request
await notifier.acceptFriendRequest(requestId, friendUserId);

// Reject friend request
await notifier.rejectFriendRequest(requestId);

// Block user
await notifier.blockUser(friendUserId);

// Unblock user
await notifier.unblockUser(friendUserId);

// Create friend challenge
await notifier.createFriendChallenge(
  initiatorId,
  challengedId,
  description,
  targetAmount,
);

// Update challenge progress
await notifier.updateChallengeProgress(
  challengeId,
  userId,
  newProgress,
);

// Update friend's online status
await notifier.updateFriendOnlineStatus(
  friendUserId,
  UserOnlineStatus.online,
);

// Get active (non-blocked) friends
List<Friend> activeFriends = notifier.getActiveFriends();

// Get online friends
List<Friend> onlineFriends = notifier.getOnlineFriends();

// Get pending friend requests
List<FriendRequest> pending = notifier.getPendingRequests();

// Get active challenges
List<FriendChallenge> challenges = notifier.getActiveChallenges();

// Get recent activity (limited to N items)
List<ActivityFeed> recent = notifier.getRecentActivity(limit: 20);

// Get activity for specific friend
List<ActivityFeed> friendActivity = notifier.getActivityForFriend(friendUserId);
```

## Providers

### Main Provider
```dart
final socialProvider = StateNotifierProvider.autoDispose<SocialNotifier, SocialState>
```

### Family Providers (with parameters)
```dart
// Get activity for specific friend
final friendActivityProvider = Provider.autoDispose.family<List<ActivityFeed>, String>
```

### Watch Providers
```dart
// Active (non-blocked) friends
final activeFriendsProvider = Provider.autoDispose<List<Friend>>

// Online friends
final onlineFriendsProvider = Provider.autoDispose<List<Friend>>

// Pending friend requests
final pendingRequestsProvider = Provider.autoDispose<List<FriendRequest>>

// Active friend challenges
final activeChallengesProvider = Provider.autoDispose<List<FriendChallenge>>

// Recent activities
final recentActivityProvider = Provider.autoDispose<List<ActivityFeed>>

// All social data aggregated
final socialDataProvider = Provider.autoDispose<SocialData>
```

## Usage Examples

### Loading Friends
```dart
final container = ProviderContainer();
final notifier = container.read(socialProvider.notifier);
await notifier.loadFriendsData('user-123');
final state = container.read(socialProvider);
```

### Sending Friend Request
```dart
await notifier.sendFriendRequest(
  'user-1',
  'john_doe',
  'user-2',
  'Let\'s study programming together!',
);
```

### Creating Friend Challenge
```dart
await notifier.createFriendChallenge(
  'user-1',
  'user-2',
  'Quiz Challenge: First to 20 correct answers wins!',
  20,
);
```

### Monitoring Progress
```dart
// Update your progress
await notifier.updateChallengeProgress(
  'challenge-123',
  'user-1',
  15,
);

// Check if you won
final challenge = container.read(socialProvider).activeChallenges[0];
if (challenge.initiatorWon) {
  print('You won the challenge!');
}
```

## Performance Considerations

1. **Caching**: Uses `friendsMap` for O(1) lookups by user ID
2. **Limiting**: Activity feed and completion history limited to 100 items
3. **Local Persistence**: SharedPreferences stores last update time for offline support
4. **Auto Disposal**: Providers use `autoDispose` to clean up when no longer watched

## Security Considerations

1. **Blocking**: Prevents blocked users from viewing activity or sending challenges
2. **Request Verification**: Validates sender and recipient before processing requests
3. **Status Validation**: Only active friends can be challenged
4. **Read Tracking**: Maintains `isRead` flag for requests to track notifications

## Integration with Other Systems

- **Learning Analytics**: Tracks friend progress and activity metrics
- **Badge System**: Activity feed includes badge unlock events
- **Challenge System**: Friend challenges complement regular challenges
- **Leaderboard System**: Friends appear with their ranking information

## Testing

Comprehensive test files included:
- `test/models/social_test.dart`: Model serialization and properties
- `test/providers/social_provider_test.dart`: State management and business logic

Run tests with:
```bash
flutter test test/models/social_test.dart
flutter test test/providers/social_provider_test.dart
```

## Future Enhancements

1. **Messages**: Direct messaging between friends
2. **Friend Groups**: Create study groups
3. **Guilds**: Large communities with roles and permissions
4. **Tournaments**: Multi-player competitions
5. **Gift System**: Send badges and rewards to friends
6. **Activity Notifications**: Real-time push notifications
7. **Friend Suggestions**: ML-based friend recommendations
