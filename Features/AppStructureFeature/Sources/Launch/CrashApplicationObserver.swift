//
//  CrashApplicationObserver.swift
//

import Crashing
import UIKit
import VLogging

@MainActor
final class CrashApplicationObserver {
    // MARK: Lifecycle

    deinit {
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
    }

    // MARK: Internal

    func start() {
        guard observers.isEmpty else { return }

        updateApplicationContext()
        observe(UIApplication.didBecomeActiveNotification, state: "active")
        observe(UIApplication.willResignActiveNotification, state: "inactive")
        observe(UIApplication.didEnterBackgroundNotification, state: "background")
        observe(UIApplication.willEnterForegroundNotification, state: "inactive")

        observers.append(
            notificationCenter.addObserver(
                forName: UIApplication.protectedDataDidBecomeAvailableNotification,
                object: nil,
                queue: .main
            ) { _ in
                crashContext.setProtectedDataAvailable(true)
                logger.info("Crash context: protected data became available")
            }
        )
        observers.append(
            notificationCenter.addObserver(
                forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
                object: nil,
                queue: .main
            ) { _ in
                crashContext.setProtectedDataAvailable(false)
                logger.info("Crash context: protected data will become unavailable")
            }
        )
    }

    // MARK: Private

    private let notificationCenter = NotificationCenter.default
    private var observers: [NSObjectProtocol] = []

    private func updateApplicationContext() {
        let application = UIApplication.shared
        crashContext.setApplicationState(application.applicationState.crashContextValue)
        crashContext.setProtectedDataAvailable(application.isProtectedDataAvailable)
    }

    private func observe(_ name: Notification.Name, state: String) {
        observers.append(
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { _ in
                crashContext.setApplicationState(state)
                crashContext.setProtectedDataAvailable(UIApplication.shared.isProtectedDataAvailable)
                logger.info("Crash context: application state changed to \(state)")
            }
        )
    }
}

private extension UIApplication.State {
    var crashContextValue: String {
        switch self {
        case .active: "active"
        case .inactive: "inactive"
        case .background: "background"
        @unknown default: "unknown"
        }
    }
}
