//
//  ModalPresentationCoordinator.swift
//
//

import UIKit

public struct ModalPresentationRequest: Identifiable {
    // MARK: Lifecycle

    private init(action: Action) {
        self.action = action
    }

    // MARK: Public

    public let id = UUID()

    public static func present(_ viewController: UIViewController) -> Self {
        Self(action: .present(viewController))
    }

    public static var dismiss: Self {
        Self(action: .dismiss)
    }

    // MARK: Internal

    enum Action {
        case present(UIViewController)
        case dismiss
    }

    let action: Action
}

@MainActor
public final class ModalPresentationCoordinator: NSObject, ObservableObject, UIAdaptivePresentationControllerDelegate {
    // MARK: Public

    public func handle(_ request: ModalPresentationRequest, from presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController

        switch request.action {
        case .present(let viewController):
            perform(stateMachine.requestPresentation(viewController))
        case .dismiss:
            perform(stateMachine.requestDismissal())
        }
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismiss(presentationController.presentedViewController)
    }

    // MARK: Private

    private weak var presentingViewController: UIViewController?
    private weak var presentedViewController: UIViewController?
    private var stateMachine = ModalPresentationStateMachine<UIViewController>()

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
            stateMachine.cancel()
            return
        }

        presentedViewController = viewController
        presentingViewController.present(viewController, animated: true) { [weak self, weak viewController] in
            guard let self, presentedViewController === viewController else { return }
            perform(stateMachine.didPresent())
        }
        viewController.presentationController?.delegate = self
    }

    private func dismiss() {
        guard let presentedViewController else {
            perform(stateMachine.didDismiss())
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
        perform(stateMachine.didDismiss())
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
