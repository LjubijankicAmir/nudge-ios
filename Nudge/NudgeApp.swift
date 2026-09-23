import NudgeCore
import SwiftUI

@main
struct NudgeApp: App {
    /// Built once at launch. A failure here means the App Group is unavailable,
    /// which is unrecoverable, so the app explains itself rather than limping on.
    private let composition: Result<CompositionRoot, NudgeError>

    init() {
        composition = Result {
            try CompositionRoot()
        }
        .mapError { $0 as? NudgeError ?? .appGroupUnavailable(identifier: AppGroup.identifier) }
    }

    var body: some Scene {
        WindowGroup {
            switch composition {
            case .success(let composition):
                RootView(composition: composition)
                    .onOpenURL { url in
                        composition.router.handle(deepLink: url)
                    }
            case .failure(let error):
                StartupFailureView(error: error)
            }
        }
    }
}
