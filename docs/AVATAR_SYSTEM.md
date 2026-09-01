# Avatar System Documentation

## Overview

The Avatar System allows users to customize their profile with different avatar icons. The system includes:

- **4 Default Avatars**: Available to all users without cost
- **4 Premium Avatars**: Available for purchase using in-app coins
- **Avatar Selection**: Users can select their active avatar
- **Purchase Integration**: Seamlessly integrates with the existing coin currency system

## Architecture

### Models

#### `Avatar` (lib/models/avatar.dart)

Represents a single avatar with the following properties:

```dart
class Avatar {
  final String id;              // Unique identifier
  final String name;            // Display name
  final String emoji;           // Emoji representation
  final bool isDefault;         // True for free avatars
  final int price;              // Cost in coins (0 for default)
}
```

### State Management

#### `AvatarState` (lib/providers/avatar_provider.dart)

Holds the complete avatar state:

- `allAvatars`: List of all available avatars (8 total: 4 default + 4 premium)
- `selectedAvatarId`: ID of currently selected avatar
- `ownedAvatarIds`: Set of premium avatars purchased by user

#### `AvatarNotifier` (lib/providers/avatar_provider.dart)

StateNotifier that manages avatar state and operations:

**Key Methods:**
- `initialize()`: Load persisted avatar data from SharedPreferences
- `selectAvatar(avatarId)`: Change the selected avatar
- `purchaseAvatar(avatarId)`: Purchase a premium avatar using coins
- `getAvatarById(id)`: Retrieve avatar by ID
- `isAvatarOwned(id)`: Check if avatar is owned/free

**Storage:**
- Selected avatar ID persisted to `selected_avatar` key
- Owned premium avatar IDs persisted to `owned_avatars` key

### Providers

#### `avatarProvider`

Main Riverpod provider for avatar state:

```dart
final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarState>(...);
```

#### `avatarInitializationProvider`

Future provider that handles async initialization:

```dart
final avatarInitializationProvider = FutureProvider<void>(...);
```

## Default Avatars

| ID | Name | Emoji | Price |
|-------|------------|-------|-------|
| avatar_1 | Ninja | 🥷 | Free |
| avatar_2 | Astronaut | 👨‍🚀 | Free |
| avatar_3 | Scholar | 🧑‍🎓 | Free |
| avatar_4 | Artist | 🎨 | Free |

## Premium Avatars

| ID | Name | Emoji | Price |
|-------|------------|-------|-------|
| avatar_5 | Dragon Master | 🐉 | 200 coins |
| avatar_6 | Golden Guardian | 👑 | 250 coins |
| avatar_7 | Alien Explorer | 👽 | 300 coins |
| avatar_8 | Robot Engineer | 🤖 | 350 coins |

## Usage Examples

### Initialize Avatar System

In your app's main initialization (typically in main.dart or app startup):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  await container.read(avatarInitializationProvider.future);
  
  runApp(const MyApp());
}
```

Or use Riverpod's `FutureProvider` wrapper in a widget:

```dart
class AvatarInitializer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(avatarInitializationProvider).when(
      data: (_) => const MyApp(),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
```

### Display Current Avatar

Use the `AvatarDisplayWidget`:

```dart
AvatarDisplayWidget(
  size: 48.0,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AvatarSelectionScreen()),
  ),
)
```

Or use `AvatarCardWidget` for a larger card display:

```dart
AvatarCardWidget(size: 80.0)
```

### Open Avatar Selection Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AvatarSelectionScreen(
      onAvatarSelected: () {
        // Optional callback when avatar is selected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar updated!')),
        );
      },
    ),
  ),
)
```

### Check Avatar Ownership

```dart
final avatarState = ref.watch(avatarProvider);
final isOwned = avatarState.isAvatarOwned('avatar_5');
```

### Get Available and Purchasable Avatars

```dart
final avatarState = ref.watch(avatarProvider);

// Available to user (free + owned premium)
final available = avatarState.availableAvatars;

// Can be purchased (owned premium not included)
final purchasable = avatarState.purchasableAvatars;
```

## Integration with Coin System

The avatar system automatically integrates with `CoinProvider`:

1. **Purchase Verification**: Checks if user has enough coins before purchase
2. **Coin Deduction**: Automatically deducts coins when avatar is purchased
3. **Persistence**: Purchased avatars are tracked in `CoinState.purchasedItemIds`

### How Purchase Works

```dart
// In AvatarNotifier.purchaseAvatar()
1. Check if avatar is owned → return false if already owned
2. Check if avatar is premium → return false if default
3. Get current coin balance from CoinProvider
4. Verify balance >= avatar.price → return false if insufficient
5. Call coinNotifier.deductCoins(avatar.price)
6. Add avatar ID to ownedAvatarIds
7. Persist to SharedPreferences
8. Return true (success)
```

## File Structure

```
lib/
├── models/
│   └── avatar.dart                    # Avatar model definition
├── providers/
│   └── avatar_provider.dart           # State management
├── screens/
│   └── avatar_selection_screen.dart   # Avatar selection UI
└── widgets/
    └── avatar_display_widget.dart     # Avatar display components

test/
├── models/
│   └── avatar_test.dart               # Avatar model tests
└── providers/
    └── avatar_provider_test.dart      # Avatar state management tests
```

## Testing

### Unit Tests

Test Avatar model and state:

```bash
flutter test test/models/avatar_test.dart
flutter test test/providers/avatar_provider_test.dart
```

### Test Utilities

For testing purposes, use these methods on `AvatarNotifier`:

```dart
// Add premium avatar to owned (simulates purchase)
notifier.addOwnedAvatarForTesting('avatar_5');

// Clear owned avatars
notifier.clearOwnedAvatarsForTesting();
```

## Future Enhancements

1. **Custom Avatars**: Allow users to upload custom avatar images
2. **Avatar Effects**: Add animation/effects to avatars
3. **Avatar Rarity**: Implement rarity levels for premium avatars
4. **Limited Edition**: Time-limited avatars for special events
5. **Avatar Levels**: Unlock avatars through achievements or levels
6. **Avatar Gifts**: Allow users to gift avatars to other users
7. **Seasonal Avatars**: Rotate avatars based on seasons/holidays

## Persistence

- **Storage**: SharedPreferences (key-value local storage)
- **Selected Avatar**: Persisted immediately on selection
- **Owned Avatars**: Persisted when avatar is purchased
- **Data Structure**: Owned avatars stored as JSON array of avatar IDs

## Performance Considerations

- Avatar data is loaded once during app initialization
- Selected avatar is cached in Riverpod state (no repeated reads)
- UI rebuilds only affected widgets when avatar state changes
- Coin deduction is atomic (all-or-nothing operation)

## Error Handling

The system gracefully handles:

- **Invalid Avatar ID**: Returns false or null
- **Insufficient Coins**: Blocks purchase, returns false
- **Already Owned**: Prevents duplicate purchases
- **SharedPreferences Failures**: Logged but doesn't crash app
- **Network Issues**: Coin deduction is local, no network required

## Security Notes

- Avatar purchases are atomic transactions (coin deduction and ownership tracking)
- No server validation required (works offline)
- Avatar data is user-local (no cross-user conflicts)
- SharedPreferences encryption is handled by Flutter framework
