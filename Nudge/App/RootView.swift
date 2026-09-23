import DesignSystem
import NudgeCore
import SwiftUI

/// Hosts the navigation stack and routes values to screens.
///
/// The real screens do not exist yet; the placeholders below are deliberately
/// thin, and every one of them already draws from design tokens so no literal
/// colours or sizes creep in later.
struct RootView: View {
    let composition: CompositionRoot

    var body: some View {
        @Bindable var router = composition.router

        NavigationStack(path: $router.path) {
            HomePlaceholderView(router: composition.router)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .escapeProtocol:
            PlaceholderScreen(title: "Escape protocol")
        case .settings:
            PlaceholderScreen(title: "Settings")
        case .taskLibrary:
            PlaceholderScreen(title: "Task library")
        case .dayDetail(let day):
            PlaceholderScreen(title: "\(day)")
        case .designSystemGallery:
            DesignSystemGallery()
        }
    }
}

private struct HomePlaceholderView: View {
    let router: AppRouter

    var body: some View {
        ZStack {
            Theme.Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                StreakCounter(
                    days: 0,
                    layout: .hero,
                    detail: String(localized: "Nothing recorded yet")
                )

                Button("Settings") { router.navigate(to: .settings) }
                    .buttonStyle(.nudgeSecondary)

                #if DEBUG
                Button("Design system") { router.navigate(to: .designSystemGallery) }
                    .buttonStyle(.nudgeText)
                #endif
            }
            .padding(Theme.Spacing.xl)
        }
        .navigationTitle("Nudge")
    }
}

private struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        ZStack {
            Theme.Color.backgroundPrimary.ignoresSafeArea()
            Text(title)
                .textStyle(Theme.Typography.titleM)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
