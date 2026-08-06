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
    @State private var presentingViewController: UIViewController?

    func body(content: Content) -> some View {
        content
            .background(
                ModalPresentationViewControllerReader(
                    viewController: $presentingViewController
                )
            )
            .onChange(of: request?.id) { _ in
                handleRequestIfPossible()
            }
            .onChange(of: presentingViewController == nil) { _ in
                handleRequestIfPossible()
            }
    }

    private func handleRequestIfPossible() {
        guard let request, let presentingViewController else { return }
        self.request = nil
        coordinator.handle(request, from: presentingViewController)
    }
}

private struct ModalPresentationViewControllerReader: UIViewControllerRepresentable {
    @Binding var viewController: UIViewController?

    func makeUIViewController(context: Context) -> ReaderViewController {
        ReaderViewController(viewController: $viewController)
    }

    func updateUIViewController(_ uiViewController: ReaderViewController, context: Context) {
        uiViewController.viewController = $viewController
    }

    static func dismantleUIViewController(_ uiViewController: ReaderViewController, coordinator: ()) {
        uiViewController.viewController.wrappedValue = nil
    }

    final class ReaderViewController: UIViewController {
        var viewController: Binding<UIViewController?>

        init(viewController: Binding<UIViewController?>) {
            self.viewController = viewController
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            viewController.wrappedValue = parent
        }
    }
}
