# CLAUDE.md

Engineering conventions for this repository. Read before making changes.

## What this is

Nudge — a native iOS screen-time app that intercepts compulsive app use and offers a
guided "escape protocol" instead of a bare lock screen.

Product spec, acceptance criteria and open questions: **[docs/SPEC.md](docs/SPEC.md)**.
Treat it as the source of truth for behaviour. If an implementation would contradict it,
say so rather than quietly diverging.

## Current state

Foundations complete. All six targets build; the app shell runs. No features yet, and
the extensions are still Apple's unmodified templates.

```
Nudge/                 app target (synchronized folder — files on disk are compiled
                       automatically, no project edits needed to add one)
NudgeMonitor/          DeviceActivityMonitor extension    app.nudge.NudgeMonitor
NudgeShield/           ShieldConfiguration extension      app.nudge.NudgeShield
NudgeShieldAction/     ShieldAction extension             app.nudge.NudgeShieldAction
Packages/NudgeCore/    extension-safe: domain, persistence, clock, Screen Time
                       abstraction. Zero dependencies, no SwiftUI.
Packages/DesignSystem/ app-only: tokens, components, gallery. SwiftUI.
```

All four runnable targets carry the `group.app.nudge` App Group and Family Controls
entitlements. `NudgeTests/AppGroupTests.swift` guards this at runtime — if the App
Group is ever dropped from a target, those tests fail loudly instead of the app
silently losing sight of its extensions.

The app shell is in `Nudge/App/`: `CompositionRoot` builds the object graph at launch,
`AppRouter` owns a typed `NavigationStack` path, and `Route(deepLink:)` parses the
`nudge://` scheme. `CompositionRoot` currently always builds `FakeScreenTimeService` —
swapping in the live one is a change to a single function.

No `DEVELOPMENT_TEAM` is set yet, so device builds are not yet possible.

## Build & verify

```bash
xcodebuild -scheme Nudge -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme Nudge -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Always build after a change. Swift 6 concurrency errors are much easier to resolve one
at a time than twenty at once.

## Architecture

**MVVM with `@Observable`**, feature-first organisation, local Swift Package Manager
modules under `Packages/` for real boundaries.

- Views are dumb. No business logic, no networking, no persistence in a `View`.
- ViewModels are `@Observable` classes holding screen state and coordinating work.
- Prefer fine-grained properties on a ViewModel over one bundled `state` enum —
  Observation tracks dependencies per property, so a single blob invalidates everything.
- Domain logic that can be pure **must** be pure: free functions or plain types with no
  dependencies. This is where the tests live.
- Protocols at boundaries worth faking: network, device APIs, persistence, and anything
  non-deterministic (clock, UUID, randomness). Not at every layer.
- No DI container. Constructor injection, wired in a composition root.
- Layer a feature only where it earns it. A thin settings screen does not need
  `Domain/`, `Data/` and `Presentation/` folders. Asymmetry here is deliberate.

## Swift conventions

- **Swift 6 language mode, strict concurrency.** Do not silence errors with
  `@unchecked Sendable` or `nonisolated(unsafe)` to make something compile — fix the
  actual data flow, or stop and explain the tradeoff.
- `async`/`await` and `throws` for errors. No `Result`-returning async APIs, no
  `Either`-style functional error types.
- Value types by default. Reference types only when identity or shared mutation is
  genuinely needed.
- **Never name a type `Task`** — it collides with Swift concurrency's `Task` and poisons
  every file that imports the module. Same caution for `State`, `Result`, `Error`.
  Use `ResetTask`, `ProtocolStep`, etc.
- Anything a package exposes to the app must be `public`. SPM defaults to `internal`
  and this is the most common mistake when extracting a module.
- Read the current time through `AppClock`, never `Date()` directly. (It is `AppClock`
  rather than `Clock` because the standard library already has a `Clock` protocol.)
- **The app target defaults to main-actor isolation**
  (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`), so every type declared in it is
  implicitly `@MainActor`. Mark pure value types `nonisolated` — otherwise they cannot
  be used from a background context, and tests covering them are forced onto the main
  actor for no reason. `Route` is the worked example. The packages do **not** have this
  setting, so `NudgeCore` types are isolation-free already.

## Screen Time API — non-obvious constraints

These are easy to get wrong. Design around them rather than discovering them later.

- **App tokens are opaque.** Selecting apps returns tokens, not bundle IDs or names.
  You cannot learn which app was picked, log it, or send it to a server. Never build a
  feature that assumes app identity is knowable.
- **Extensions are separate targets and separate processes**, running when the app is
  not. They operate under a very tight memory budget (single-digit MB). Keep their
  dependencies minimal — never import a heavy module into an extension.
- **The lock screen is a `ShieldConfiguration` extension** and supports only: a
  background colour or blur, one icon, a title, a subtitle, and up to two buttons with
  configurable labels and colours. Arbitrary layout is not possible.
- **`DeviceActivityReport` is sandboxed** — it renders SwiftUI and cannot make network
  calls or pass data back out.
- **Shared state between app and extensions goes through the App Group**
  (`group.app.nudge`). Standard `UserDefaults` is not shared.
- **Threshold detection is not guaranteed to be instant.** Never promise
  to-the-second interruption in UX copy.
- Distribution requires Apple's **Family Controls entitlement**.

## Testing

- **Swift Testing** (`@Test`, `#expect`) for new tests. Not XCTest.
- Pure domain logic ships with tests. Non-negotiable — streak rules, day-state
  precedence and protocol progression are the core of the product.
- Inject a clock rather than reading the current time directly. Midnight rollover and
  streak logic must be testable without waiting.
- Hand-written fakes, not a mocking framework.
- Don't chase coverage on views.

## Design system

`Packages/DesignSystem` — the "Arcade" direction. `Theme.Color`, `Theme.Typography`,
`Theme.Spacing`, `Theme.Radius`, `Theme.Elevation`, `Theme.Motion`, plus button styles
and components. `DesignSystemGallery` renders everything at once.

- **Never hardcode a colour, spacing value, corner radius or font size in a feature.**
  Use tokens. If a token is missing, add it to the design system rather than inlining
  a literal.
- Apply type with `.textStyle(Theme.Typography.bodyM)`, never `.font(...)`.
- `DesignSystem` knows nothing about the domain. `DayCell` takes a presentational
  `DayCellStyle`; mapping `DayState` onto one is the feature layer's job.
- **`DesignSystem` must never be linked by an app extension.** It is SwiftUI-heavy and
  the extensions run under a single-digit-MB budget.

## Localization

Every user-facing string lives in `Nudge/Localizable.xcstrings`.

- SwiftUI extracts `Text("...")` and other `LocalizedStringKey` positions automatically.
- When passing a plain `String` to an API that takes one — `StreakCounter(detail:)`, for
  instance — wrap it: `String(localized: "...")`. It will not be localized otherwise,
  and nothing warns you.
- `xcodebuild` does not write new keys back into the catalog; only Xcode does. If a
  string is missing after a command-line build, add it in Xcode or by hand.

## Commits

Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.

Small, focused commits with real messages. This repository is a portfolio artifact —
the history is part of what's being shown.

**Never add AI attribution to commits or pull requests.** No `Co-Authored-By: Claude`
trailer, no "Generated with Claude Code" line, no tool references in commit messages
or PR descriptions.

## Don't

- Don't add third-party dependencies without asking. The platform covers most of this;
  a dependency needs a justification.
- Don't commit `xcuserdata/`, `DerivedData/` or build output.
- Don't weaken concurrency checking to make something compile.
- Don't add a dependency from `NudgeCore` to anything, or import SwiftUI into it — that
  is what keeps the extensions alive.
- Don't commit unformatted code; `./Scripts/format.sh` before committing (CI lints it).
- Don't implement behaviour that contradicts `docs/SPEC.md` — raise it instead.
