//
//  ModalPresentationCoordinator.swift
//
//

import Crashing
import UIKit
import VLogging

public struct ModalPresentationRequest: Identifiable {
    // MARK: Lifecycle

    private init(action: Action, owner: String, kind: String) {
        self.action = action
        self.owner = owner
        self.kind = kind
    }

    // MARK: Public

    public let id = UUID()

    public static func present(_ viewController: UIViewController) -> Self {
        present(viewController, owner: "unspecified", kind: "modal")
    }

    public static func present(_ viewController: UIViewController, owner: String, kind: String) -> Self {
        Self(action: .present(viewController), owner: owner, kind: kind)
    }

    public static var dismiss: Self {
        dismiss(owner: "unspecified")
    }

    public static func dismiss(owner: String) -> Self {
        Self(action: .dismiss, owner: owner, kind: "modal")
    }

    // MARK: Internal

    enum Action {
        case present(UIViewController)
        case dismiss
    }

    let action: Action
    let owner: String
    let kind: String
}

@MainActor
public final class ModalPresentationCoordinator: NSObject, ObservableObject, UIAdaptivePresentationControllerDelegate {
    // MARK: Public

    public func handle(_ request: ModalPresentationRequest, from presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController

        switch request.action {
        case .present(let viewController):
            presentationMetadata[ObjectIdentifier(viewController)] = (request.owner, request.kind)
            crashContext.setPresentation(owner: request.owner, kind: request.kind, phase: "requested", interactive: false)
            logger.info("Modal presentation requested: \(request.owner), kind: \(request.kind)")
            perform(stateMachine.requestPresentation(viewController))
        case .dismiss:
            let owner = currentOwner ?? request.owner
            crashContext.setPresentation(owner: owner, kind: currentKind ?? request.kind, phase: "dismiss_requested", interactive: false)
            logger.info("Modal dismissal requested: \(owner)")
            perform(stateMachine.requestDismissal())
        }
    }

    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        recordCurrentPresentation(phase: "interactive_dismissing", interactive: true)
    }

    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        recordCurrentPresentation(phase: "interactive_dismissal_blocked", interactive: false)
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismiss(presentationController.presentedViewController)
    }

    // MARK: Private

    private weak var presentingViewController: UIViewController?
    private weak var presentedViewController: UIViewController?
    private var stateMachine = ModalPresentationStateMachine<UIViewController>()
    private var presentationMetadata: [ObjectIdentifier: (owner: String, kind: String)] = [:]
    private var currentOwner: String?
    private var currentKind: String?

    private func perform(_ action: ModalPresentationStateMachine<UIViewController>.Action?) {
        guard let action else { return }

        switch action {
        case .present(let viewController):
            present(viewController)
        case .dismiss:
            dismiss()
        }
    }

    private func present(_ viewController: UIViewController) {
        guard let presentingViewController else {
            if let metadata = presentationMetadata.removeValue(forKey: ObjectIdentifier(viewController)) {
                crashContext.clearPresentation(owner: metadata.owner)
            }
            stateMachine.cancel()
            return
        }

        let metadata = presentationMetadata.removeValue(forKey: ObjectIdentifier(viewController)) ?? ("unspecified", "modal")
        currentOwner = metadata.owner
        currentKind = metadata.kind
        recordCurrentPresentation(phase: "presenting", interactive: false)
        presentedViewController = viewController
        presentingViewController.present(viewController, animated: true) { [weak self, weak viewController] in
            guard let self, presentedViewController === viewController else { return }
            recordCurrentPresentation(phase: "presented", interactive: false)
            perform(stateMachine.didPresent())
        }
        viewController.presentationController?.delegate = self
    }

    private func dismiss() {
        recordCurrentPresentation(phase: "dismissing", interactive: false)
        guard let presentedViewController else {
            let dismissedOwner = currentOwner
            currentOwner = nil
            currentKind = nil
            let action = stateMachine.didDismiss()
            if let dismissedOwner {
                crashContext.clearPresentation(owner: dismissedOwner)
            }
            perform(action)
            return
        }
        presentedViewController.dismiss(animated: true) { [weak self, weak presentedViewController] in
            guard let presentedViewController else { return }
            self?.didDismiss(presentedViewController)
        }
    }

    private func didDismiss(_ viewController: UIViewController) {
        guard presentedViewController === viewController else { return }
        presentedViewController = nil
        let dismissedOwner = currentOwner
        currentOwner = nil
        currentKind = nil
        let action = stateMachine.didDismiss()
        if let dismissedOwner {
            crashContext.clearPresentation(owner: dismissedOwner)
            logger.info("Modal presentation dismissed: \(dismissedOwner)")
        }
        perform(action)
    }

    private func recordCurrentPresentation(phase: String, interactive: Bool) {
        guard let currentOwner, let currentKind else { return }
        crashContext.setPresentation(owner: currentOwner, kind: currentKind, phase: phase, interactive: interactive)
    }
}

struct ModalPresentationStateMachine<Item> {
    enum Action {
        case present(Item)
        case dismiss
    }

    enum Phase: Equatable {
        case idle
        case presenting
        case presented
        case dismissing
    }

    private(set) var phase = Phase.idle
    private var pendingItem: Item?
    private var dismissAfterPresentation = false

    mutating func requestPresentation(_ item: Item) -> Action? {
        switch phase {
        case .idle:
            phase = .presenting
            return .present(item)
        case .presenting:
            pendingItem = item
            return nil
        case .presented:
            pendingItem = item
            phase = .dismissing
            return .dismiss
        case .dismissing:
            pendingItem = item
            return nil
        }
    }

    mutating func requestDismissal() -> Action? {
        pendingItem = nil

        switch phase {
        case .idle, .dismissing:
            return nil
        case .presenting:
            dismissAfterPresentation = true
            return nil
        case .presented:
            phase = .dismissing
            return .dismiss
        }
    }

    mutating func didPresent() -> Action? {
        guard phase == .presenting else { return nil }

        if dismissAfterPresentation || pendingItem != nil {
            dismissAfterPresentation = false
            phase = .dismissing
            return .dismiss
        }

        phase = .presented
        return nil
    }

    mutating func didDismiss() -> Action? {
        guard phase == .presented || phase == .dismissing else { return nil }

        if let pendingItem {
            self.pendingItem = nil
            phase = .presenting
            return .present(pendingItem)
        }

        phase = .idle
        return nil
    }

    mutating func cancel() {
        pendingItem = nil
        dismissAfterPresentation = false
        phase = .idle
    }
}

extension ModalPresentationStateMachine.Action: Equatable where Item: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.present(let lhs), .present(let rhs)):
            lhs == rhs
        case (.dismiss, .dismiss):
            true
        default:
            false
        }
    }
}
