import AVFoundation

class WatchAudioCaptureManager: ObservableObject {
    var onAudioReady: ((Data) -> Void)?

    let soundAnalyzer = SoundLevelAnalyzer()

    private var engine: AVAudioEngine?
    private let targetFormat = makeAudioFormat()

    func startCapture() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .default)
        try? audioSession.setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // If input format matches target, tap directly; otherwise convert
        if inputFormat.sampleRate == audioSampleRate && inputFormat.channelCount == audioChannels {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: targetFormat) { [weak self] buffer, _ in
                self?.sendBuffer(buffer)
            }
        } else {
            // Tap in native format and convert
            guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else { return }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                guard let self else { return }
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

        try? engine.start()
        self.engine = engine
    }

    private func sendBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.int16ChannelData else { return }
        let byteCount = Int(buffer.frameLength) * MemoryLayout<Int16>.size
        let data = Data(bytes: channelData[0], count: byteCount)

        // Analyze sound level for cry detection
        soundAnalyzer.analyze(int16Data: data)

        onAudioReady?(prefixData(.audio, data))
    }

    func stopCapture() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
    }
}
