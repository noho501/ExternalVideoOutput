import UIKit

/// Observes UIScreen connect/disconnect notifications and maintains
/// a dedicated UIWindow on the external screen.
final class ExternalDisplayManager {

    // MARK: - Callbacks

    var onConnect: ((UIScreen) -> Void)?
    var onDisconnect: (() -> Void)?

    // MARK: - State

    private(set) var externalWindow: UIWindow?
    private(set) var externalScreen: UIScreen?

    private var observers: [NSObjectProtocol] = []

    // MARK: - Lifecycle

    func start() {
        // Observe future connections/disconnections
        let connectObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.didConnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let screen = notification.object as? UIScreen else { return }
            self?.handleConnect(screen)
        }

        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDisconnect()
        }

        observers = [connectObserver, disconnectObserver]

        // Handle already-connected external screens
        if let screen = UIScreen.screens.first(where: { $0 != UIScreen.main }) {
            handleConnect(screen)
        }
    }

    func stop() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        tearDownWindow()
    }

    // MARK: - Helpers

    private func handleConnect(_ screen: UIScreen) {
        externalScreen = screen
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.backgroundColor = .black
        window.isHidden = false
        externalWindow = window
        onConnect?(screen)
    }

    private func handleDisconnect() {
        tearDownWindow()
        onDisconnect?()
    }

    private func tearDownWindow() {
        externalWindow?.isHidden = true
        externalWindow = nil
        externalScreen = nil
    }
}
