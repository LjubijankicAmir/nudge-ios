import Testing
import UIKit

@testable import DesignSystem

@Suite("Color assets")
struct ColorAssetTests {
    /// Every semantic color must resolve to an asset in the package bundle.
    /// Parameterized so a missing asset names itself in the failure.
    @Test("resolves in the package bundle", arguments: Theme.Color.allAssetNames)
    func colorAssetExists(name: String) {
        #expect(
            UIColor(named: name, in: .module, compatibleWith: nil) != nil,
            "Missing color asset: \(name)"
        )
    }
}
