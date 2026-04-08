import AVFoundation

class WatchAudioPlayerManager: ObservableObject {
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let format = makeAudioFormat()
    private var interruptionObserver: NSObjectProtocol?

    func setup() {
        configureAudioSession()
        setupEngine()
        observeInterruptions()
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

        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
    }

    // MARK: - Setup

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Watch audio player session error: \(error)")
        }
    }

    private func setupEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            player.play()
            self.engine = engine
            self.playerNode = player
        } catch {
            print("Watch audio player engine error: \(error)")
        }
    }

    // MARK: - Interruption Handling

    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            if type == .ended {
                guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    configureAudioSession()
                    do {
                        try engine?.start()
                        playerNode?.play()
                    } catch {
                        setupEngine()
                    }
                }
            }
        }
    }
}
