import Foundation
import SwiftData

/// Sessions shorter than this are discarded as false starts.
let minSleepSessionDuration: TimeInterval = 120

@Model
final class SleepSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    /// "audio" when phone is the receiver (watch mic), "video" when phone is the camera source.
    var mode: String
    @Relationship(deleteRule: .cascade, inverse: \WakeEvent.session)
    var wakeEvents: [WakeEvent] = []

    init(id: UUID = UUID(), startedAt: Date = Date(), mode: String) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = startedAt
        self.mode = mode
    }

    var duration: TimeInterval { max(0, endedAt.timeIntervalSince(startedAt)) }
    var wakeCount: Int { wakeEvents.count }
}

@Model
final class WakeEvent {
    var id: UUID
    var timestamp: Date
    var session: SleepSession?

    init(id: UUID = UUID(), timestamp: Date = Date(), session: SleepSession? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.session = session
    }
}
