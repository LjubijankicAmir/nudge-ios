import DesignSystem
import NudgeCore
import SwiftUI

/// Shown when the object graph cannot be built at all — in practice, a missing
/// App Group capability. The app genuinely cannot function, so this is an
/// explanation rather than a retry.
struct StartupFailureView: View {
    let error: NudgeError

    var body: some View {
        ZStack {
            Theme.Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.md) {
                IconCircle("exclamationmark.triangle.fill", tone: .danger)
                Text("Nudge can't start")
                    .textStyle(Theme.Typography.titleL)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(error.errorDescription ?? "")
                    .textStyle(Theme.Typography.bodyM)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.xl)
        }
    }
}
