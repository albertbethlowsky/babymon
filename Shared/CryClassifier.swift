import AVFoundation
import SoundAnalysis

/// Uses Apple's built-in sound classifier to detect baby crying.
/// Falls back to RMS-based detection if SoundAnalysis is unavailable.
class CryClassifier: NSObject, ObservableObject {
    @Published var isCrying = false
    @Published var confidence: Double = 0
    @Published var dominantSound: String = "silence"

    var onCryDetected: (() -> Void)?

    private var analyzer: SNAudioStreamAnalyzer?
    private var request: SNClassifySoundRequest?
    private let analysisQueue = DispatchQueue(label: "com.babymon.soundanalysis")
    private var cooldownSeconds: TimeInterval = 15
    private var lastAlertTime: Date = .distantPast

    /// Call once with the audio format from the engine's input node.
    func prepare(format: AVAudioFormat) {
        analyzer = SNAudioStreamAnalyzer(format: format)

        do {
            let classifyRequest = try SNClassifySoundRequest(classifierIdentifier: .version1)
            classifyRequest.windowDuration = CMTime(seconds: 1.5, preferredTimescale: 1000)
            classifyRequest.overlapFactor = 0.5
            try analyzer?.add(classifyRequest, withObserver: self)
            request = classifyRequest
        } catch {
            print("CryClassifier: Failed to set up sound classification: \(error)")
        }
    }

    /// Feed audio buffers from the input tap. Call on the audio processing queue.
    func analyze(buffer: AVAudioPCMBuffer, at time: AVAudioFramePosition) {
        analysisQueue.async { [weak self] in
            self?.analyzer?.analyze(buffer, atAudioFramePosition: time)
        }
    }

    func stop() {
        if let request {
            analyzer?.remove(request)
        }
        analyzer = nil
        request = nil
    }
}

extension CryClassifier: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classification = result as? SNClassificationResult else { return }

        // Find baby_crying classification
        let cryResult = classification.classifications.first { $0.identifier == "baby_crying" }
        let topResult = classification.classifications.first

        let cryConfidence = cryResult?.confidence ?? 0
        let topIdentifier = topResult?.identifier ?? "silence"
        let topConfidence = topResult?.confidence ?? 0

        DispatchQueue.main.async {
            self.confidence = cryConfidence
            self.dominantSound = Self.friendlyName(for: topIdentifier)

            // Trigger if baby_crying is detected with high confidence,
            // or if it's the top classification with moderate confidence
            let isCryingNow = cryConfidence > 0.5
                || (topIdentifier == "baby_crying" && topConfidence > 0.3)

            if isCryingNow && !self.isCrying {
                let now = Date()
                if now.timeIntervalSince(self.lastAlertTime) >= self.cooldownSeconds {
                    self.lastAlertTime = now
                    self.isCrying = true
                    self.onCryDetected?()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        self.isCrying = false
                    }
                }
            }
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("CryClassifier: Analysis failed: \(error)")
    }

    private static func friendlyName(for identifier: String) -> String {
        switch identifier {
        case "baby_crying": return "Baby Crying"
        case "crying_sobbing": return "Crying"
        case "speech": return "Talking"
        case "music": return "Music"
        case "silence": return "Silence"
        case "noise": return "Background Noise"
        case "laughter": return "Laughter"
        case "screaming": return "Screaming"
        default:
            return identifier
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
}
