import AVFoundation
import UIKit

class CameraCaptureManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    var onFrameReady: ((Data) -> Void)?
    var onAudioReady: ((Data) -> Void)?

    private let videoQueue = DispatchQueue(label: "com.babymon.video")
    private let audioQueue = DispatchQueue(label: "com.babymon.audio")
    private var lastFrameTime: CFAbsoluteTime = 0
    private let ciContext = CIContext()
    private let frameInterval: CFAbsoluteTime

    override init() {
        frameInterval = 1.0 / Double(videoFPS)
        super.init()
    }

    func startCapture() {
        session.beginConfiguration()
        session.sessionPreset = .medium

        // Video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)

        // Audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              session.canAddInput(audioInput) else { return }
        session.addInput(audioInput)

        // Video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)

        // Audio output
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        guard session.canAddOutput(audioOutput) else { return }
        session.addOutput(audioOutput)

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stopCapture() {
        session.stopRunning()
    }

    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastFrameTime >= frameInterval else { return }
        lastFrameTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let scaleX = CGFloat(videoWidth) / ciImage.extent.width
        let scaleY = CGFloat(videoHeight) / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = ciContext.createCGImage(scaled, from: CGRect(x: 0, y: 0, width: videoWidth, height: videoHeight)) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        guard let jpegData = uiImage.jpegData(compressionQuality: jpegQuality) else { return }

        onFrameReady?(prefixData(.video, jpegData))
    }

    private func processAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        let length = CMBlockBufferGetDataLength(blockBuffer)
        var data = Data(count: length)
        data.withUnsafeMutableBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: baseAddress)
        }
        onAudioReady?(prefixData(.audio, data))
    }
}

extension CameraCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output is AVCaptureVideoDataOutput {
            processVideoFrame(sampleBuffer)
        } else if output is AVCaptureAudioDataOutput {
            processAudioBuffer(sampleBuffer)
        }
    }
}
