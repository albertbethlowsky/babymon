import AVFoundation

class AudioPlayerManager: ObservableObject {
    @Published var isPlaying = false

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let format = makeAudioFormat()
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?

    func setup() {
        configureAudioSession()
        setupEngine()
        observeInterruptions()
        observeRouteChanges()
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
        }
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        interruptionObserver = nil
        routeChangeObserver = nil

        DispatchQueue.main.async { self.isPlaying = false }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // .playback keeps audio going when screen locks
            // .spokenAudio ducks other audio and resumes after interruptions
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            print("AudioSession config error: \(error)")
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
            DispatchQueue.main.async { self.isPlaying = true }
        } catch {
            print("AudioEngine start error: \(error)")
        }
    }

    // MARK: - Interruption Handling

    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Phone call or Siri — engine is paused automatically
            DispatchQueue.main.async { self.isPlaying = false }

        case .ended:
            // Interruption over — restart the engine
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                restartEngine()
            }

        @unknown default:
            break
        }
    }

    // MARK: - Route Changes

    private func observeRouteChanges() {
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        switch reason {
        case .oldDeviceUnavailable:
            // Headphones unplugged — restart to play through speaker
            restartEngine()
        case .newDeviceAvailable:
            // New output connected — restart to use it
            restartEngine()
        default:
            break
        }
    }

    // MARK: - Recovery

    private func restartEngine() {
        playerNode?.stop()
        engine?.stop()

        configureAudioSession()

        do {
            try engine?.start()
            playerNode?.play()
            DispatchQueue.main.async { self.isPlaying = true }
        } catch {
            print("Engine restart error: \(error)")
            // Full rebuild as last resort
            setupEngine()
        }
    }
}
