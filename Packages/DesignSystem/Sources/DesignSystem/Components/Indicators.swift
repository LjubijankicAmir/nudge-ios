import SwiftUI

// MARK: - Streak counter

public struct StreakCounter: View {
    public enum Layout: Sendable { case badge, hero }

    private let days: Int
    private let layout: Layout
    private let detail: String?

    /// - Parameters:
    ///   - days: current streak length. `0` renders as "Day 1" (a fresh start), never as a loss.
    ///   - detail: optional supporting line for `.hero`, e.g. "3 bad moments handled".
    public init(days: Int, layout: Layout = .badge, detail: String? = nil) {
        self.days = days
        self.layout = layout
        self.detail = detail
    }

    private var isFreshStart: Bool { days <= 0 }

    public var body: some View {
        switch layout {
        case .badge:
            NudgePill(
                isFreshStart ? "Day 1" : "\(days)",
                systemImage: "flame",
                tone: isFreshStart ? .surface : .reward,
                elevated: true
            )
            .accessibilityLabel(accessibilityText)
        case .hero:
            HStack(spacing: Theme.Spacing.sm) {
                IconCircle("flame", tone: isFreshStart ? .surface : .reward, size: Theme.Size.iconCircleLarge)
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Streak").textStyle(Theme.Typography.eyebrow).foregroundStyle(Theme.Color.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                        Text(isFreshStart ? "Day 1" : "\(days)")
                            .textStyle(Theme.Typography.displayM)
                            .contentTransition(.numericText())
                        if let detail {
                            Text(detail).textStyle(Theme.Typography.bodyS).foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                }
            }
            .foregroundStyle(Theme.Color.textPrimary)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)
        }
    }

    private var accessibilityText: String {
        isFreshStart ? "Streak: day one" : "Streak: \(days) days"
    }
}

// MARK: - Day state & cell

/// Visual treatment for one calendar day.
///
/// Purely presentational: the design system does not know what a "clean" or an
/// "earned" day *means*, only how one looks. The feature layer owns the domain
/// state and maps it onto one of these presets.
public struct DayCellStyle: Sendable, Hashable {
    public let fill: Color
    public let foreground: Color
    /// A day with nothing recorded yet. Today's cell renders as an outline
    /// rather than a filled tile when its style is a placeholder.
    public let isPlaceholder: Bool

    public init(fill: Color, foreground: Color, isPlaceholder: Bool = false) {
        self.fill = fill
        self.foreground = foreground
        self.isPlaceholder = isPlaceholder
    }

    public static let clean = DayCellStyle(fill: Theme.Color.dayClean, foreground: Theme.Color.onDayClean)
    public static let earned = DayCellStyle(fill: Theme.Color.dayEarned, foreground: Theme.Color.onDayEarned)
    public static let incomplete = DayCellStyle(
        fill: Theme.Color.dayIncomplete, foreground: Theme.Color.onDayIncomplete)
    public static let rejected = DayCellStyle(fill: Theme.Color.dayRejected, foreground: Theme.Color.onDayRejected)
    public static let overridden = DayCellStyle(
        fill: Theme.Color.dayOverridden, foreground: Theme.Color.onDayOverridden)
    public static let noData = DayCellStyle(
        fill: Theme.Color.dayNoData, foreground: Theme.Color.onDayNoData, isPlaceholder: true)

    /// Every preset with a display name. For the gallery only.
    public static let allPresets: [(name: String, style: DayCellStyle)] = [
        ("clean", .clean), ("earned", .earned), ("incomplete", .incomplete),
        ("rejected", .rejected), ("overridden", .overridden), ("noData", .noData),
    ]
}

public struct DayCell: View {
    private let day: Int
    private let style: DayCellStyle
    private let isToday: Bool
    private let stateDescription: String?

    /// - Parameters:
    ///   - stateDescription: localized wording for VoiceOver, supplied by the
    ///     feature layer since the design system has no domain vocabulary.
    public init(day: Int, style: DayCellStyle, isToday: Bool = false, stateDescription: String? = nil) {
        self.day = day
        self.style = style
        self.isToday = isToday
        self.stateDescription = stateDescription
    }

    private var isOutlined: Bool { isToday && style.isPlaceholder }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
        Text("\(day)")
            .textStyle(Theme.Typography.numeric)
            .foregroundStyle(isOutlined ? Theme.Color.dayTodayRing : style.foreground)
            .frame(minWidth: Theme.Size.dayCell, minHeight: Theme.Size.dayCell)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(shape.fill(isOutlined ? Theme.Color.backgroundPrimary : style.fill))
            .overlay(shape.strokeBorder(Theme.Color.dayTodayRing, lineWidth: isToday ? Theme.Stroke.ring : 0))
            .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = ["\(day)"]
        if let stateDescription { parts.append(stateDescription) }
        if isToday { parts.append("today") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Cooldown ring

/// Time remaining on a lock. Calm by design: one colour, no pulsing, no red.
public struct CooldownRing: View {
    private let remaining: TimeInterval
    private let total: TimeInterval
    private let caption: String?

    public init(remaining: TimeInterval, total: TimeInterval, caption: String? = nil) {
        self.remaining = max(0, remaining)
        self.total = max(1, total)
        self.caption = caption
    }

    private var fraction: CGFloat { CGFloat(min(1, remaining / total)) }
    private var timeText: String {
        let s = Int(remaining.rounded())
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    public var body: some View {
        ZStack {
            Circle().stroke(Theme.Color.backgroundSecondary, lineWidth: Theme.Stroke.cooldownRing)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    Theme.Color.accentPrimary, style: StrokeStyle(lineWidth: Theme.Stroke.cooldownRing, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: fraction)
            VStack(spacing: Theme.Spacing.xxs) {
                Text(timeText).textStyle(Theme.Typography.titleL).contentTransition(.numericText())
                if let caption {
                    Text(caption).textStyle(Theme.Typography.caption).foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .foregroundStyle(Theme.Color.textPrimary)
        }
        .frame(width: Theme.Size.cooldownRing, height: Theme.Size.cooldownRing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timeText) remaining\(caption.map { ", \($0)" } ?? "")")
    }
}

// MARK: - Step progress

/// Segmented progress for the protocol: done segments in success, the current
/// one in reward, the rest as sunken background.
public struct StepProgress: View {
    private let total: Int
    private let completed: Int

    public init(total: Int, completed: Int) {
        self.total = max(1, total)
        self.completed = min(max(0, completed), total)
    }

    public var body: some View {
        HStack(spacing: Theme.Spacing.xxs + 2) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(
                        i < completed
                            ? Theme.Color.success
                            : (i == completed ? Theme.Color.reward : Theme.Color.backgroundSecondary)
                    )
                    .frame(height: Theme.Size.progressSegmentHeight)
            }
        }
        .animation(Theme.Motion.pop, value: completed)
        .accessibilityLabel("Task \(min(completed + 1, total)) of \(total)")
    }
}
