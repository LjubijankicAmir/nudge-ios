import SwiftUI

/// Every token and component on one screen. This is the acceptance test.
public struct DesignSystemGallery: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                Text("Nudge · Arcade").textStyle(Theme.Typography.titleL)

                section("Colors") { colors }
                section("Typography") { typography }
                section("Spacing · Radius · Elevation") { shapeTokens }
                section("Buttons") { buttons }
                section("Cards & Pills") { cardsAndPills }
                section("Streak") { streak }
                section("Calendar day states") { dayStates }
                section("Cooldown & progress") { progress }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Color.backgroundPrimary.ignoresSafeArea())
        .foregroundStyle(Theme.Color.textPrimary)
    }

    // MARK: Sections

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title).textStyle(Theme.Typography.eyebrow).foregroundStyle(Theme.Color.textSecondary)
            content()
        }
    }

    private var colors: some View {
        let swatches: [(String, Color, Color)] = [
            ("backgroundPrimary", Theme.Color.backgroundPrimary, Theme.Color.textPrimary),
            ("backgroundSecondary", Theme.Color.backgroundSecondary, Theme.Color.textPrimary),
            ("surface", Theme.Color.surface, Theme.Color.textPrimary),
            ("accentPrimary", Theme.Color.accentPrimary, Theme.Color.onAccentPrimary),
            ("accentSecondary", Theme.Color.accentSecondary, Theme.Color.onAccentSecondary),
            ("reward", Theme.Color.reward, Theme.Color.onReward),
            ("success", Theme.Color.success, Theme.Color.onSuccess),
            ("warning", Theme.Color.warning, Theme.Color.onWarning),
            ("danger", Theme.Color.danger, Theme.Color.onDanger),
            ("info", Theme.Color.info, Theme.Color.onInfo),
            ("textPrimary", Theme.Color.textPrimary, Theme.Color.surface),
            ("textSecondary", Theme.Color.textSecondary, Theme.Color.surface),
            ("textTertiary", Theme.Color.textTertiary, Theme.Color.surface),
        ]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Theme.Spacing.xs)], spacing: Theme.Spacing.xs) {
            ForEach(swatches, id: \.0) { name, fill, fg in
                Text(name)
                    .textStyle(Theme.Typography.caption)
                    .foregroundStyle(fg)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .padding(Theme.Spacing.xs)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous).fill(fill))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous).strokeBorder(Theme.Color.divider))
            }
        }
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(Theme.Typography.all, id: \.0) { name, style in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                    Text(name).textStyle(Theme.Typography.caption).foregroundStyle(Theme.Color.textTertiary).frame(width: 96, alignment: .leading)
                    Text(style.uppercased ? "Days you didn't need it" : "Handled 14").textStyle(style).lineLimit(1).minimumScaleFactor(0.4)
                }
            }
        }
    }

    private var shapeTokens: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .bottom, spacing: Theme.Spacing.xs) {
                ForEach([("xxs", Theme.Spacing.xxs), ("xs", Theme.Spacing.xs), ("sm", Theme.Spacing.sm), ("md", Theme.Spacing.md),
                         ("lg", Theme.Spacing.lg), ("xl", Theme.Spacing.xl), ("xxl", Theme.Spacing.xxl), ("xxxl", Theme.Spacing.xxxl)], id: \.0) { name, v in
                    VStack(spacing: Theme.Spacing.xxs) {
                        RoundedRectangle(cornerRadius: Theme.Radius.chip).fill(Theme.Color.accentPrimary).frame(width: v, height: v)
                        Text(name).textStyle(Theme.Typography.caption).foregroundStyle(Theme.Color.textTertiary)
                    }
                }
            }
            HStack(spacing: Theme.Spacing.sm) {
                ForEach([("chip", Theme.Radius.chip), ("tile", Theme.Radius.tile), ("cardSmall", Theme.Radius.cardSmall), ("card", Theme.Radius.card)], id: \.0) { name, r in
                    VStack(spacing: Theme.Spacing.xxs) {
                        RoundedRectangle(cornerRadius: r, style: .continuous).fill(Theme.Color.surface)
                            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(Theme.Color.divider))
                            .frame(width: 64, height: 64)
                        Text("\(name) \(Int(r))").textStyle(Theme.Typography.caption).foregroundStyle(Theme.Color.textTertiary)
                    }
                }
            }
            HStack(spacing: Theme.Spacing.md) {
                ForEach([("chip", Theme.Elevation.chip), ("control", Theme.Elevation.control), ("hero", Theme.Elevation.hero)], id: \.0) { name, d in
                    VStack(spacing: Theme.Spacing.xs) {
                        RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous).fill(Theme.Color.reward)
                            .frame(width: 64, height: 40)
                            .blockShadow(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous), color: Theme.Color.rewardDepth, depth: d)
                        Text("\(name) \(Int(d))").textStyle(Theme.Typography.caption).foregroundStyle(Theme.Color.textTertiary)
                    }
                }
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button("Done") {}.buttonStyle(.nudgePrimary)
            HStack(spacing: Theme.Spacing.sm) {
                Button { } label: { Label("Swap", systemImage: "shuffle") }.buttonStyle(.nudgeSecondary)
                Button { } label: { Label("Skip", systemImage: "forward.fill") }.buttonStyle(.nudgeSecondary)
            }
            Button("Remove TikTok from Nudge") {}.buttonStyle(.nudgeDestructive)
            Button("Emergency override") {}.buttonStyle(.nudgeText)
            Button("Disabled") {}.buttonStyle(.nudgePrimary).disabled(true)
        }
    }

    private var cardsAndPills: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            NudgeCard(tone: .accent, elevation: Theme.Elevation.hero) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Days you didn't need it").textStyle(Theme.Typography.eyebrow)
                    Text("14").textStyle(Theme.Typography.displayXL)
                }
            }
            NudgeCard {
                HStack(spacing: Theme.Spacing.sm) {
                    IconCircle("drop", tone: .info)
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Splash cold water on your face").textStyle(Theme.Typography.titleS)
                        Text("Instant reset · 1 min").textStyle(Theme.Typography.bodyS).foregroundStyle(Theme.Color.textSecondary)
                    }
                }
            }
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(Theme.Tone.allCases, id: \.self) { tone in
                    NudgePill("\(tone)".capitalized, tone: tone, elevated: true)
                }
            }
            .lineLimit(1)
        }
    }

    private var streak: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                StreakCounter(days: 21)
                StreakCounter(days: 0)
            }
            StreakCounter(days: 21, layout: .hero, detail: "3 bad moments handled")
            StreakCounter(days: 0, layout: .hero, detail: "Your 14 clean days stay.")
        }
    }

    private var dayStates: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(DayCellStyle.allPresets, id: \.name) { preset in
                    DayCell(day: 16, style: preset.style, stateDescription: preset.name)
                }
                DayCell(day: 16, style: .noData, isToday: true, stateDescription: "no data")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.xxs), count: 2), alignment: .leading, spacing: Theme.Spacing.xxs) {
                ForEach(DayCellStyle.allPresets, id: \.name) { preset in
                    HStack(spacing: Theme.Spacing.xs) {
                        RoundedRectangle(cornerRadius: Theme.Radius.chip / 3).fill(preset.style.fill).frame(width: 12, height: 12)
                        Text(preset.name).textStyle(Theme.Typography.caption).foregroundStyle(Theme.Color.textSecondary)
                    }
                }
            }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.lg) {
                CooldownRing(remaining: 23 * 60 + 40, total: 30 * 60, caption: "TikTok")
                CooldownRing(remaining: 0, total: 30 * 60, caption: "Unlocked")
            }
            StepProgress(total: 6, completed: 2)
        }
    }
}

#Preview("Light") {
    DesignSystemGallery().preferredColorScheme(.light)
}

#Preview("Dark") {
    DesignSystemGallery().preferredColorScheme(.dark)
}

#Preview("Accessibility XXXL") {
    DesignSystemGallery().dynamicTypeSize(.accessibility3)
}
