import UIKit
import AVFoundation
import CoreImage
import ExternalVideoOutput

final class CameraViewController: UIViewController {

    // MARK: - Camera

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session")

    // MARK: - Preview

    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - UI

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - FPS tracking

    private var frameCount = 0
    private var lastFPSDate = Date()
    private var currentFPS: Int = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupStatusLabel()
        requestCameraPermission()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ExternalVideoOutput.shared.start()
        startFPSTimer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ExternalVideoOutput.shared.stop()
        captureSession.stopRunning()
    }

    // MARK: - Layout

    private func setupStatusLabel() {
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        ])
    }

    // MARK: - Camera setup

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupCamera()
                } else {
                    self?.statusLabel.text = "Camera access denied"
                }
            }
        }
    }

    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1920x1080

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device)
            else {
                DispatchQueue.main.async { self.statusLabel.text = "Camera not available" }
                return
            }

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }

            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frames"))
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            DispatchQueue.main.async { self.setupPreviewLayer() }
        }
    }

    private func setupPreviewLayer() {
        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
        view.bringSubviewToFront(statusLabel)
    }

    // MARK: - FPS timer

    private func startFPSTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    private func updateStatus() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFPSDate)
        currentFPS = elapsed > 0 ? Int(Double(frameCount) / elapsed) : 0
        frameCount = 0
        lastFPSDate = now

        let connected = ExternalVideoOutput.shared.isConnected
        let connectedText = connected ? "🟢 Connected" : "🔴 Disconnected"
        statusLabel.text = "\(connectedText)\nFPS: \(currentFPS)"
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        ExternalVideoOutput.shared.render(ciImage)

        frameCount += 1
    }
}
