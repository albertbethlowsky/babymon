import Foundation
import WatchConnectivity

class ConnectivityManager: NSObject, ObservableObject {
    static let shared = ConnectivityManager()

    @Published var isReachable = false
    @Published var currentMode: SessionMode? = nil
    @Published var isStreaming = false

    var onAudioDataReceived: ((Data) -> Void)?
    var onVideoDataReceived: ((Data) -> Void)?
    var onModeReceived: ((SessionMode) -> Void)?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendStreamData(_ data: Data) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessageData(data, replyHandler: nil) { error in
            print("Send error: \(error.localizedDescription)")
        }
    }

    func sendModeSelection(_ mode: SessionMode) {
        guard WCSession.default.isReachable else { return }
        let message = ["mode": mode.rawValue]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Mode send error: \(error.localizedDescription)")
        }
    }

    func stopStreaming() {
        currentMode = nil
        isStreaming = false
        onAudioDataReceived = nil
        onVideoDataReceived = nil
        sendModeSelection(.phoneSource) // Signal stop — counterpart checks for mode change
    }
}

extension ConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let (type, payload) = parseData(messageData) else { return }
        switch type {
        case .video:
            onVideoDataReceived?(payload)
        case .audio:
            onAudioDataReceived?(payload)
        case .control:
            break
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let modeRaw = message["mode"] as? String, let mode = SessionMode(rawValue: modeRaw) {
            DispatchQueue.main.async {
                self.currentMode = mode
                self.onModeReceived?(mode)
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
