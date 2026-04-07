import XCTest
@testable import Babymon

final class SoundLevelAnalyzerTests: XCTestCase {

    // MARK: - RMS Computation

    func testSilenceReturnsZero() {
        let analyzer = SoundLevelAnalyzer()
        let silence = makeInt16Data(samples: Array(repeating: 0, count: 1024))
        analyzer.analyze(int16Data: silence)

        let expectation = XCTestExpectation(description: "Level updates on main queue")
        DispatchQueue.main.async {
            XCTAssertEqual(analyzer.currentLevel, 0.0, accuracy: 0.001)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testEmptyDataReturnsZero() {
        let analyzer = SoundLevelAnalyzer()
        analyzer.analyze(int16Data: Data())

        let expectation = XCTestExpectation(description: "Level updates on main queue")
        DispatchQueue.main.async {
            XCTAssertEqual(analyzer.currentLevel, 0.0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testMaxAmplitudeReturnsOne() {
        let analyzer = SoundLevelAnalyzer()
        let loud = makeInt16Data(samples: Array(repeating: Int16.max, count: 1024))
        analyzer.analyze(int16Data: loud)

        let expectation = XCTestExpectation(description: "Level updates on main queue")
        DispatchQueue.main.async {
            // RMS of all max values = 1.0, scaled by 4x = 4.0, clamped to 1.0
            XCTAssertEqual(analyzer.currentLevel, 1.0, accuracy: 0.01)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testModerateAmplitude() {
        let analyzer = SoundLevelAnalyzer()
        // ~25% amplitude → RMS ≈ 0.25, scaled by 4 → 1.0 (clamped)
        // Use ~10% amplitude → RMS ≈ 0.1, scaled by 4 → 0.4
        let moderate = makeInt16Data(samples: Array(repeating: Int16(Int16.max / 10), count: 1024))
        analyzer.analyze(int16Data: moderate)

        let expectation = XCTestExpectation(description: "Level updates on main queue")
        DispatchQueue.main.async {
            XCTAssertGreaterThan(analyzer.currentLevel, 0.1)
            XCTAssertLessThan(analyzer.currentLevel, 0.8)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testNegativeSamplesContribute() {
        let analyzer = SoundLevelAnalyzer()
        // Negative samples should have same RMS as positive (squared)
        let negative = makeInt16Data(samples: Array(repeating: Int16.min + 1, count: 1024))
        analyzer.analyze(int16Data: negative)

        let expectation = XCTestExpectation(description: "Level updates on main queue")
        DispatchQueue.main.async {
            XCTAssertGreaterThan(analyzer.currentLevel, 0.9)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Cry Detection

    func testNoCryOnQuietAudio() {
        let analyzer = SoundLevelAnalyzer()
        analyzer.sensitivity = 0.35

        var cryTriggered = false
        analyzer.onCryDetected = { cryTriggered = true }

        let silence = makeInt16Data(samples: Array(repeating: 0, count: 1024))
        for _ in 0..<10 {
            analyzer.analyze(int16Data: silence)
        }

        let expectation = XCTestExpectation(description: "Wait for main queue")
        DispatchQueue.main.async {
            XCTAssertFalse(cryTriggered)
            XCTAssertFalse(analyzer.isCryDetected)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testCryDetectedAfterConsecutiveLoudBuffers() {
        let analyzer = SoundLevelAnalyzer()
        analyzer.sensitivity = 0.3
        analyzer.cooldownSeconds = 0 // Disable cooldown for test

        let cryExpectation = XCTestExpectation(description: "Cry detected callback")
        analyzer.onCryDetected = {
            cryExpectation.fulfill()
        }

        // Send loud buffers (max amplitude → level = 1.0, well above 0.3 threshold)
        let loud = makeInt16Data(samples: Array(repeating: Int16.max, count: 1024))
        for _ in 0..<5 {
            analyzer.analyze(int16Data: loud)
        }

        wait(for: [cryExpectation], timeout: 2.0)
    }

    func testNoCryWithOnlyTwoLoudBuffers() {
        let analyzer = SoundLevelAnalyzer()
        analyzer.sensitivity = 0.3

        var cryTriggered = false
        analyzer.onCryDetected = { cryTriggered = true }

        // Send only 2 loud buffers (need 3 consecutive)
        let loud = makeInt16Data(samples: Array(repeating: Int16.max, count: 1024))
        analyzer.analyze(int16Data: loud)
        analyzer.analyze(int16Data: loud)

        // Then send quiet
        let silence = makeInt16Data(samples: Array(repeating: 0, count: 1024))
        analyzer.analyze(int16Data: silence)

        let expectation = XCTestExpectation(description: "Wait for main queue")
        DispatchQueue.main.async {
            XCTAssertFalse(cryTriggered)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testCooldownPreventsRepeatedAlerts() {
        let analyzer = SoundLevelAnalyzer()
        analyzer.sensitivity = 0.3
        analyzer.cooldownSeconds = 60 // Long cooldown

        var cryCount = 0
        analyzer.onCryDetected = { cryCount += 1 }

        let loud = makeInt16Data(samples: Array(repeating: Int16.max, count: 1024))

        // First round: should trigger
        for _ in 0..<5 { analyzer.analyze(int16Data: loud) }

        // Second round: should NOT trigger (cooldown)
        for _ in 0..<5 { analyzer.analyze(int16Data: loud) }

        let expectation = XCTestExpectation(description: "Wait for main queue")
        DispatchQueue.main.async {
            XCTAssertEqual(cryCount, 1, "Should only trigger once due to cooldown")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testCustomSensitivity() {
        let analyzer = SoundLevelAnalyzer()
        analyzer.sensitivity = 0.9 // Very high threshold
        analyzer.cooldownSeconds = 0

        var cryTriggered = false
        analyzer.onCryDetected = { cryTriggered = true }

        // Moderate audio that would trigger at default (0.35) but not at 0.9
        let moderate = makeInt16Data(samples: Array(repeating: Int16(Int16.max / 5), count: 1024))
        for _ in 0..<10 {
            analyzer.analyze(int16Data: moderate)
        }

        let expectation = XCTestExpectation(description: "Wait for main queue")
        DispatchQueue.main.async {
            XCTAssertFalse(cryTriggered, "Should not trigger with high sensitivity threshold")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeInt16Data(samples: [Int16]) -> Data {
        var data = Data(capacity: samples.count * MemoryLayout<Int16>.size)
        for sample in samples {
            var s = sample
            data.append(Data(bytes: &s, count: MemoryLayout<Int16>.size))
        }
        return data
    }
}
