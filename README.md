# ExternalVideoOutput

A Swift Package Manager library for iOS 15+ that outputs `CIImage` frames to an external display connected via USB-C → HDMI, similar to Blackmagic Camera.

---

## Features

- Renders `CIImage` frames directly to an external `UIScreen` using **Metal** and **Core Image**
- No conversion to `UIImage`, `CGImage`, or `CVPixelBuffer`
- Dedicated `UIWindow` on the external screen — main app UI is **completely unchanged**
- `CADisplayLink`-based rendering at up to **60 FPS**
- Thread-safe, lock-based frame queue — drops old frames, never blocks the caller
- Automatic connect/disconnect handling via `UIScreen` notifications
- `.aspectFit` and `.aspectFill` content modes
- No ReplayKit, AirPlay, screen mirroring, or screen capture

---

## Architecture

```
CIImage
   ├── Main app preview (unchanged)
   └── ExternalVideoOutput
          ↓
      Metal / CIContext
          ↓
      CAMetalLayer
          ↓
      External UIScreen
          ↓
      USB-C → HDMI
```

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/noho501/ExternalVideoOutput.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Packages…** and enter the repository URL.

---

## Usage

```swift
import ExternalVideoOutput

// Start observing external display connections
ExternalVideoOutput.shared.start()

// In your video/camera callback (any thread):
ExternalVideoOutput.shared.render(ciImage)

// Stop and release resources
ExternalVideoOutput.shared.stop()

// Check connection state
if ExternalVideoOutput.shared.isConnected {
    // External display is connected
}

// Configure content mode (default: .aspectFit)
ExternalVideoOutput.shared.contentMode = .aspectFill
```

---

## Example App

The `Example/` directory contains a complete iOS app using `AVFoundation`:

- Requests camera permission
- Shows a normal camera preview on the iPhone
- Sends every `CIImage` frame to `ExternalVideoOutput`
- Displays clean camera video on the USB-C → HDMI external display
- Detects connect/disconnect automatically
- Shows connection status and FPS on screen

Open `Example/ExternalVideoOutputExample` in Xcode, set your team, and run on a real device.

---

## API Reference

```swift
public final class ExternalVideoOutput {
    public static let shared: ExternalVideoOutput

    /// Whether an external display is currently connected.
    public var isConnected: Bool { get }

    /// Content scaling mode. Default is `.aspectFit`.
    public var contentMode: ExternalVideoContentMode { get set }

    /// Begin observing external display connections and start rendering.
    public func start()

    /// Submit a CIImage frame for output on the external display.
    /// Non-blocking — drops the previous pending frame if not yet rendered.
    public func render(_ image: CIImage)

    /// Stop rendering and release all resources.
    public func stop()
}

public enum ExternalVideoContentMode {
    case aspectFit   // Letterbox/pillarbox (default)
    case aspectFill  // Crop to fill
}
```

---

## Requirements

| | |
|---|---|
| Platform | iOS 15+ |
| Language | Swift 5.7+ |
| Frameworks | Metal, Core Image, UIKit |

---

## Limitations

- Requires a physical USB-C → HDMI adapter and external display; there is no simulator support for external `UIScreen`.
- `CADisplayLink` runs on the main run loop; keep `render()` calls lightweight.
- The library uses `UIScreen.screens` which is deprecated in iOS 16 but remains functional; a `UIWindowScene`-based API may be added in a future version.

---

## License

MIT