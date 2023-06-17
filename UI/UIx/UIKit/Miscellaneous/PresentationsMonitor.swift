//
//  PresentationsMonitor.swift
//
//
//  Created by Mohamed Afifi on 2022-12-24.
//

import UIKit

public class PresentationsMonitor {
    public struct Actions {
        // MARK: Lifecycle

        public init(didDismiss: @escaping (UIPresentationController) -> Void) {
            self.didDismiss = didDismiss
        }

        // MARK: Public

        public var didDismiss: (UIPresentationController) -> Void
    }

    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func monitor(_ viewControllerToPresent: UIViewController, actions: Actions) {
        var updatedActions = actions
        updatedActions.didDismiss = { [weak self] presentation in
            actions.didDismiss(presentation)
            self?.cleanup(presentation.presentedViewController)
        }
        let presentation = Presentation(actions: updatedActions)
        viewControllerToPresent.presentationController?.delegate = presentation
        presentations[viewControllerToPresent] = presentation
    }

    public func dismiss(_ viewController: UIViewController) {
        if let presentationController = viewController.presentationController {
            presentations[viewController]?.actions.didDismiss(presentationController)
        }
    }

    // MARK: Private

    private var presentations: [UIViewController: Presentation] = [:]

    private func cleanup(_ viewController: UIViewController) {
        presentations[viewController] = nil
    }
}

private class Presentation: NSObject, UIAdaptivePresentationControllerDelegate {
    // MARK: Lifecycle

    init(actions: PresentationsMonitor.Actions) {
        self.actions = actions
        super.init()
    }

    // MARK: Internal

    let actions: PresentationsMonitor.Actions

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        actions.didDismiss(presentationController)
    }
}
