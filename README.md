# Huddle

A family communication iOS app built with SwiftUI and Firebase. Huddle lets families stay connected through a shared feed, shopping list, pinned messages, and a home screen widget.


---
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 49 31 PM" src="https://github.com/user-attachments/assets/eded044a-2f0b-42e7-830b-3921591914f7" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 50 24 PM" src="https://github.com/user-attachments/assets/029a3761-aa4e-46ec-82a0-3e58eca4daf2" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 50 53 PM" src="https://github.com/user-attachments/assets/43ca4167-b734-4f62-8934-79c9f6b5b60b" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 51 08 PM" src="https://github.com/user-attachments/assets/8b5477ea-fb78-4c86-a919-ccc4826b7fbf" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 51 17 PM" src="https://github.com/user-attachments/assets/6d627051-6a3b-4dcf-b31c-64f0642e93f9" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 52 29 PM" src="https://github.com/user-attachments/assets/7c650211-6c75-492f-8bce-2a594692ad5d" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 53 48 PM" src="https://github.com/user-attachments/assets/6e107866-4c00-4cf1-b9a1-e021b7ae5f51" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 53 54 PM" src="https://github.com/user-attachments/assets/79e8f60b-21c5-4832-a43a-030cee7b279d" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 54 19 PM" src="https://github.com/user-attachments/assets/b2f73763-ea12-4ca7-9155-ff04e1ffd500" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 54 41 PM" src="https://github.com/user-attachments/assets/a89304b7-2a54-435f-9ff1-aa815fb4d106" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 56 15 PM" src="https://github.com/user-attachments/assets/5ed4a2f0-baf8-49db-ad09-bc2b203b4bcf" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 56 32 PM" src="https://github.com/user-attachments/assets/2f8bac06-6e9a-4d45-8ded-c4d9b2ba318e" />
<img width="401" height="866" alt="Screenshot 2026-04-13 at 10 59 55 PM" src="https://github.com/user-attachments/assets/63ed8055-b4da-4042-9eb1-17912a1cd9ae" />

---

## Features

- **Anonymous sign-in** — no email or password required, just a display name
- **Family rooms** — create a family and share a 6-digit code (e.g. `H-123456`) for others to join
- **Family feed** — real-time chat with pin and delete support
- **Pinned messages** — important messages stay visible at the top of the feed
- **Shopping list** — shared list with add, complete, and delete actions
- **Home screen widget** — shows pinned messages and shopping items in small and medium sizes
- **Deep linking** — `huddle://shopping` opens the shopping list directly from the widget

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Architecture | MVVM |
| Auth | Firebase Anonymous Auth |
| Database | Cloud Firestore |
| Widget | WidgetKit |
| Data sharing | App Groups (`group.huddle.shared`) |
| Language | Swift 6 |
| Platform | iOS 17+ |

---

## Project Structure

```
Huddle/
├── HuddleApp.swift              # App entry point, Firebase setup, deep link handler
│
├── models/
│   ├── AppUser.swift            # Authenticated user (id, displayName, currentFamilyId)
│   ├── Family.swift             # Family room (name, code, members)
│   ├── Member.swift             # Family member (id, displayName, joinedAt)
│   ├── HuddleMessage.swift      # Message model (text, photo, shopping types)
│   └── Extensions.swift         # Color+hex helper for brand colors
│
├── services/
│   ├── AuthService.swift        # Firebase Auth — sign in, profile fetch, sign out
│   ├── FamilyService.swift      # Firestore — create, join, fetch family
│   └── MessageService.swift     # Firestore — send, listen, pin, delete messages
│
├── viewmodels/
│   ├── RootViewModel.swift      # Controls name input sheet visibility
│   ├── CreateFamilyViewModel.swift  # Handles family creation flow
│   ├── JoinFamilyViewModel.swift    # Handles family join flow + code validation
│   ├── FamilyFeedViewModel.swift    # Feed, messages, shopping, pins
│   └── ShoppingListViewModel.swift  # Shopping list CRUD with optimistic updates
│
├── views/
│   ├── RootView.swift           # Auth gate — routes to Welcome, CreateJoin, or Feed
│   ├── WelcomeView.swift        # Landing screen with Get Started button
│   ├── NameInputView.swift      # Bottom sheet for entering display name
│   ├── CreateJoinFamily.swift   # Choice screen — create or join
│   ├── CreateFamily.swift       # Family creation form
│   ├── JoinFamily.swift         # Family join form with code input
│   ├── familyFeed.swift         # Main feed — messages, shopping preview, pinned
│   ├── ExpandedChat.swift       # Full-screen chat view
│   ├── ShoppingList.swift       # Shopping list sheet
│   └── ContentView.swift
│
HuddleWidget/
│   ├── HuddleWidget.swift       # Widget views (small + medium)
│   ├── HuddleWidgetBundle.swift # Widget bundle entry
│   ├── HuddleWidgetControl.swift
│   └── SharedDataManager.swift  # App Group bridge for widget data
│
HuddleTests/
│   └── HuddleTests.swift        # Unit + performance tests (XCTest)
│
HuddleUITests/
│   ├── HuddleUITests.swift      # UI tests + launch performance
│   └── HuddleUITestsLaunchTests.swift
```

---

## Architecture

Huddle follows **MVVM**. Views own no business logic — they bind to `@ObservableObject` view models which call service classes for all Firebase operations.

```
View  →  ViewModel  →  Service  →  Firebase
              ↑
        @Published state
```

Data flow for the family feed:

1. `FamilyFeedViewModel.loadMessages()` attaches a Firestore real-time listener
2. New messages arrive via the listener callback and update `@Published var messages`
3. `FamilyFeedView` re-renders automatically
4. On `onDisappear`, `cleanup()` removes the listener to avoid memory leaks

---

## Family Code Format

Family codes follow the format `H-XXXXXX` where X is a digit (0–9).

- Always 8 characters total
- Prefix is always `H-`
- 6 random digits generated server-side
- Collision-checked before saving to Firestore

Validation logic (in `JoinFamilyViewModel`):
```swift
code.count == 8 &&
code.hasPrefix("H-") &&
code.dropFirst(2).allSatisfy { $0.isNumber }
```

---

## Widget

The widget reads data written by the main app via **App Groups** (`group.huddle.shared`).

- Main app writes pinned messages and shopping items to `UserDefaults(suiteName:)` after every Firestore fetch
- Widget reads from the same shared `UserDefaults` on each timeline refresh
- Widget refreshes every **15 minutes**
- Supports **small** (pinned messages or shopping) and **medium** (both columns) sizes
- Deep link targets: `huddle://open` and `huddle://shopping`

---

## Testing

Tests are written with **XCTest** and live in the `HuddleTests` target.

Run all tests: **Cmd+U** in Xcode

### Unit Tests

| Suite | What's covered |
|---|---|
| `ModelTests` | `AppUser`, `Member`, `Family`, `HuddleMessage` — creation, property access, mutations |
| `CodeValidationTests` | `isValidCode` and `formatFamilyCode` — valid codes, too short/long, wrong prefix, non-digits, truncation |
| `InputGuardTests` | `isCreateButtonDisabled`, empty/whitespace content guards for shopping items |
| `ColorExtensionTests` | Hex color parsing for all brand colors |

### Performance Tests

Run via `measure {}` — each test runs the operation 5 times and reports average + standard deviation.

| Test | What it measures |
|---|---|
| `testMessageCreationPerformance` | Creating 1,000 messages |
| `testPinnedMessageFilterPerformance` | Filtering 1,000 messages for pinned |
| `testShoppingItemFilterPerformance` | Filtering 1,000 messages by type |
| `testMessageSortByDatePerformance` | Sorting 1,000 messages by date |
| `testShoppingItemTogglePerformance` | Toggling completion on 500 items |
| `testFamilyWithLargeMemberListPerformance` | Building a family with 500 members |
| `testColorHexParsingPerformance` | 6,000 hex color parses |
| `testMemberDictionarySerializationPerformance` | 500 member → Firestore dictionary conversions |

### UI Tests

| Test | Result |
|---|---|
| `testExample` | App launches and renders without crash |
| `testLaunchPerformance` | Average launch time measured across 5 runs |

---

## Performance Optimization

### Launch Time

**Problem:** On first profiling, average app launch was ~9.7 seconds (simulator).

**Root cause:** `AuthService.fetchUserProfile()` made a single Firestore **server** fetch on every launch, blocking the auth state update until the network round-trip completed.

**Fix:** Cache-first fetch strategy in `AuthService.fetchUserProfile()`:

```
Before:  launch → wait for server response → update UI
After:   launch → read cache instantly → update UI
                  ↓ (background)
                  fetch server → update if changed
```

The app now reads the user profile from Firestore's local cache immediately on launch, restoring the authenticated state in milliseconds. The server fetch still runs in the background to pick up any changes made on other devices.

**Result:**

| | Before | After |
|---|---|---|
| Average launch | ~9.7s | **2.4s** |
| Std deviation | — | 3.4% |
| Improvement | — | **~4x faster** |

---

## Setup

1. Clone the repo
2. Add your `GoogleService-Info.plist` to the `Huddle` target (not included in source control)
3. Enable the **App Group** `group.huddle.shared` in both the Huddle and HuddleWidget targets in Xcode → Signing & Capabilities
4. Open `Huddle.xcodeproj` and run on a simulator or device

> Firebase Anonymous Auth and Firestore must be enabled in your Firebase console.

---

## Brand Colors

| Name | Hex |
|---|---|
| `huddleCoral` | `#FF9B85` |
| `huddlePeach` | `#FFD6A5` |
| `huddleBlue` | `#A8DADC` |
| `huddleBackground` | `#FFF8F3` |

---

## Author

Shalinth Adithyan
