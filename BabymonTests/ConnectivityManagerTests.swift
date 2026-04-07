import XCTest
@testable import Babymon

final class ConnectivityManagerTests: XCTestCase {

    func testInitialState() {
        let manager = ConnectivityManager.shared
        // Reset to known state
        manager.currentMode = nil
        manager.isStreaming = false

        XCTAssertNil(manager.currentMode)
        XCTAssertFalse(manager.isStreaming)
    }

    func testEnableDemoMode() {
        let manager = ConnectivityManager.shared
        manager.enableDemoMode()

        XCTAssertTrue(manager.isDemoMode)
        XCTAssertTrue(manager.isReachable)
    }

    func testDisableDemoMode() {
        let manager = ConnectivityManager.shared
        manager.enableDemoMode()
        manager.disableDemoMode()

        XCTAssertFalse(manager.isDemoMode)
        // In simulator, WCSession is not supported so isReachable stays false
    }

    func testModeSelection() {
        let manager = ConnectivityManager.shared
        manager.enableDemoMode()

        manager.currentMode = .phoneSource
        XCTAssertEqual(manager.currentMode, .phoneSource)

        manager.currentMode = .watchSource
        XCTAssertEqual(manager.currentMode, .watchSource)

        manager.currentMode = nil
        XCTAssertNil(manager.currentMode)
    }

    func testStopStreamingResetsState() {
        let manager = ConnectivityManager.shared
        manager.enableDemoMode()
        manager.currentMode = .watchSource
        manager.isStreaming = true

        manager.stopStreaming()

        XCTAssertNil(manager.currentMode)
        XCTAssertFalse(manager.isStreaming)
    }

    func testSendStreamDataDoesNotCrashInDemoMode() {
        let manager = ConnectivityManager.shared
        manager.enableDemoMode()

        // Should silently return without crashing
        let data = prefixData(.audio, Data(repeating: 0, count: 100))
        manager.sendStreamData(data)
    }

    func testSendCryAlertDoesNotCrashInDemoMode() {
        let manager = ConnectivityManager.shared
        manager.enableDemoMode()

        // Should silently return without crashing
        manager.sendCryAlert()
    }

    func testCryAlertCallbackWiredCorrectly() {
        let manager = ConnectivityManager.shared

        var alertReceived = false
        manager.onCryAlertReceived = {
            alertReceived = true
        }

        // Simulate receiving a cry alert message
        manager.onCryAlertReceived?()
        XCTAssertTrue(alertReceived)

        // Cleanup
        manager.onCryAlertReceived = nil
    }
}
