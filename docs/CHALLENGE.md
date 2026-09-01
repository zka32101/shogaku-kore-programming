# Challenge & Quest System

Adds daily challenges, weekly quests, and streak mechanics for engagement-driven gamification.

## Features

- **Daily Challenges**: Time-limited learning tasks (easy/medium/hard/expert)
- **Weekly Quests**: Milestone-based challenges with reward progression
- **Challenge Streaks**: Maintain consecutive completions for bonus rewards
- **Bonus System**: Extra XP for category-specific performance
- **Progress Tracking**: Real-time challenge completion with milestone detection

## Architecture

### Data Models (lib/models/challenge.dart)

**Enums:**
- `ChallengeType`: daily, weekly, monthly, special
- `ChallengeDifficulty`: easy, medium, hard, expert
- `ChallengeStatus`: available, inProgress, completed, failed, expired

**Classes:**
- `ChallengeCondition`: Challenge requirements (description, target amount, category)
- `ChallengeReward`: XP/coin rewards with category bonuses
- `Challenge`: Challenge definition with type, difficulty, condition, reward
- `UserChallengeProgress`: User's challenge state (status, progress, attempts)
- `ChallengeCompletion`: Completion record (XP earned, timestamp, bonus status)
- `ChallengeStreak`: Consecutive completion tracking with reset logic
- `ChallengeData`: Aggregated snapshot of all challenge data

### Provider (lib/providers/challenge_provider.dart)

**ChallengeNotifier Methods:**
- `generateDailyChallenges()`: Create day's challenge set
- `startChallenge(userId, challengeId)`: Initialize challenge attempt
- `completeChallenge(userId, challengeId, xp, coins)`: Record completion
- `getActiveChallenges()`: List live challenges
- `getStreakCount(type)`: Retrieve current streak

**Providers:**
- `challengeProvider`: Main state management
- `activeChallengesProvider`: Live challenge list
- `userStreakProvider`: Streak counter (family)
- `dailyChallengesProvider`: Daily challenge data (async)

## Example Usage

```dart
// Start daily challenges
final notifier = ref.read(challengeProvider.notifier);
final dailyChallenges = await notifier.generateDailyChallenges();

// Display active challenges
final active = ref.watch(activeChallengesProvider);
ListView(children: active.map((c) => ChallengeCard(challenge: c)))

// Complete a challenge
await notifier.completeChallenge('user-1', 'ch-1', 100, 50);

// Show streak badge
final streak = ref.watch(userStreakProvider(ChallengeType.daily));
Badge(label: Text('$streak day streak'))
```

## Testing

- 30+ model tests: Challenge types, serialization, status transitions
- 15+ provider tests: Generation, completion, streak tracking
- Full coverage of completion flow and state management

## Integration

- **With Learning Analytics**: Uses quiz completion data for progress
- **With Leaderboard**: Challenge completions contribute to ranking
- **With Achievements**: Daily completions unlock badges
- **With Multiplayer**: Competitive challenges with friend rankings

## Future Enhancements

- Social challenges with friends
- Seasonal events with special quests
- Challenge customization by user preference
- AI-generated personalized challenges
- Challenge streaming and sharing
