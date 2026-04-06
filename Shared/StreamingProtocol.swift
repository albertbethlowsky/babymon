import AVFoundation

let audioSampleRate: Double = 16000
let audioChannels: AVAudioChannelCount = 1
let videoFPS: Int = 8
let jpegQuality: CGFloat = 0.4
let videoWidth: Int = 160
let videoHeight: Int = 120

func makeAudioFormat() -> AVAudioFormat {
    AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: audioSampleRate, channels: audioChannels, interleaved: true)!
}
