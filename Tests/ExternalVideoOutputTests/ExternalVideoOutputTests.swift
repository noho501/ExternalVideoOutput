import XCTest
@testable import ExternalVideoOutput

final class ExternalVideoOutputTests: XCTestCase {

    func testSharedInstanceIsSingleton() {
        XCTAssertTrue(ExternalVideoOutput.shared === ExternalVideoOutput.shared)
    }

    func testIsConnectedDefaultsFalse() {
        // Without an external screen in a test environment, isConnected should be false.
        XCTAssertFalse(ExternalVideoOutput.shared.isConnected)
    }

    func testDefaultContentMode() {
        let output = ExternalVideoOutput.shared
        // Default content mode should be .aspectFit
        XCTAssertEqual(output.contentMode, ExternalVideoContentMode.aspectFit)
    }

    func testContentModeChange() {
        let output = ExternalVideoOutput.shared
        output.contentMode = .aspectFill
        XCTAssertEqual(output.contentMode, .aspectFill)
        // Reset
        output.contentMode = .aspectFit
    }

    func testRenderDoesNotCrashWhenNotConnected() {
        // Rendering without an external display connected should be a no-op.
        let image = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertNoThrow(ExternalVideoOutput.shared.render(image))
    }

    func testStartAndStopDoNotCrash() {
        XCTAssertNoThrow(ExternalVideoOutput.shared.start())
        XCTAssertNoThrow(ExternalVideoOutput.shared.stop())
    }
}
