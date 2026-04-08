import AVFoundation
import UIKit

class CameraCaptureManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    var onFrameReady: ((Data) -> Void)?
    var onAudioReady: ((Data) -> Void)?

    @Published var isNightMode = false
    @Published var isTorchOn = false

    private let videoQueue = DispatchQueue(label: "com.babymon.video")
    private let audioQueue = DispatchQueue(label: "com.babymon.audio")
    private var lastFrameTime: CFAbsoluteTime = 0
    private let ciContext = CIContext()
    private let frameInterval: CFAbsoluteTime
    private var videoDevice: AVCaptureDevice?
    private var interruptionObserver: NSObjectProtocol?

    override init() {
        frameInterval = 1.0 / Double(videoFPS)
        super.init()
    }

    func startCapture() {
        configureAudioSession()
        observeInterruptions()

        session.beginConfiguration()
        session.sessionPreset = .medium

        // Video input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)
        videoDevice = device

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
        if isTorchOn { setTorch(on: false) }
        session.stopRunning()
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
    }

    // MARK: - Audio Session for Background

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // .playAndRecord allows both mic capture and speaker output
            // .defaultToSpeaker routes to speaker (not earpiece)
            // .allowBluetooth allows BT headphones
            try audioSession.setCategory(
                .playAndRecord,
                mode: .videoRecording,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            print("CameraCapture audio session error: \(error)")
        }
    }

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
                // Capture session handles this automatically
                break
            case .ended:
                guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    configureAudioSession()
                    if !session.isRunning {
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.session.startRunning()
                        }
                    }
                }
            @unknown default:
                break
            }
        }
    }

    // MARK: - Night Mode

    func toggleNightMode() {
        isNightMode.toggle()
        if isNightMode {
            enableNightMode()
        } else {
            disableNightMode()
        }
    }

    private func enableNightMode() {
        guard let device = videoDevice else { return }
        do {
            try device.lockForConfiguration()

            // Max out exposure for low-light
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.setExposureTargetBias(device.maxExposureTargetBias * 0.7, completionHandler: nil)

            // Slower frame rate allows longer exposure per frame
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 4) // 4fps min
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 4)

            // Max ISO
            let maxISO = device.activeFormat.maxISO
            if device.isExposureModeSupported(.custom) {
                device.setExposureModeCustom(
                    duration: AVCaptureDevice.currentExposureDuration,
                    iso: min(maxISO, 1600),
                    completionHandler: nil
                )
            }

            device.unlockForConfiguration()

            // Turn on torch at low level for infrared-like illumination
            setTorch(on: true, level: 0.1)
        } catch {
            print("Night mode config error: \(error)")
        }
    }

    private func disableNightMode() {
        guard let device = videoDevice else { return }
        do {
            try device.lockForConfiguration()

            // Reset to auto exposure
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.setExposureTargetBias(0, completionHandler: nil)

            // Reset frame rate
            device.activeVideoMinFrameDuration = .invalid
            device.activeVideoMaxFrameDuration = .invalid

            device.unlockForConfiguration()

            setTorch(on: false)
        } catch {
            print("Reset camera config error: \(error)")
        }
    }

    func setTorch(on: Bool, level: Float = 0.1) {
        guard let device = videoDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: level)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
            DispatchQueue.main.async { self.isTorchOn = on }
        } catch {
            print("Torch error: \(error)")
        }
    }

    // MARK: - Frame Processing

    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastFrameTime >= frameInterval else { return }
        lastFrameTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // In night mode, boost brightness and apply green tint for night-vision look
        if isNightMode {
            ciImage = applyNightVisionFilter(to: ciImage)
        }

        let scaleX = CGFloat(videoWidth) / ciImage.extent.width
        let scaleY = CGFloat(videoHeight) / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = ciContext.createCGImage(scaled, from: CGRect(x: 0, y: 0, width: videoWidth, height: videoHeight)) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        guard let jpegData = uiImage.jpegData(compressionQuality: jpegQuality) else { return }

        onFrameReady?(prefixData(.video, jpegData))
    }

    private func applyNightVisionFilter(to image: CIImage) -> CIImage {
        var result = image

        // Boost exposure
        if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
            exposureFilter.setValue(result, forKey: kCIInputImageKey)
            exposureFilter.setValue(1.5, forKey: kCIInputEVKey)
            if let output = exposureFilter.outputImage {
                result = output
            }
        }

        // Green tint via color matrix (classic night-vision)
        if let colorMatrix = CIFilter(name: "CIColorMatrix") {
            colorMatrix.setValue(result, forKey: kCIInputImageKey)
            colorMatrix.setValue(CIVector(x: 0.2, y: 0, z: 0, w: 0), forKey: "inputRVector")
            colorMatrix.setValue(CIVector(x: 0, y: 0.8, z: 0, w: 0), forKey: "inputGVector")
            colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0.2, w: 0), forKey: "inputBVector")
            if let output = colorMatrix.outputImage {
                result = output
            }
        }

        return result
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
