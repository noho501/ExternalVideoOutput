import UIKit
import Metal
import CoreImage

/// Manages a Metal-based CAMetalLayer that renders CIImage frames
/// to a given UIWindow on an external screen.
final class MetalRenderer {

    // MARK: - Metal objects (created once)

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext
    private let metalLayer: CAMetalLayer

    // MARK: - State

    private(set) var contentMode: ExternalVideoContentMode
    private var displayLink: CADisplayLink?

    /// The latest frame to render. Atomic swap via lock.
    private var pendingImage: CIImage?
    private let frameLock = NSLock()

    // MARK: - Init

    init?(window: UIWindow, contentMode: ExternalVideoContentMode) {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        guard let queue = device.makeCommandQueue() else { return nil }

        self.device = device
        self.commandQueue = queue
        self.ciContext = CIContext(mtlDevice: device, options: [
            .workingColorSpace: NSNull(),
            .outputColorSpace: NSNull()
        ])
        self.contentMode = contentMode

        let layer = CAMetalLayer()
        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.framebufferOnly = false
        layer.frame = window.bounds
        layer.drawableSize = CGSize(
            width: window.bounds.width * window.screen.scale,
            height: window.bounds.height * window.screen.scale
        )
        self.metalLayer = layer

        window.layer.addSublayer(layer)
    }

    // MARK: - Lifecycle

    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        link.preferredFramesPerSecond = 60
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        frameLock.lock()
        pendingImage = nil
        frameLock.unlock()
    }

    // MARK: - Frame submission

    /// Thread-safe. Drops old frame and keeps only the latest.
    func enqueue(_ image: CIImage) {
        frameLock.lock()
        pendingImage = image
        frameLock.unlock()
    }

    // MARK: - Rendering

    @objc private func displayLinkFired() {
        frameLock.lock()
        let image = pendingImage
        pendingImage = nil
        frameLock.unlock()

        guard let image else { return }
        render(image)
    }

    private func render(_ image: CIImage) {
        guard let drawable = metalLayer.nextDrawable() else { return }

        let drawableSize = metalLayer.drawableSize
        let destRect = destinationRect(for: image.extent, in: drawableSize)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        ciContext.render(
            image,
            to: drawable.texture,
            commandBuffer: commandBuffer,
            bounds: CGRect(origin: .zero, size: drawableSize),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Layout helpers

    private func destinationRect(for imageExtent: CGRect, in drawableSize: CGSize) -> CGRect {
        let drawableRect = CGRect(origin: .zero, size: drawableSize)
        guard imageExtent.width > 0, imageExtent.height > 0 else { return drawableRect }

        let scaleX = drawableSize.width / imageExtent.width
        let scaleY = drawableSize.height / imageExtent.height

        let scale: CGFloat
        switch contentMode {
        case .aspectFit:
            scale = min(scaleX, scaleY)
        case .aspectFill:
            scale = max(scaleX, scaleY)
        }

        let scaledWidth = imageExtent.width * scale
        let scaledHeight = imageExtent.height * scale
        let x = (drawableSize.width - scaledWidth) / 2
        let y = (drawableSize.height - scaledHeight) / 2
        return CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
    }

    // MARK: - Layout update

    func updateLayout(for window: UIWindow) {
        metalLayer.frame = window.bounds
        metalLayer.drawableSize = CGSize(
            width: window.bounds.width * window.screen.scale,
            height: window.bounds.height * window.screen.scale
        )
    }
}
