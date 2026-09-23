# Architecture

Structural reference for the Nudge iOS application. Describes the process model,
module graph, dependency rules and subsystem contracts. Product behaviour is
specified separately in [SPEC.md](SPEC.md); day-to-day conventions are in
[../CLAUDE.md](../CLAUDE.md).

---

## 1. Process model

The application is distributed as a single `.app` bundle containing three app
extensions. Each extension is an independent executable that the system launches in
its own process, in response to a system event, generally while the containing
application is not running.

| Target | Bundle identifier | Type | Launched by |
|---|---|---|---|
| `Nudge` | `app.nudge` | Application | User |
| `NudgeMonitor` | `app.nudge.NudgeMonitor` | `DeviceActivityMonitor` extension | Usage threshold crossed |
| `NudgeShield` | `app.nudge.NudgeShield` | `ShieldConfiguration` extension | Shielded application opened |
| `NudgeShieldAction` | `app.nudge.NudgeShieldAction` | `ShieldAction` extension | Shield control activated |

An extension bundle identifier must be prefixed by the containing application's
identifier followed by one additional component.

Three properties of this model determine the rest of the architecture:

1. **No shared address space.** Extensions cannot call into the application and share
   no memory with it. All inter-process state passes through the App Group container.
2. **Constrained resources.** Extension processes operate under a memory budget in the
   single-digit megabytes and are terminated on breach. Linked module weight is
   therefore a correctness concern, not an optimisation.
3. **Independent lifecycle.** An extension may execute at any time, including when the
   application has never been launched in the current boot.

---

## 2. Module graph

```
                    ┌──────────────┐
                    │ DesignSystem │   SwiftUI, presentation only
                    └──────▲───────┘
                           │
                  ┌────────┴────────┐
                  │   Nudge (app)   │
                  └────────┬────────┘
                           │
                    ┌──────▼───────┐
                    │  NudgeCore   │   no dependencies, no SwiftUI
                    └──────▲───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────┴──────┐  ┌────────┴───────┐  ┌───────┴──────────┐
│ NudgeMonitor │  │  NudgeShield   │  │ NudgeShieldAction│
└──────────────┘  └────────────────┘  └──────────────────┘
```

Modules are local Swift Package Manager packages under `Packages/`. Package manifests
declare permitted imports, so a boundary violation is a compilation failure rather than
a review comment.

### 2.1 Dependency rules

- `NudgeCore` declares no dependencies and does not import SwiftUI. This is what makes
  it linkable by a memory-constrained extension.
- `DesignSystem` is linked by the application target only. It must never appear in an
  extension's link phase.
- Extensions link `NudgeCore` exclusively.
- The module split is drawn along one axis: *what an extension may load*. It is not an
  abstract layering exercise, and further modules are introduced only when a comparable
  hard constraint appears.

---

## 3. NudgeCore

Domain model, persistence, time, and the Screen Time abstraction. Contains no
presentation code and no platform UI types.

### 3.1 Domain

Value types (`struct`, `enum`) conforming to `Codable`, `Sendable` and `Hashable`.

| Type | Responsibility |
|---|---|
| `DayState` | The six terminal states of a calendar day |
| `StreakEffect` | The effect of a day on the running streak |
| `CalendarDay` | Year/month/day triple used as the history key |
| `TaskTier` | Escalation tier of an escape-protocol task |
| `ResetTask` | A single offered task |
| `LockSession` | A cooldown period with a fixed duration and an outcome |
| `ProtocolStep`, `ProtocolSession` | Progression through the escape protocol |
| `Reflection` | Single-tap post-protocol response |
| `DayRecord` | Aggregate record for one day |

Two rules are expressed as behaviour on `DayState` rather than as scattered conditionals:

- `DayState.worst(_:_:)` resolves a day that recorded multiple outcomes. Precedence is
  `overridden > rejected > incomplete > earned > clean > noData` (SPEC §3).
- `DayState.streakEffect` maps a state onto `extends`, `breaks` or `ignored`. Only
  `rejected` and `overridden` break a streak: those are the two states in which the user
  regained access to the blocked applications. Task completion is self-reported and
  therefore not a streak input (SPEC §7).

`CalendarDay` stores calendar components rather than a `Date`. A `Date` denotes an
instant; a calendar day does not. Storing components keeps persisted history stable
across time-zone changes and makes day arithmetic independent of wall-clock time.

Naming constraint: domain types must not shadow standard library names. `ResetTask`
exists because `Task` is Swift's concurrency primitive.

### 3.2 Time

```swift
public protocol AppClock: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}
```

`SystemClock` is the production implementation; `FixedClock` is a frozen, advanceable
implementation for tests. Named `AppClock` because the standard library defines `Clock`.

All time-dependent logic resolves the current instant through an injected `AppClock`.
Midnight rollover and streak accumulation are consequently testable without elapsed
real time.

### 3.3 Persistence

Two stores, both backed by the App Group container.

**`FileStore`** — `Codable` documents serialised as JSON.

```swift
public protocol FileStore: Sendable {
    func load<T: Decodable>(_ type: T.Type, from file: StoreFile) throws -> T?
    func save<T: Encodable>(_ value: T, to file: StoreFile) throws
    func delete(_ file: StoreFile) throws
}
```

`JSONFileStore` takes its directory as an initialiser parameter rather than resolving a
global location, which permits tests to target a temporary directory. Writes use
`Data.WritingOptions.atomic`, so an extension terminated mid-write cannot leave a
partially written document. Decode failures are translated to
`NudgeError.storageReadFailed` rather than propagating `DecodingError`.

`StoreFile` enumerates the known documents (`dayRecords`, `lockSessions`,
`protocolSessions`, `taskLibrary`).

**`SettingsStore`** — scalar configuration in the App Group `UserDefaults` suite.
`UserDefaultsSettingsStore` stores the suite *name*, not a `UserDefaults` instance,
because `UserDefaults` is not `Sendable`; the instance is resolved per access.

Rationale for JSON over a managed object store: the data volume is small and bounded
(one record per day, plus a task library), the schema is owned entirely by this
project, and the store must be readable inside a memory-constrained extension.

### 3.4 Screen Time abstraction

```swift
public protocol ScreenTimeService: Sendable {
    func authorizationStatus() async -> ScreenTimeAuthorizationStatus
    func requestAuthorization() async throws
    func startMonitoring(dailyThreshold: TimeInterval) async throws
    func stopMonitoring() async throws
    func applyShield() async throws
    func removeShield() async throws
    func isShielded() async -> Bool
    var events: AsyncStream<ScreenTimeEvent> { get }
}
```

`FakeScreenTimeService` is an in-memory implementation declared as an `actor`. It
exposes `simulateThresholdReached()`, which substitutes for the monitor extension
firing.

This abstraction is load-bearing for two reasons independent of testing:

- The Screen Time APIs are non-functional in the Simulator.
- Distribution requires an entitlement granted by Apple on request.

All application screens and flows are therefore developed against the protocol, and the
live implementation is selected in one function of the composition root.

`events` models the real data path as well as the fake one: in production the monitor
extension writes to the App Group and the application observes, rather than receiving a
direct callback.

### 3.5 Errors

`NudgeError` enumerates the failure modes that exist in an on-device-only application:
authorisation denial, entitlement absence, App Group unavailability, and storage read
or write failure. It conforms to `LocalizedError`.

Errors propagate with `throws` and `async`/`await`. `Result`-returning asynchronous
APIs and functional error containers are not used.

---

## 4. DesignSystem

Presentation tokens and components. Contains no domain vocabulary.

### 4.1 Tokens

`Theme` is the namespace for every design constant: `Color`, `Typography`, `Spacing`
(4pt base), `Radius`, `Elevation`, `Size`, `Stroke`, `Opacity`, `Motion`.

Colours are defined as Asset Catalog colour sets with explicit light and dark values,
not as literals in Swift. Appearance switching is consequently handled by the system
with no conditional code.

Typography is a named ramp applied through `.textStyle(Theme.Typography.bodyM)`. The
modifier scales size, tracking and line spacing together via `@ScaledMetric(relativeTo:)`,
so Dynamic Type support follows from using the token.

No feature may declare a colour, spacing value, corner radius or font size inline. A
missing value is added to the token set.

### 4.2 Tone

`Theme.Tone` binds a fill colour to its guaranteed-contrast foreground and its
block-shadow tint. Components accept a `Tone` rather than individual colours, which
makes an unreadable colour pairing unrepresentable.

### 4.3 Components

`NudgeCard`, `NudgePill`, `IconCircle`, `StreakCounter`, `DayCell`, `CooldownRing`,
`StepProgress`, and four `ButtonStyle` implementations exposed as `.nudgePrimary`,
`.nudgeSecondary`, `.nudgeDestructive` and `.nudgeText`.

`DesignSystemGallery` renders the complete token set and component inventory on one
screen and serves as the visual acceptance surface for the package.

### 4.4 Domain independence

`DayCell` accepts a `DayCellStyle` — a fill, a foreground, and a placeholder flag —
together with a caller-supplied accessibility description. It has no knowledge of
`DayState`.

Mapping domain state onto presentation is the responsibility of the feature layer. The
inverse arrangement would make the package unusable outside this product and would
invert the dependency direction between presentation and domain.

---

## 5. Application layer

Pattern: MVVM with `@Observable`, organised by feature. Views hold no business logic,
networking or persistence.

### 5.1 Composition root

`CompositionRoot` constructs the object graph once, at launch, and supplies
dependencies through initialisers. There is no service locator and no registration
step: an unwired dependency is a compilation failure rather than a runtime lookup
failure.

Its initialiser throws when the App Group container cannot be resolved. No degraded
mode exists — the application cannot exchange state with its extensions — so
`NudgeApp` renders `StartupFailureView` instead.

Environment selection of `ScreenTimeService` is confined to a single private factory
method.

### 5.2 Navigation

Navigation is value-driven. `AppRouter` is an `@Observable`, `@MainActor` type owning a
`[Route]` path bound to a `NavigationStack`. Screens append a `Route`; they do not
construct destination views.

`Route` is declared `nonisolated`. The application target sets
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so types declared in it are implicitly
main-actor isolated; a pure value type has no such requirement and would otherwise be
unusable from a background context.

`Route(deepLink:)` parses the `nudge://` scheme registered in `CFBundleURLTypes`.
`AppRouter.present(_:)` *replaces* the path rather than appending to it: an entry point
originating outside the application must not leave unrelated screens beneath it.

`AppRouter` is deliberately separate from any screen's view model, because navigation
is driven from outside the view hierarchy — by a deep link, or by discovering a pending
protocol session in shared storage at launch.

### 5.3 Error presentation

`ErrorAlert` is a `ViewModifier` applied as `.errorAlert($error)`. Screens do not
construct their own alerts. `StartupFailureView` covers the unrecoverable case
described in §5.1.

---

## 6. Platform configuration

### 6.1 Entitlements

Each runnable target carries an `.entitlements` file declaring
`com.apple.security.application-groups` (`group.app.nudge`) and
`com.apple.developer.family-controls`. Entitlements are validated against the
provisioning profile and embedded in the code signature; they are privileges granted by
Apple, distinct from `Info.plist` metadata.

### 6.2 App Group

`group.app.nudge` provides one shared container directory and one shared `UserDefaults`
suite. It is the only channel between the application and its extensions.

`UserDefaults.standard` is not shared across the App Group and must not be used for any
state an extension reads or writes.

`NudgeTests/AppGroupTests.swift` verifies at runtime that the container resolves, the
suite opens, and a value round-trips. The failure mode this guards against is silent:
without the capability the application and its extensions simply stop observing each
other's data.

### 6.3 Info.plist

The application target uses an explicit `Nudge/Info.plist`, merged with keys generated
from build settings. It is explicit because the generated form cannot express the
launch screen configuration, and because `CFBundleURLTypes` is required for the
`nudge://` scheme.

The file is listed in a `PBXFileSystemSynchronizedBuildFileExceptionSet` so the
synchronized folder does not also copy it as a bundle resource, which would produce two
build commands writing the same output. The extension targets use the same mechanism.

### 6.4 Asset catalogs

`Assets.xcassets` compiles to `Assets.car`. The catalog carries appearance variants and
per-device resolutions, and supports App Thinning.

The application icon is supplied as a single 1024×1024 image per appearance — light,
dark and tinted. Derived sizes are generated at build time.

`AccentColor` mirrors `Theme.Color.accentPrimary` so system-tinted controls agree with
the design system.

### 6.5 Launch screen

The launch screen is rendered by the system before application code executes and is
therefore declarative, not SwiftUI. It is described in `Info.plist`:

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key><string>LaunchBackground</string>
    <key>UIImageName</key><string>LaunchMark</string>
</dict>
```

Both names refer to asset catalog entries with light and dark variants. No animation is
possible at this stage; any motion belongs to the first rendered view.

### 6.6 Localization

User-facing strings are held in the `Nudge/Localizable.xcstrings` String Catalog, which
compiles to `en.lproj/Localizable.strings`.

SwiftUI extracts `LocalizedStringKey` positions automatically. Values passed to
parameters typed as `String` are not extracted and must be wrapped in
`String(localized:)`; the omission is silent.

---

## 7. Concurrency model

The project builds in Swift 6 language mode with strict concurrency checking. Data-race
safety is enforced by the compiler rather than by convention.

- Domain types are `Sendable` value types.
- Mutable shared state is held in actors. `FakeScreenTimeService` is the current example.
- UI-bound types are `@MainActor`.
- The application target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; types
  declared there are implicitly main-actor isolated unless marked `nonisolated`. The
  packages do not set this, so `NudgeCore` and `DesignSystem` types are unisolated by
  default.
- `@unchecked Sendable` and `nonisolated(unsafe)` are not used to suppress diagnostics.
  Where a non-`Sendable` platform type is involved, the data flow is restructured — see
  `UserDefaultsSettingsStore` in §3.3.

---

## 8. Testing strategy

Swift Testing (`@Test`, `#expect`) throughout. Fakes are hand-written; no mocking
framework is used.

| Suite | Target | Covers |
|---|---|---|
| `NudgeCoreTests` | package | Day-state precedence and streak effects, calendar arithmetic, clock rollover, store round-trips and corruption handling, fake service behaviour, session invariants |
| `DesignSystemTests` | package | Every semantic colour resolves to an asset, parameterised over the token list |
| `NudgeTests` | application | App Group availability at runtime, deep-link parsing, router behaviour |
| `NudgeUITests` | application | Launch smoke test only; excluded from CI |

Principles:

- Pure domain logic is tested directly and exhaustively. It has no dependencies, so
  these tests are fast and require no fakes.
- Non-determinism is injected, never mocked at the call site: time via `AppClock`,
  storage directory via `JSONFileStore(directory:)`.
- View rendering is not unit-tested. Logic is pushed out of views instead.
- The App Group tests exist to detect configuration regressions, not code regressions.

---

## 9. Build and tooling

- Swift 6, iOS 18.6 minimum, across all targets including tests and extensions.
- `swift-format` with a checked-in configuration, invoked through `Scripts/format.sh`.
  It ships with the toolchain and is not a third-party dependency.
- GitHub Actions builds and tests every target on push and pull request, and lints
  formatting. The workflow resolves an available simulator at run time rather than
  naming a device, because runner images vary.
- A shared scheme is committed at `Nudge.xcodeproj/xcshareddata/xcschemes/`. Schemes
  generated automatically by Xcode reside in `xcuserdata`, which is not tracked, and
  are therefore unavailable to CI.
- The application target uses synchronized folder groups, so source files added on disk
  are compiled without project file modification.

---

## 10. Known platform constraints

Constraints that shape the design and are not negotiable:

- **Application tokens are opaque.** Selection returns tokens, not bundle identifiers
  or names. The identity of a monitored application is not knowable, loggable or
  transmissible. No feature may assume otherwise.
- **`ShieldConfiguration` is not arbitrary UI.** It supplies a background, one icon, a
  title, a subtitle and up to two buttons with configurable labels and colours.
- **`DeviceActivityReport` executes in a sandboxed extension** that renders SwiftUI and
  cannot perform network access or return data to the host.
- **Threshold detection latency is unspecified.** No interface may promise
  interruption at a precise moment.
- **A `ShieldAction` extension has no documented mechanism for launching its containing
  application.** It returns `.close`, `.defer` or `.none`. Transfer of control from the
  shield to the application is therefore expected to proceed via shared state plus a
  local notification. This requires confirmation before the interception feature is
  implemented, as it affects SPEC F3.2.

---

## 11. Open decisions

- **SPEC Q2** — cooldown duration relative to threshold. Currently derived from the sum
  of nominal tier durations (32 minutes).
- **SPEC Q3** — daily-total versus session-based thresholds. Daily total is implemented.
- **`LiveScreenTimeService`** — not yet written. Lands with the interception feature.
- **`DEVELOPMENT_TEAM`** — unset; device builds are not yet possible.
