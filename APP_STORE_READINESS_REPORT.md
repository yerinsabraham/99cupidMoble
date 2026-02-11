# 99Cupid — App Store Readiness Report

**Date:** June 2025  
**Scope:** Full end-to-end dating app flow audit + Apple App Store submission readiness  
**Verdict:** ❌ NOT READY — 8 blockers, 12 high-priority issues, 15 medium items

---

## Table of Contents
1. [Complete User Flow Analysis](#1-complete-user-flow-analysis)
2. [How the Backend & Data Models Work](#2-how-the-backend--data-models-work)
3. [How Matching Works](#3-how-matching-works)
4. [Blocker Issues (Must Fix Before Submission)](#4-blocker-issues-must-fix-before-submission)
5. [High Priority Issues](#5-high-priority-issues)
6. [Medium Priority Issues](#6-medium-priority-issues)
7. [Low Priority / Nice-to-Have](#7-low-priority--nice-to-have)
8. [Apple App Store Specific Requirements](#8-apple-app-store-specific-requirements)
9. [What's Working Well](#9-whats-working-well)
10. [Recommended Fix Order](#10-recommended-fix-order)

---

## 1. Complete User Flow Analysis

### The Journey: From Download to First Message

```
📱 App Launch
    │
    ▼
🔄 Splash Screen (2s delay)
    │ Checks: Firebase Auth user → Firestore user doc → profileSetupComplete
    │
    ├── No user → /login
    │       ├── Email + Password login ✅
    │       ├── Google Sign-In ✅
    │       └── Forgot Password ✅
    │
    ├── User exists, no profile → /onboarding/setup
    │       Step 1: Name, Age, Gender, LookingFor, Location, Bio ✅
    │       Step 2: Upload 1-6 photos to Firebase Storage ✅
    │       Step 3: Select 3+ interests → SAVE ALL to Firestore ✅
    │
    └── User exists, profile complete → /home
            │
            ┌───────────────────────────────────────┐
            │          Main Screen (4 Tabs)          │
            ├───────┬───────┬───────────┬────────────┤
            │ Swipe │Matches│ Messages  │  Profile   │
            │ Tab 0 │ Tab 1 │  Tab 2    │  Tab 3     │
            └───┬───┴───┬───┴─────┬─────┴──────┬─────┘
                │       │         │            │
                ▼       ▼         ▼            ▼
           Card Deck  Match    Chat List   Own Profile
           Swipe L/R  Grid    Real-time    View/Edit
                │       │         │
                ▼       │         │
           On Match! ──►├─────────┤
           Dialog       │         │
           "Say Hello"──┼────►Chat Screen
                        │    Send text ✅
                        │    Send image ✅
                        │    Read receipts ✅
                        │    Real-time ✅
```

### Flow Status Summary

| Step | Status | Notes |
|------|--------|-------|
| App launch → auth check | ✅ Working | Splash handles routing correctly |
| Email signup | ✅ Working | Creates Firebase Auth + Firestore user doc |
| Google sign-in | ✅ Working | Auto-creates user doc if missing |
| Email verification | ⚠️ Partial | Sends email but doesn't enforce it before proceed |
| Profile setup (3 steps) | ✅ Working | All data saved to Firestore in one write |
| Photo upload | ✅ Working | Firebase Storage, 1-6 photos |
| Interest selection | ✅ Working | 40 options, min 3 required |
| Profile discovery (swipe deck) | ✅ Working | Loads profiles, applies filters |
| Swipe left (pass) | ✅ Working | Records to `swipes` collection |
| Swipe right (like) | ✅ Working | Records to `likes`, checks mutual |
| Mutual match detection | ✅ Working | Auto-creates match + chat documents |
| Match dialog | ✅ Working | Shows dialog with "Say Hello" → chat |
| Chat messaging | ✅ Working | Real-time Firestore, text + images |
| Matches grid | ✅ Working | Displays all mutual matches |
| Messages list | ✅ Working | Real-time chat list with last message |
| Profile viewing | ✅ Working | Own profile + other user profiles |
| Profile editing | ✅ Working | All fields editable, photo management |
| Settings | ✅ Working | Privacy, notifications, account management |
| Block/Report users | ✅ Working | Block + report with reasons |
| Verification | ⚠️ Partial | Phone uses mock OTP (123456) |
| Admin dashboard | ✅ Working | User management, reports, verifications |
| Account deletion | ⚠️ Partial | Works for email users only, not Google users |
| Push notifications | ❌ Missing | No package installed |
| Subscription/Payment | ❌ Missing | No in-app purchase integration |

---

## 2. How the Backend & Data Models Work

### Firestore Collections

```
📦 Firestore Database (cupid-e5874)
│
├── 👤 users/{uid}
│   ├── Profile: displayName, bio, age, gender, lookingFor, location
│   ├── Photos: photoURL, photos[]
│   ├── Interests: interests[]
│   ├── Verification: isPhoneVerified, isPhotoVerified, isIDVerified
│   ├── Subscription: hasActiveSubscription, subscriptionStatus
│   ├── Safety: blockedUsers[], blockedByUsers[], reportedBy[]
│   └── Meta: isAdmin, accountStatus, createdAt, updatedAt, lastActiveAt
│
├── ❤️ likes/{likeId}
│   └── fromUserId, toUserId, timestamp
│
├── 👈 swipes/{swipeId}
│   └── userId, targetUserId, direction (left/right), timestamp
│
├── 💑 matches/{matchId}
│   ├── user1Id, user2Id
│   ├── user1Name, user2Name, user1Photo, user2Photo
│   ├── matchedAt, chatId (links to chats collection)
│   └── Both users' names & photos denormalized for fast display
│
├── 💬 chats/{chatId}
│   ├── participants[], user1Id, user2Id
│   ├── user1Name, user2Name, user1Photo, user2Photo
│   ├── lastMessage, lastMessageAt
│   ├── unreadCount: { "userId1": 0, "userId2": 0 }
│   └── 📨 messages/{messageId}  (subcollection)
│       ├── chatId, senderId, senderName, senderPhoto
│       ├── text, type (text/image), imageUrl, fileUrl
│       ├── timestamp, read (boolean)
│       └── readBy, readAt (optional)
│
├── ✅ verifications/{verificationId}
│   └── userId, type (phone/photo/id), status, data, timestamps
│
├── 🚨 reports/{reportId}
│   └── reportedUserId, reportingUserId, reason, description, status
│
└── 📊 Cloud Functions (5 deployed)
    ├── onMessageCreated → updates chat lastMessage + unreadCount
    ├── onMessageUpdated → handles read receipt propagation
    ├── markMessagesAsRead → batch marks messages read
    ├── deleteChat → deletes chat + all messages
    └── createChat → creates chat with dedup check
```

### Data Flow Diagram

```
User A likes User B          User B likes User A
       │                            │
       ▼                            ▼
  writes to                    writes to
  likes collection             likes collection
       │                            │
       └──────── mutual? ──────────┘
                    │
                   YES
                    │
                    ▼
         ┌─ Create Chat Doc ─┐
         │  participants: [A,B]│
         │  user names/photos  │
         └─────────┬──────────┘
                   │
                   ▼
         ┌─ Create Match Doc ─┐
         │  user1Id: A         │
         │  user2Id: B         │
         │  chatId: ^^^        │
         └─────────┬──────────┘
                   │
                   ▼
         Match Dialog appears
         "Say Hello" → Chat Screen
                   │
                   ▼
         Send message → messages subcollection
         Cloud Function → updates lastMessage + unreadCount
```

---

## 3. How Matching Works

### Discovery Algorithm (MatchingService)
1. Loads ALL users where `profileSetupComplete == true`
2. Filters out: self, already-swiped users, gender mismatches (mutual preference), age range
3. Scores remaining profiles 0-100 using:
   - Common interests: 40%
   - Age compatibility: 20%
   - Profile completeness: 20%
   - Verification status: 20%
4. Sorts by score, returns top 50

### When Can Users Message Each Other?
**ONLY after a mutual match.** The flow is:
1. User A swipes right → `likes` document created
2. User B swipes right on A → `likes` document created → mutual like detected
3. On mutual like: chat document auto-created, match document auto-created with `chatId`
4. Both users can now see each other in Matches tab and access the shared chat

**Users CANNOT message someone they haven't matched with.** There is no "message request" or pay-to-message feature.

---

## 4. Blocker Issues (Must Fix Before Submission)

These will **cause App Store rejection** or **break core functionality**:

### BLOCKER 1: `read` vs `isRead` Field Name Mismatch
- **Mobile app** writes `read: true/false` on message documents
- **Cloud Functions** (`markMessagesAsRead`) queries `where("isRead", "==", false)` and sets `isRead: true`
- **Result:** Cloud function will NEVER find messages to mark as read. Unread counts won't reset via the batch function.
- **Fix:** Align field names — either update Cloud Functions to use `read` or update `MessageModel` to use `isRead`

### BLOCKER 2: `unreadCount` Type Mismatch in `createMatch()`
- `SwipeService.createMatch()` sets `unreadCount: 0` (an integer)
- `ChatScreen._sendMessage()` does `'unreadCount.$otherUserId': FieldValue.increment(1)` (expects a map)
- **Result:** First message in a new match will crash or fail to update unread count
- **Fix:** Change `createMatch()` to initialize `unreadCount` as `{'$user1Id': 0, '$user2Id': 0}`

### BLOCKER 3: No Push Notifications
- No `firebase_messaging` or `flutter_local_notifications` packages
- Users will NOT know about new messages or matches unless the app is open
- **Apple may reject** a messaging app that can't notify users
- **Fix:** Integrate Firebase Cloud Messaging + local notifications

### BLOCKER 4: No Privacy Policy / Terms of Service
- Settings screen has "Privacy Policy" and "Terms of Service" buttons with `onTap: () {}` — **empty handlers**
- Apple **requires** a functional privacy policy URL during submission
- **Fix:** Create privacy policy document (web page), link from app and App Store listing

### BLOCKER 5: No Account Deletion for Google Sign-In Users
- `UserAccountService.deleteAccount()` uses `EmailAuthProvider.credential()` for re-authentication
- Google sign-in users will get a credential mismatch error and CANNOT delete their accounts
- **Apple requires** account deletion for all users (App Store Review Guideline 5.1.1(v))
- **Fix:** Detect auth provider, use `GoogleAuthProvider` for re-auth, or use Firebase reauthenticateWithProvider

### BLOCKER 6: No Age Verification / 17+ Content Rating
- Dating apps must be rated 17+ on App Store
- No age gate or date-of-birth verification at signup
- The onboarding asks for "age" as a number input — no proof of age
- **Fix:** Add date-of-birth input (not just age number), enforce 18+ at signup

### BLOCKER 7: Mock OTP Still in Verification
- `verification_screen.dart` line 617 still uses `mockOtp = '123456'`
- Any user can verify their phone with "123456" — makes verification meaningless
- **Fix:** Integrate real SMS verification (Firebase Phone Auth, Twilio, etc.) or remove phone verification for now

### BLOCKER 8: No App Store Screenshots / Metadata
- No app icon set (likely using Flutter default)
- Need 6.7" and 6.1" iPhone screenshots
- Need app description, keywords, support URL
- **Fix:** Prepare all App Store Connect metadata

---

## 5. High Priority Issues

These won't cause rejection but will **break user experience**:

### HIGH 1: Matches Screen Full Collection Scan
- `matches_screen.dart` fetches EVERY match document in the entire database, then filters client-side
- With 1000 users making 10 matches each = 10,000 reads per user per visit
- **Fix:** Add `participants` array to match docs, query with `arrayContains`

### HIGH 2: Profile Discovery Loads All Users
- `MatchingService.getMatches()` queries ALL `profileSetupComplete == true` users into memory
- With 10,000 users, this downloads all 10,000 user documents on every swipe deck load
- **Fix:** Server-side filtering with Firestore queries, pagination with cursors

### HIGH 3: Blocked Users Still Appear in Discovery
- `MatchingService` does NOT check `blockedUsers` / `blockedByUsers` arrays
- Blocked users will still show up in the swipe deck
- **Fix:** Add blocked user filtering in `_getSwipedUserIds()` or in the filter step

### HIGH 4: Suspended/Deleted Accounts in Discovery
- `MatchingService` does NOT check `accountStatus`
- Suspended or deleted users appear in the swipe deck
- **Fix:** Add `accountStatus == 'active'` filter

### HIGH 5: UserProfileScreen Like/SuperLike Non-Functional
- When viewing another user's profile (from swipe deck tap), the Like/SuperLike buttons just show a SnackBar
- They do NOT actually record a like in Firestore or check for matches
- **Fix:** Wire up buttons to `SwipeService.likeUser()` with proper match detection

### HIGH 6: No Duplicate Like Prevention
- `SwipeService.likeUser()` has no deduplication check
- Rapid taps could create multiple like documents and potentially multiple match/chat documents
- **Fix:** Check for existing like before writing, or use deterministic document IDs

### HIGH 7: Two Competing Account Deletion Paths
- `AuthService.deleteAccount()` — deletes user doc + auth account but NO related data cleanup
- `UserAccountService.deleteAccount()` — full cleanup (matches, chats, likes, swipes, etc.)
- If the wrong one is called, orphan data remains
- **Fix:** Remove `AuthService.deleteAccount()` or have it delegate to `UserAccountService`

### HIGH 8: No Firebase Analytics or Crashlytics
- No crash reporting — production issues will be invisible
- No usage analytics — can't measure engagement, retention, or conversion
- **Fix:** Add `firebase_analytics` and `firebase_crashlytics` packages

### HIGH 9: Chat Format Inconsistency with Cloud Functions
- `SwipeService.createMatch()` creates chats with `user1Id`, `user2Id` fields
- Cloud Function `createChat` creates chats with `participantNames`, `participantPhotos` maps
- `onMessageCreated` reads `participants` array (present in both formats, so this works)
- **Risk:** If `createChat` cloud function is ever called from mobile, `ChatModel.fromFirestore()` won't find `user1Id`/`user2Id`

### HIGH 10: Onboarding Data Could Be Lost
- Onboarding saves data to a Riverpod provider across 3 screens
- If the user closes the app during onboarding, all accumulated data is lost
- Photos already uploaded to Storage become orphans
- **Fix:** Save progress to Firestore or local storage after each step

### HIGH 11: No Loading / Error States on Swipe Deck
- If `MatchingService.getMatches()` fails, user sees "No more profiles"
- No retry button, no error indication
- **Fix:** Add proper error handling with retry capability

### HIGH 12: Email Verification Not Enforced
- Signup sends verification email but immediately proceeds to onboarding
- Users can use the app with unverified emails
- **Fix:** Add email verification check in splash screen routing or before profile completion

---

## 6. Medium Priority Issues

### MED 1: No Route Guards
- Any deep link can access `/admin`, `/settings`, `/chat/:id` without authentication
- Splash screen handles initial routing, but there's no redirect for invalid direct navigation
- **Fix:** Add `redirect` callback to GoRouter that checks auth state

### MED 2: Most Screens Bypass Riverpod
- Only auth and onboarding screens use Provid providers
- All other screens instantiate services directly and use local state
- Makes testing difficult, state inconsistent, unnecessary Firebase reads
- **Fix:** Create providers for all services, use `ConsumerWidget` consistently

### MED 3: OTP Stored in Plaintext
- Phone verification OTP is stored as-is in Firestore `verifications` collection
- Anyone with database access can see OTPs
- **Fix:** Hash OTPs before storage, or use Firebase Phone Auth

### MED 4: Blocking Doesn't Remove Existing Matches/Chats
- When User A blocks User B, existing matches and chat history remain
- Both users can still see old messages
- **Fix:** Delete or hide matches/chats on block

### MED 5: No Typing Indicators
- Web app's `MessagingService` supports `typingUsers` map on chat docs
- Mobile chat has no typing indicator support
- **Fix:** Add typing status writes and a UI indicator

### MED 6: Super Like = Regular Like
- The super-like button calls the same `_handleSwipe(uid, true)` as regular like
- No distinct logic, notification, or visual on the recipient's side
- **Fix:** Either implement distinct super-like or remove the button

### MED 7: Two Firestore Reads Per Like Swipe
- `_handleSwipe` reads both current and target user docs from Firestore on EVERY like
- Current user data should be cached since it doesn't change during a swipe session
- **Fix:** Cache current user data, pass profile data from the already-loaded card

### MED 8: Incomplete GDPR Data Export
- `UserAccountService.exportUserData()` exists but no UI button to trigger it
- **Fix:** Add "Download My Data" button in Settings

### MED 9: No Image Compression
- Photos are uploaded at original resolution
- Large photos slow down loading and increase storage costs
- **Fix:** Add `flutter_image_compress` package

### MED 10: App Supports Landscape Orientation
- Info.plist allows landscape orientations
- Dating apps typically lock to portrait
- **Fix:** Remove landscape orientations from Info.plist

### MED 11: Liked-AT-User Cleanup on Deletion
- `_deleteUserRelatedData` deletes likes FROM the user (`fromUserId`) but NOT likes directed AT them (`toUserId`)
- **Fix:** Also query and delete `likes` where `toUserId == userId`

### MED 12: Firestore Batch Size Limit
- Account deletion uses a single Firestore batch for all related data
- Batch limit is 500 operations — users with many messages will hit this
- **Fix:** Implement paginated batch deletion

### MED 13: `blockedUsers` Array Size Limit
- Blocked users stored as array on user document
- Firestore documents have 1MB limit; arrays have practical limit ~40,000 entries
- **Fix:** Use a subcollection for blocked users if scale requires it

### MED 14: No Last Active Tracking
- `lastActiveAt` field exists on `UserModel` but is never updated during app usage
- Can't show "Active X minutes ago" accurately
- **Fix:** Update `lastActiveAt` on app foreground / meaningful interactions

### MED 15: Swipe Stats are Placeholder
- Empty state in swipe screen shows `_currentIndex` for both "Liked" and "Viewed" counters
- Not actual lifetime stats
- **Fix:** Track real stats or remove the display

---

## 7. Low Priority / Nice-to-Have

| # | Issue | Notes |
|---|---|---|
| 1 | "Start Swiping" button in empty matches has no `onTap` | Dead UI element |
| 2 | `home_screen.dart` is dead code | Never referenced in router, can delete |
| 3 | Photo "drag to reorder" subtitle exists but no implementation | Remove subtitle or implement |
| 4 | No distance/location-based filtering | Location field exists but no geo-queries |
| 5 | No "undo last swipe" feature | Common in dating apps |
| 6 | No message search within chat | Only chat-list search exists |
| 7 | No video messages | Only text and images supported |
| 8 | No voice messages | Common in modern messaging |
| 9 | No GIF/emoji picker | Standard messaging feature |
| 10 | No "who liked you" screen | Premium feature in most dating apps |

---

## 8. Apple App Store Specific Requirements

### Required for Submission

| Requirement | Status | Action Needed |
|------------|--------|---------------|
| Privacy Policy URL | ❌ Missing | Create and host a privacy policy web page |
| Terms of Service | ❌ Missing | Create ToS document |
| Account Deletion | ⚠️ Partial | Fix for Google sign-in users |
| Age Rating 17+ | ❌ Not set | Set content rating in App Store Connect |
| Age Gate (18+) | ❌ Missing | Add DOB verification at signup |
| App Icons (1024x1024) | ❓ Unverified | Verify proper app icon set |
| Screenshots (6.7", 6.1") | ❌ Missing | Create for iPhone 15 Pro Max + iPhone 15 |
| App Description | ❌ Missing | Write compelling store description |
| Support URL | ❌ Missing | Create support page/email |
| Push Notification Capability | ❌ Missing | Required for messaging apps |
| Sign in with Apple | ❌ Missing | **Required** if you offer Google Sign-In |
| Data Safety / App Privacy | ❌ Missing | Fill out privacy nutrition label |

### Apple Review Guidelines — Dating App Specific

| Guideline | Concern | Status |
|-----------|---------|--------|
| 1.2 User-Generated Content | Must have blocking + reporting | ✅ Done |
| 1.3 Kids Category | Must NOT be in Kids category | ✅ N/A |
| 4.3 Spam | Must have real unique functionality | ✅ Has features |
| 5.1.1(v) Account deletion | Must allow full account deletion | ⚠️ Broken for Google users |
| 5.1.2 Data Use | Privacy policy required | ❌ Missing |
| 5.6.1 App Review | Must provide demo account for review | ❌ Need to prepare |
| **4.0 Design** | Must be polished, no placeholders | ⚠️ Some placeholder elements |
| **Sign in with Apple** | Required when third-party login offered | ❌ Missing |

### Critical: Sign in with Apple
**Apple requires** Sign in with Apple as an option if you offer any third-party login (Google). This is a **hard rejection** if missing. You need to:
1. Add `sign_in_with_apple` package
2. Configure Apple Sign-In capability in Xcode
3. Set up Apple Sign-In in Firebase Console
4. Add UI button on login/signup screens

---

## 9. What's Working Well

| Feature | Assessment |
|---------|------------|
| Firebase Auth (email + Google) | Solid implementation |
| 3-step onboarding flow | Clean, all data saved properly |
| Swipe card interface | Working with proper animations |
| Mutual match detection | Correct logic — creates match + chat atomically |
| Real-time messaging | Firestore streams working, text + images |
| Image upload in chat | Firebase Storage with progress indicators |
| Profile management | Full edit capability with photo management |
| Block & Report system | Complete with reasons |
| Admin dashboard | User management, reports, verifications |
| Verification system | 3-tier (phone/photo/ID) with trust score |
| Security rules | Comprehensive Firestore + Storage rules |
| Cloud Functions | 5 functions deployed and operational |
| Dark theme support | Full themed UI |
| Router architecture | Clean GoRouter setup with path parameters |

---

## 10. Recommended Fix Order

### Phase 1: Critical Blockers (1-2 weeks)
> *Without these, Apple will reject or the app will break*

1. **Fix `read` vs `isRead` mismatch** — Change Cloud Functions to use `read` field
2. **Fix `unreadCount` type in `createMatch()`** — Initialize as map, not integer
3. **Add Sign in with Apple** — Required for App Store
4. **Add Privacy Policy + Terms of Service** — Required for submission
5. **Fix Google account deletion** — Detect provider, use appropriate re-auth
6. **Add age gate (18+ DOB check)** — Required for dating apps
7. **Remove mock OTP** — Either integrate real SMS or remove phone verification
8. **Add push notifications** — Firebase Cloud Messaging + local notifications

### Phase 2: High Priority Fixes (1-2 weeks)  
> *Core UX issues that will cause bad reviews*

9. **Fix matches collection scan** — Add server-side query filtering
10. **Fix profile discovery scalability** — Paginate + server-side filters
11. **Filter blocked/suspended users from discovery**
12. **Wire up UserProfileScreen like/superlike buttons**
13. **Add duplicate like prevention**
14. **Add Firebase Analytics + Crashlytics**
15. **Consolidate account deletion into one path**

### Phase 3: Polish (1 week)
> *Before submission*

16. **Lock to portrait orientation**
17. **Add route guards to GoRouter**
18. **Cache current user data during swipe session**
19. **Prepare App Store screenshots and metadata**
20. **Create demo account for Apple review**
21. **Fill out App Privacy nutrition label**

### Phase 4: Post-Launch Improvements
22. Migrate screens to Riverpod providers consistently
23. Add typing indicators
24. Implement location-based discovery
25. Add subscription/payment system
26. Add image compression
27. Implement "who liked you" premium feature

---

## Final Assessment

**The core dating app flow works end-to-end** — signup, profile setup, swipe, match, and chat are all functional with real Firebase data. The architecture is sound and the UI is themed properly.

**However, the app has 8 blocking issues** that will cause either App Store rejection or critical runtime failures. The most urgent are:
1. **Sign in with Apple** (instant rejection without it)  
2. **Privacy Policy** (instant rejection without it)  
3. **`unreadCount` type mismatch** (breaks first message in every new chat)
4. **Push notifications** (messaging app without notifications is unusable)

**Estimated timeline to App Store ready: 3-5 weeks** following the phased approach above.
