import AVFoundation

class WatchAudioCaptureManager: ObservableObject {
    var onAudioReady: ((Data) -> Void)?

    let soundAnalyzer = SoundLevelAnalyzer()
    let cryClassifier = CryClassifier()

    private var engine: AVAudioEngine?
    private let targetFormat = makeAudioFormat()
    private var interruptionObserver: NSObjectProtocol?

    func startCapture() {
        configureAudioSession()
        observeInterruptions()
        startEngine()
    }

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Watch audio session error: \(error)")
        }
    }

    private func startEngine() {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Prepare cry classifier with native input format
        cryClassifier.prepare(format: inputFormat)

        // If input format matches target, tap directly; otherwise convert
        if inputFormat.sampleRate == audioSampleRate && inputFormat.channelCount == audioChannels {
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: targetFormat) { [weak self] buffer, time in
                self?.cryClassifier.analyze(buffer: buffer, at: time.sampleTime)
                self?.sendBuffer(buffer)
            }
        } else {
            // Tap in native format and convert
            guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else { return }

            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
                guard let self else { return }

                // Feed native format to classifier
                cryClassifier.analyze(buffer: buffer, at: time.sampleTime)

                // Convert for streaming
                let frameCount = UInt32(Double(buffer.frameLength) * audioSampleRate / inputFormat.sampleRate)
                guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else { return }

                var error: NSError?
                converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }

                if error == nil {
                    self.sendBuffer(convertedBuffer)
                }
            }
        }

        do {
            try engine.start()
            self.engine = engine
        } catch {
            print("Watch audio engine start error: \(error)")
        }
    }

    private func sendBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.int16ChannelData else { return }
        let byteCount = Int(buffer.frameLength) * MemoryLayout<Int16>.size
        let data = Data(bytes: channelData[0], count: byteCount)

        // RMS-based level for UI visualization
        soundAnalyzer.analyze(int16Data: data)

        onAudioReady?(prefixData(.audio, data))
    }

    func stopCapture() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        cryClassifier.stop()
        engine = nil

        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
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

            switch type {
            case .began:
                // Audio interrupted — engine paused
                break
            case .ended:
                guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    self.restartAfterInterruption()
                }
            @unknown default:
                break
            }
        }
    }

    private func restartAfterInterruption() {
        // Tear down and rebuild to get a clean engine state
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil

        configureAudioSession()
        startEngine()
    }
}
