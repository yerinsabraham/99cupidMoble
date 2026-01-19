# Messages Screen: Mock Data to Real Backend Transition Guide

## Current Implementation (Mock Data)

The messages screen currently uses mock data to demonstrate the UI/UX design. This allows you to see and test the interface before connecting to the actual backend.

### Mock Data Toggle
Located in `messages_screen.dart` at line ~26:
```dart
final bool _useMockData = true; // Toggle to see design with mock users
```

**To switch to real data**: Change `true` to `false`

---

## Transition Steps

### Step 1: Switch to Real Data
In `lib/presentation/screens/messages/messages_screen.dart`:
```dart
final bool _useMockData = false; // Switch to real backend data
```

### Step 2: Remove Mock Data (Optional)
Once you confirm real data works, you can remove:
- The `_mockChats` list (lines ~28-85)
- The `_buildMockMessageList()` method (lines ~560-660)

### Step 3: Update Navigation Routes
The mock navigation uses routes like `/chat/mock_1`, `/chat/mock_2`, etc.

**Current mock navigation:**
```dart
context.push('/chat/mock_${mock['id']}');
```

**Real data navigation** (already implemented):
```dart
context.push('/chat/${chat.id}'); // Uses actual Firebase chat ID
```

No code changes needed - the real data path already uses proper chat IDs.

---

## Code Structure for Easy Transition

### Horizontal User Avatars
- **Mock version**: Shows `_mockChats` users
- **Real version**: Shows users from `_getChatsStream()`
- Both use identical UI components

### Message List
- **Mock version**: `_buildMockMessageList()` displays mock data
- **Real version**: `StreamBuilder` displays Firebase data
- Both render identical UI items

### Navigation
- Both versions navigate to `/chat/{chatId}`
- Mock uses `mock_1`, `mock_2`, etc.
- Real uses actual Firebase document IDs
- The chat screen handles both seamlessly

---

## Testing Checklist

Before removing mock data:
- [ ] Verify real chats load from Firebase
- [ ] Test clicking on a chat navigates correctly
- [ ] Confirm horizontal avatar scroll works
- [ ] Check unread indicators display properly
- [ ] Test search functionality
- [ ] Verify timestamps format correctly
- [ ] Test with empty chat list
- [ ] Confirm bottom gradient displays properly

---

## Key Benefits of This Implementation

1. **Zero Breaking Changes**: Switch between mock/real with one boolean
2. **Identical UI**: Both versions render the same design
3. **Easy Testing**: Test UI without backend dependencies
4. **Smooth Migration**: No refactoring needed when switching
5. **Production Ready**: Real implementation already complete

---

## Notes

- The `_useMockData` toggle is at the top of the `_MessagesScreenState` class
- Mock data includes 6 sample users (Jenny, Laurent, Lily, Caroline, Marry Jane, Jennifer)
- The bottom white blur gradient works with both mock and real data
- All navigation routes are compatible with the app's routing system
