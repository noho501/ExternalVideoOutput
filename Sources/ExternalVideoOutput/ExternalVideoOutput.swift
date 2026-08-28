import CoreImage
import UIKit

/// Outputs CIImage frames to an external display connected via USB-C → HDMI.
///
/// Usage:
/// ```swift
/// ExternalVideoOutput.shared.start()
/// ExternalVideoOutput.shared.render(ciImage)
/// ExternalVideoOutput.shared.stop()
/// ```
public final class ExternalVideoOutput {

    // MARK: - Singleton

    public static let shared = ExternalVideoOutput()

    // MARK: - Public properties

    /// Whether an external display is currently connected.
    public var isConnected: Bool {
        displayManager.externalScreen != nil
    }

    /// Content scaling mode. Default is `.aspectFit`.
    public var contentMode: ExternalVideoContentMode = .aspectFit {
        didSet { renderer?.contentMode = contentMode }
    }

    // MARK: - Private state

    private let displayManager = ExternalDisplayManager()
    private var renderer: MetalRenderer?

    // MARK: - Init

    private init() {}

    // MARK: - Public API

    /// Begin observing external display connections and start rendering.
    public func start() {
        displayManager.onConnect = { [weak self] screen in
            self?.setupRenderer()
        }
        displayManager.onDisconnect = { [weak self] in
            self?.tearDownRenderer()
        }
        displayManager.start()

        // If a screen is already connected, set up renderer immediately
        if displayManager.externalWindow != nil {
            setupRenderer()
        }
    }

    /// Submit a CIImage frame for output on the external display.
    /// Non-blocking. Drops the previous pending frame if not yet rendered.
    public func render(_ image: CIImage) {
        renderer?.enqueue(image)
    }

    /// Stop rendering and release all resources.
    public func stop() {
        tearDownRenderer()
        displayManager.stop()
    }

    // MARK: - Internal helpers

    private func setupRenderer() {
        guard let window = displayManager.externalWindow else { return }
        let r = MetalRenderer(window: window, contentMode: contentMode)
        renderer = r
        r?.start()
    }

    private func tearDownRenderer() {
        renderer?.stop()
        renderer = nil
    }
}
