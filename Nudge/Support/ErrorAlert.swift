import NudgeCore
import SwiftUI

/// The single way errors reach the user.
///
/// Errors are thrown (`async`/`await` + `throws`) and surface here; screens do
/// not build their own alerts.
struct ErrorAlert: ViewModifier {
    @Binding var error: NudgeError?

    func body(content: Content) -> some View {
        content.alert(
            "Something went wrong",
            isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            ),
            presenting: error
        ) { _ in
            Button("OK", role: .cancel) { error = nil }
        } message: { error in
            Text(error.errorDescription ?? "")
        }
    }
}

extension View {
    func errorAlert(_ error: Binding<NudgeError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}
