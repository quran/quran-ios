//
//  AppIconAnnouncementController.swift
//  Quran
//
//

import SwiftUI
import UIKit

@MainActor
public final class AppIconAnnouncementController {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func presentIfNeeded(
        from parent: UIViewController,
        completion: @escaping () -> Void
    ) {
        guard !store.hasSeenAnnouncement else {
            completion()
            return
        }

        let view = AppIconAnnouncementView { [weak self, weak parent] in
            guard let self else { return }

            store.hasSeenAnnouncement = true
            parent?.dismiss(animated: true, completion: completion)
        }
        let viewController = UIHostingController(rootView: view)
        viewController.modalPresentationStyle = .fullScreen
        parent.present(viewController, animated: true)
    }

    // MARK: Private

    private let store = AppIconAnnouncementStore()
}
