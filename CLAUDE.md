# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Prologue is a social reading tracker for iOS (iOS 17+). Users track books across four statuses, log reading progress, discover books via text search and ISBN barcode scanning, connect with friends, and view annual reading stats. Built with SwiftUI + Supabase + Google Books API.

## Build & Test Commands

```bash
# Run unit tests (Swift Testing framework)
xcodebuild test -project Prologue/Prologue.xcodeproj \
  -scheme Prologue \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PrologueTests

# Run UI tests (XCTest, requires simulator)
xcodebuild test -project Prologue/Prologue.xcodeproj \
  -scheme Prologue \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PrologueUITests
```

In Xcode: Cmd+U runs all tests; select a specific target in the test navigator to run one suite.

## Architecture

MVVM with SwiftUI + `@Observable` (iOS 17 Observation framework).

```
PrologueApp.swift
  └─ ContentView             routes between LoginView / AppTabView
       └─ AppTabView         four tabs; loads data in .task
            ├─ LibraryView   + LibraryViewModel
            ├─ SearchView    + SearchViewModel
            ├─ SocialView    + SocialViewModel
            └─ InsightsView  + StatsViewModel
```

Every ViewModel is `@Observable final class` injected via `.environment()`. All UI-mutating methods are `@MainActor`.

## Directory Structure

```
Prologue/Prologue/Prologue/
├── App/ContentView.swift
├── PrologueApp.swift
├── Config/Config.swift          ← reads secrets from Info.plist build vars
├── Models/                      ← Book, UserBook (+ ReadingStatus), Profile, Friendship
├── ViewModels/                  ← Auth, Library, Search, Social, Stats
├── Views/
│   ├── Auth/LoginView.swift
│   ├── Library/                 ← LibraryView (+ ProfileSheet), BookDetailView
│   ├── Search/                  ← SearchView, ISBNScannerView
│   ├── Social/                  ← SocialView, FriendProfileView
│   ├── Insights/InsightsView.swift
│   └── Main/AppTabView.swift
└── Services/                    ← SupabaseManager, AuthService, BookSearchService + Protocols/
```

## SPM Dependencies

| Package | Purpose |
|---|---|
| `supabase-swift` ≥ 2.0 | Postgres client + auth |
| `google-signin-ios` ≥ 7.0 | Google OAuth |
| Swift Charts (system framework) | Reading volume chart in InsightsView |

## Secrets & Config

API keys live in `Config.xcconfig` (gitignored via `*.xcconfig`). `Info.plist` uses build-variable references like `$(SUPABASE_HOST)` — safe to commit.

**xcconfig URL gotcha**: `//` is treated as a comment in xcconfig. Store only the host (`SUPABASE_HOST = foo.supabase.co`) and construct the full URL in `Config.swift`: `URL(string: "https://\(host)")!`.

## Testing Notes

### Unit Tests (PrologueTests — Swift Testing framework)
- `@MainActor` is required on every test suite that instantiates an `@Observable` ViewModel — Swift 6 infers the init as `@MainActor` when the class has `@MainActor` methods.
- `StatsViewModelTests` uses `@Suite(.serialized)` (parent wrapping all nested suites) because `annualGoal` reads/writes `UserDefaults.standard`.
- `BookSearchServiceTests` uses `@Suite(.serialized)` because `MockURLProtocol.requestHandler` is a shared static var.

### UI Tests (PrologueUITests — XCTest)
Two launch-environment modes:

| Variable | Value | Effect |
|---|---|---|
| `UI_TESTING` | `"1"` | `SupabaseManager` uses a placeholder client; no real DB calls |
| `UI_TESTING_AUTHENTICATED` | `"1"` | `ContentView` bypasses the auth check and shows `AppTabView` with empty state; always set alongside `UI_TESTING` |

## Key Auth Decisions

**Nonce flow**: `AuthService` generates a raw nonce, SHA-256 hashes it with CryptoKit, passes the hash to `GIDSignIn` and the raw nonce to Supabase. Supabase re-hashes and compares.

**userID race condition**: `AuthViewModel.userID` returns `currentUser?.id ?? profile?.id`. `currentUser` is set immediately when `refreshSession()` completes; `profile` may still be `nil` if `loadOrCreateProfile` hasn't finished. Always use `authViewModel.userID` in views — never `authViewModel.profile?.id` directly.
