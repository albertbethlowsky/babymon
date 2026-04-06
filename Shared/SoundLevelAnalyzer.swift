import Foundation

/// Analyzes PCM audio buffers for sound level and cry detection.
/// Works on both iOS and watchOS.
class SoundLevelAnalyzer: ObservableObject {
    @Published var currentLevel: Float = 0       // 0.0 to 1.0 normalized
    @Published var isCryDetected: Bool = false

    /// Threshold (0-1) above which we consider it a "cry". Default 0.35.
    var sensitivity: Float = 0.35

    /// Minimum seconds between cry alerts to avoid spamming.
    var cooldownSeconds: TimeInterval = 15

    /// How many consecutive loud buffers needed before triggering.
    private let requiredLoudBuffers = 3
    private var consecutiveLoudCount = 0
    private var lastAlertTime: Date = .distantPast

    var onCryDetected: (() -> Void)?

    /// Analyze a buffer of 16-bit PCM samples. Call from the audio capture callback.
    func analyze(int16Data data: Data) {
        let level = computeRMS(data: data)

        DispatchQueue.main.async {
            self.currentLevel = level
        }

        if level >= sensitivity {
            consecutiveLoudCount += 1
        } else {
            consecutiveLoudCount = max(0, consecutiveLoudCount - 1)
        }

        if consecutiveLoudCount >= requiredLoudBuffers {
            let now = Date()
            if now.timeIntervalSince(lastAlertTime) >= cooldownSeconds {
                lastAlertTime = now
                consecutiveLoudCount = 0
                DispatchQueue.main.async {
                    self.isCryDetected = true
                    self.onCryDetected?()
                }
                // Reset after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.isCryDetected = false
                }
            }
        }
    }

    private func computeRMS(data: Data) -> Float {
        let sampleCount = data.count / MemoryLayout<Int16>.size
        guard sampleCount > 0 else { return 0 }

        var sumSquares: Float = 0
        data.withUnsafeBytes { rawBuffer in
            guard let samples = rawBuffer.baseAddress?.assumingMemoryBound(to: Int16.self) else { return }
            for i in 0..<sampleCount {
                let normalized = Float(samples[i]) / Float(Int16.max)
                sumSquares += normalized * normalized
            }
        }

        let rms = sqrt(sumSquares / Float(sampleCount))
        // Map RMS to 0-1 range (typical speech ~0.05-0.15, cry ~0.2-0.5)
        return min(rms * 4.0, 1.0)
    }
}
