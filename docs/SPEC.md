# Product Spec — v1 (Working title: TBD)

> Status: draft for review
> Scope: iOS native (SwiftUI). Android is a later port.
> Purpose: source of truth for v1 feature set and acceptance criteria; input for tickets.

---

## 1. Product summary

A screen-time app that intercepts compulsive app use and offers a structured way out of it,
rather than just a wall.

The user selects apps to monitor and a daily usage threshold. When the threshold is crossed,
the monitored apps are locked for a fixed cooldown. During that cooldown the app offers a
guided **escape protocol** — a sequence of escalating physical and productive tasks, served one
at a time — designed to break the dopamine loop and restore a sense of agency.

**Core design principle:** completing tasks does NOT unlock the apps. The cooldown runs on a
timer regardless. The protocol is what you're offered to do *instead of* staring at a locked
phone — never a toll to pay to get back in. This keeps the app on the user's side and removes
the incentive to game the task list.

**North star metric (user-facing):** days the user did not need the escape at all.

---

## 2. Glossary

| Term | Definition |
|---|---|
| **Monitored apps** | The set of apps the user selected during onboarding to be tracked and locked. |
| **Threshold** | Daily cumulative usage across all monitored apps that triggers a lock. |
| **Lock session** | The period during which all monitored apps are shielded, following a threshold breach. |
| **Escape protocol** | The guided task sequence offered during a lock session. |
| **Task tier** | Size/effort class of a task (see §5). |
| **Clean day** | A day on which the threshold was never reached. |
| **Earned day** | A day on which the threshold was reached, the lock was accepted, and all protocol tasks were completed. |
| **Emergency unlock** | A high-friction, limited override that ends a lock session early. |

---

## 3. Day-state model

Exactly one state per calendar day. Drives the calendar view and streak calculation.

| State | Meaning | Streak effect |
|---|---|---|
| `CLEAN` | Threshold never reached | Extends |
| `EARNED` | Threshold reached, lock accepted, all tasks completed | Extends |
| `INCOMPLETE` | Threshold reached, lock accepted, tasks not all completed | Extends |
| `REJECTED` | Threshold reached, user rejected the lock | Breaks |
| `OVERRIDDEN` | Emergency unlock used | Breaks |
| `NO_DATA` | Before first use, or monitoring unavailable | Neutral (ignored) |

**Precedence:** if multiple events occur in one day, the worst outcome wins
(`OVERRIDDEN` > `REJECTED` > `INCOMPLETE` > `EARNED` > `CLEAN`).

---

## 4. Features & acceptance criteria

### F1 — Onboarding

Select what to monitor and set the threshold. First-run only; all values editable later in settings.

**AC**
1. On first launch the user is taken through onboarding before reaching the main screen.
2. The user grants Screen Time authorization. If denied, the app explains that it cannot function and offers to retry.
3. The user selects one or more apps to monitor via the system app picker.
4. The user sets a daily threshold from a preset list (e.g. 30 min / 1 h / 2 h) or a custom value.
5. Onboarding cannot be completed with zero monitored apps or no threshold set.
6. On completion the user lands on the main screen with a streak of 0.

> **Constraint:** app selections come back as opaque system tokens. The app never learns which
> app was chosen, and cannot pre-populate or name specific apps (e.g. "Instagram") in its own UI.

---

### F2 — Monitoring & threshold detection

**AC**
1. Usage is accumulated as a **daily total across all monitored apps combined**.
2. The daily total resets at local midnight.
3. When the daily total reaches the threshold, a lock session is triggered.
4. Triggering locks **all** monitored apps, regardless of which one caused the breach.
5. After a lock session ends, the usage clock resets; accumulating another full threshold's
   worth of usage triggers a new lock session on the same day.
6. There is no daily cap on the number of lock sessions.

---

### F3 — Lock session

**AC**
1. When triggered, all monitored apps display a lock screen instead of their content.
2. The lock screen offers exactly two primary choices: **start the escape protocol**, or **reject the lock**.
3. Lock duration is a fixed value derived from the approximate total time of the protocol tasks (see §5) and is **independent of task completion**.
4. Completing all tasks does NOT end the lock session early.
5. The lock session ends automatically when its duration elapses; apps become usable again.
6. If the user rejects the lock, all monitored apps unlock immediately and the day is marked `REJECTED`.
7. Rejecting a lock does not disable future lock sessions that day.
8. A lock session's remaining time is visible to the user at all times while active.

---

### F4 — Escape protocol

Tasks served **one at a time**, escalating through tiers.

**AC**
1. On starting the protocol, the user is shown exactly one task.
2. The user can mark the current task complete, **swap** it for another task in the same tier, or **skip** it.
3. On completion or skip, the next task is served, escalating to the next tier when the current tier's task is resolved.
4. Tasks can be marked complete at any time; there is no minimum elapsed time before completion is allowed.
5. The protocol is complete when one task from every tier has been marked complete.
6. Skipping a task means that tier is not completed, and the protocol cannot reach `EARNED`.
7. On protocol completion the user is shown a single-tap reflection prompt ("how do you feel now?") with a small set of options.
8. The reflection response is stored with the session.
9. Protocol progress persists if the user leaves and re-opens the app during the lock session.

> **Known accepted limitation:** task completion is entirely self-reported and unverifiable.
> This is accepted because completion grants no access — only streak credit — so the only
> person a user can cheat is themselves.

---

### F5 — Emergency unlock

**AC**
1. An emergency unlock is available during any active lock session, but is not a primary action on the lock screen.
2. Using it requires deliberate friction before it takes effect (e.g. typing a confirmation sentence and/or a forced wait).
3. The user has a limited number of emergency unlocks per rolling week.
4. When exhausted, the option is shown as unavailable with the time until the next one becomes available.
5. A successful emergency unlock ends the lock session immediately and unlocks all monitored apps.
6. The day is marked `OVERRIDDEN` and the streak breaks.
7. Every emergency unlock is recorded and visible in history.

---

### F6 — Streak & clean days

**AC**
1. The app displays a current streak, starting at 0 for a new user.
2. The streak increments for each consecutive `CLEAN` or `EARNED` day.
3. The streak resets to 0 on any `REJECTED` or `OVERRIDDEN` day.
4. The app separately displays a total count of `CLEAN` days.
5. Streak state is evaluated once per day at local midnight rollover.
6. `NO_DATA` days do not break the streak.

---

### F7 — Calendar & history

**AC**
1. A calendar view shows one visual state per day, matching the day-state model in §3.
2. Tapping a day shows that day's detail: lock sessions, tasks completed, reflection response, emergency unlocks used.
3. Days before the user's first use are shown as `NO_DATA`.
4. The current streak and clean-day total are visible alongside the calendar.

---

### F8 — Task library

**AC**
1. Tasks are grouped into tiers by scale/effort. Proposed v1 tiers:
   - **Tier 1 — Instant physical reset** (cold water, stretch, step outside)
   - **Tier 2 — Small win** (brush teeth, fold clothes, tidy a surface)
   - **Tier 3 — Longer activity** (walk, workout, study block)
2. The app ships with a curated default task set for each tier.
3. The user can disable any default task, and disabled tasks are never served.
4. The user can add custom tasks, and must assign each to one of the predefined tiers.
5. The user can edit and delete their own custom tasks.
6. A tier must always have at least one enabled task; the app prevents disabling the last one.

---

### F9 — Settings

**AC**
1. The user can change the set of monitored apps.
2. The user can change the daily threshold.
3. The user can manage the task library (per F8).
4. Changes take effect from the next monitoring period; an active lock session is unaffected.

---

## 5. Tuning values (to be decided)

These drive the feel of the product and should be treated as configurable constants, not hardcoded.

| Value | Proposed default | Notes |
|---|---|---|
| Tier 1 task duration | ~2 min | Used only to derive lock duration |
| Tier 2 task duration | ~10 min | |
| Tier 3 task duration | ~20 min | |
| **Lock session duration** | sum of the above (~30 min) | See open question Q2 |
| Emergency unlocks per week | 2 | |
| Threshold presets | 30 min / 1 h / 2 h / custom | |

---

## 6. Out of scope for v1

- Points / rewards economy
- Social features, accountability partners, shared progress
- Voluntary protocol start (widget / Control Center / Action Button) without a threshold breach
- Pre-warning notifications before the threshold
- Per-app thresholds or per-app locking
- Session-based (rather than daily-total) thresholds
- Onboarding motivation capture ("why are you doing this")
- Time-of-day pattern analytics
- Multi-device / parental control
- Android

---

## 7. Resolved decisions

**Q1 — `INCOMPLETE` day handling. Resolved: it extends the streak.**
The streak measures whether the user stayed inside the lock, not whether they worked through
the whole protocol. Task completion is self-reported and unverifiable — a user can tap every
step in seconds — so rewarding it would be rewarding a number the app cannot trust. The streak
therefore breaks only on `REJECTED` or `OVERRIDDEN`: the two cases where the user actually got
back into the blocked apps.

`INCOMPLETE` remains a distinct day state for the calendar and for statistics; it simply carries
no streak penalty.

## 8. Open questions

**Q2 — Lock duration length.** A ~30 minute lock triggered by a 30 minute threshold may feel
disproportionate and drive rejections/uninstalls. Needs real-world tuning — consider a shorter
first lock that escalates on repeat sessions the same day.

**Q3 — Threshold granularity.** Daily total is set for v1. Worth revisiting whether a
session-based threshold better matches the actual doomscroll failure mode.

---

## 9. Dependencies & risks

- **Family Controls entitlement** from Apple is required for distribution. Approval is not
  guaranteed and gates the entire product. **Apply before building.**
- Threshold detection latency is not guaranteed to be instant; UX must not promise
  to-the-second interruption.
- Monitoring extensions run under tight memory and runtime limits, constraining what logic
  can live in them.
