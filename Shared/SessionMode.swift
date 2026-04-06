import Foundation

enum SessionMode: String, Codable {
    case phoneSource
    case watchSource
}

enum MessageType: UInt8 {
    case video = 0x01
    case audio = 0x02
    case control = 0x03
    case cryAlert = 0x04
}

func prefixData(_ type: MessageType, _ payload: Data) -> Data {
    var data = Data([type.rawValue])
    data.append(payload)
    return data
}

func parseData(_ data: Data) -> (MessageType, Data)? {
    guard let first = data.first, let type = MessageType(rawValue: first) else {
        return nil
    }
    return (type, data.dropFirst())
}
