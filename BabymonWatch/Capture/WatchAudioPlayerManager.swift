import AVFoundation

class WatchAudioPlayerManager: ObservableObject {
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let format = makeAudioFormat()

    func setup() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default)
        try? audioSession.setActive(true)

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        try? engine.start()
        player.play()

        self.engine = engine
        self.playerNode = player
    }

    func playAudioData(_ data: Data) {
        guard let playerNode else { return }

        let frameCount = UInt32(data.count / MemoryLayout<Int16>.size)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        data.withUnsafeBytes { rawBuffer in
            guard let src = rawBuffer.baseAddress else { return }
            if let channelData = buffer.int16ChannelData {
                memcpy(channelData[0], src, Int(frameCount) * MemoryLayout<Int16>.size)
            }
        }

        playerNode.scheduleBuffer(buffer)
    }

    func stop() {
        playerNode?.stop()
        engine?.stop()
        playerNode = nil
        engine = nil
    }
}
