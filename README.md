# Nudge

**A screen-time app that gives you a way out, not just a wall.**

Native iOS. An Android counterpart lives in a separate repository.

---

## The idea

Most screen-time apps are preventive: you schedule a block ahead of time and hope
future-you complies. When the wall appears, the only door out is "snooze 15 minutes"
— and everyone taps it.

Nudge is interventional. You pick the apps you lose time to and a daily limit. When
you cross it, those apps lock for a cooldown — and instead of a dead end, Nudge
offers an **escape protocol**: a sequence of escalating tasks served one at a time,
from instant physical resets, through small wins, to a longer activity.

**The core design principle:** completing tasks does *not* unlock the apps early. The
cooldown runs on a timer regardless. The protocol is what you're offered to do
*instead of* staring at a locked phone — never a toll to pay to get back in.

That single decision keeps the app on the user's side and removes any incentive to
game the task list.

The hero metric isn't screen time saved. It's **days you didn't need it at all**.

## Why this is native, and not Flutter

I build cross-platform apps professionally. This one is native on purpose, because
the architecture makes the choice for you.

iOS Screen Time work runs mostly **outside your app process**, in separate extension
targets that fire when the app isn't running — and they execute under a memory budget
of a few megabytes. A Flutter engine cannot live there. The lock screen itself is
rendered by a system extension with a fixed, non-custom layout. App selection returns
opaque tokens that are meaningless outside Swift.

The practical consequence: roughly two thirds of the interesting code would be Swift
under any framework, and a cross-platform layer would only add a bridge to maintain.
Android's equivalent (`UsageStatsManager` plus overlay-based blocking) is a different
model again, so there is little to share even in principle.

Choosing the right tool is part of the exercise here.

## Status

🚧 **Early development.** Foundations in place; no user-facing features yet.

```
Nudge/                  app target
Packages/NudgeCore/     domain models, persistence, clock, Screen Time abstraction
Packages/DesignSystem/  design tokens and components
```

`NudgeCore` is deliberately dependency-free and SwiftUI-free, because the app
extensions link it and run under a memory budget of a few megabytes. That constraint —
not taste — is what draws the module boundary.

## Documentation

| Document | What's in it |
|---|---|
| [docs/SPEC.md](docs/SPEC.md) | Product spec: features, acceptance criteria, day-state model, open questions |
| [CLAUDE.md](CLAUDE.md) | Engineering conventions and architectural rules |

## Tech

- Swift 6 (strict concurrency), SwiftUI
- iOS 18.6+
- Screen Time API — `FamilyControls`, `ManagedSettings`, `DeviceActivity`
- Local Swift Package Manager modules for feature boundaries
- Swift Testing

## Requirements

- Xcode 26+
- An Apple Developer account with the **Family Controls** entitlement approved
  (required for distribution; the core feature cannot be exercised on device without it)

## Getting started

```bash
git clone git@github.com:<user>/nudge-ios.git
cd nudge-ios
open Nudge.xcodeproj
```

Build and run on the iOS Simulator. Note that Screen Time behaviour cannot be fully
exercised in the simulator — threshold detection and app shielding require a physical
device.
