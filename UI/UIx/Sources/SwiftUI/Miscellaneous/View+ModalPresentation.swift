//
//  View+ModalPresentation.swift
//
//

import SwiftUI

extension View {
    /// Serializes UIKit modal presentation and dismissal requests from a SwiftUI view.
    /// The request is cleared after the modifier accepts it.
    public func serializedModalPresentation(
        request: Binding<ModalPresentationRequest?>
    ) -> some View {
        modifier(SerializedModalPresentationModifier(request: request))
    }
}

private struct SerializedModalPresentationModifier: ViewModifier {
    @Binding var request: ModalPresentationRequest?
    @StateObject private var coordinator = ModalPresentationCoordinator()
    @StateObject private var presentingViewController = WeakViewControllerReference()

    func body(content: Content) -> some View {
        content
            .background(
                ModalPresentationViewControllerReader(
                    viewController: presentingViewController
                )
            )
            .onChange(of: request?.id) { _ in
                handleRequestIfPossible()
            }
            .onChange(of: presentingViewController.resolutionRevision) { _ in
                handleRequestIfPossible()
            }
    }

    private func handleRequestIfPossible() {
        guard let request, let presentingViewController = presentingViewController.value else { return }
        self.request = nil
        coordinator.handle(request, from: presentingViewController)
    }
}

@MainActor
final class WeakViewControllerReference: ObservableObject {
    @Published private(set) var resolutionRevision: UInt = 0
    weak var value: UIViewController?

    func set(_ viewController: UIViewController?) {
        value = viewController
        if viewController != nil {
            resolutionRevision &+= 1
        }
    }

    func clear() {
        value = nil
    }
}

private struct ModalPresentationViewControllerReader: UIViewControllerRepresentable {
    let viewController: WeakViewControllerReference

    func makeUIViewController(context: Context) -> ReaderViewController {
        ReaderViewController(viewController: viewController)
    }

    func updateUIViewController(_ uiViewController: ReaderViewController, context: Context) {
        uiViewController.viewController = viewController
    }

    static func dismantleUIViewController(_ uiViewController: ReaderViewController, coordinator: ()) {
        // SwiftUI is invalidating its graph here. Clearing the weak pointer must not
        // publish another graph update while that invalidation is in progress.
        uiViewController.viewController.clear()
    }

    final class ReaderViewController: UIViewController {
        var viewController: WeakViewControllerReference

        init(viewController: WeakViewControllerReference) {
            self.viewController = viewController
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            viewController.set(parent)
        }
    }
}
