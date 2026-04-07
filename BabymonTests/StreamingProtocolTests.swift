import XCTest
@testable import Babymon

final class StreamingProtocolTests: XCTestCase {

    func testAudioConstants() {
        XCTAssertEqual(audioSampleRate, 16000)
        XCTAssertEqual(audioChannels, 1)
    }

    func testVideoConstants() {
        XCTAssertEqual(videoFPS, 8)
        XCTAssertEqual(jpegQuality, 0.4, accuracy: 0.001)
        XCTAssertEqual(videoWidth, 160)
        XCTAssertEqual(videoHeight, 120)
    }

    func testMakeAudioFormat() {
        let format = makeAudioFormat()
        XCTAssertEqual(format.sampleRate, 16000)
        XCTAssertEqual(format.channelCount, 1)
        XCTAssertTrue(format.isInterleaved)
        // PCM Int16 = 2 bytes per frame per channel
        XCTAssertEqual(format.streamDescription.pointee.mBitsPerChannel, 16)
    }
}
