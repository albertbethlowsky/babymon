import XCTest
@testable import Babymon

final class SessionModeTests: XCTestCase {

    // MARK: - SessionMode

    func testSessionModeRawValues() {
        XCTAssertEqual(SessionMode.phoneSource.rawValue, "phoneSource")
        XCTAssertEqual(SessionMode.watchSource.rawValue, "watchSource")
    }

    func testSessionModeFromRawValue() {
        XCTAssertEqual(SessionMode(rawValue: "phoneSource"), .phoneSource)
        XCTAssertEqual(SessionMode(rawValue: "watchSource"), .watchSource)
        XCTAssertNil(SessionMode(rawValue: "invalid"))
    }

    func testSessionModeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let original = SessionMode.phoneSource
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SessionMode.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - MessageType

    func testMessageTypeRawValues() {
        XCTAssertEqual(MessageType.video.rawValue, 0x01)
        XCTAssertEqual(MessageType.audio.rawValue, 0x02)
        XCTAssertEqual(MessageType.control.rawValue, 0x03)
        XCTAssertEqual(MessageType.cryAlert.rawValue, 0x04)
    }

    func testMessageTypeFromRawValue() {
        XCTAssertEqual(MessageType(rawValue: 0x01), .video)
        XCTAssertEqual(MessageType(rawValue: 0x04), .cryAlert)
        XCTAssertNil(MessageType(rawValue: 0xFF))
    }

    // MARK: - Data Framing

    func testPrefixDataAddsTypeByte() {
        let payload = Data([0xAA, 0xBB])
        let result = prefixData(.video, payload)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0], 0x01) // video type byte
        XCTAssertEqual(result[1], 0xAA)
        XCTAssertEqual(result[2], 0xBB)
    }

    func testPrefixDataWithEmptyPayload() {
        let result = prefixData(.cryAlert, Data())
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], 0x04)
    }

    func testParseDataExtractsTypeAndPayload() {
        let data = Data([0x02, 0xCC, 0xDD])
        let result = parseData(data)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, .audio)
        XCTAssertEqual(result?.1, Data([0xCC, 0xDD]))
    }

    func testParseDataWithEmptyPayload() {
        let data = Data([0x04])
        let result = parseData(data)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, .cryAlert)
        XCTAssertEqual(result?.1.count, 0)
    }

    func testParseDataWithInvalidType() {
        let data = Data([0xFF, 0xAA])
        XCTAssertNil(parseData(data))
    }

    func testParseDataWithEmptyData() {
        XCTAssertNil(parseData(Data()))
    }

    func testPrefixParseRoundTrip() {
        let originalPayload = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let prefixed = prefixData(.audio, originalPayload)
        let parsed = parseData(prefixed)

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.0, .audio)
        XCTAssertEqual(parsed?.1, originalPayload)
    }

    func testPrefixParseRoundTripAllTypes() {
        let payload = Data(repeating: 0x42, count: 100)

        for type in [MessageType.video, .audio, .control, .cryAlert] {
            let prefixed = prefixData(type, payload)
            let parsed = parseData(prefixed)
            XCTAssertEqual(parsed?.0, type)
            XCTAssertEqual(parsed?.1, payload)
        }
    }
}
