//
//  ToastEnvironmentKey.swift
//
//
//  Created by Mohamed Afifi on 2024-09-22.
//

import SwiftUI
import UIKit
import VLogging

extension EnvironmentValues {
    public var showToast: ((Toast) -> Void)? {
        get { self[ToastPresenterKey.self] }
        set { self[ToastPresenterKey.self] = newValue }
    }
}

extension View {
    /// Lets this view and its descendants show toasts through `showToast`, lifted above the bars
    /// at the bottom of the presenting view's screen, like a tab bar, and the bars that keep toasts
    /// above them, like the reader's audio bar.
    public func enableToastPresenter() -> some View {
        modifier(ToastPresenterModifier())
    }
}

private struct ToastPresenterKey: EnvironmentKey {
    static let defaultValue: ((Toast) -> Void)? = nil
}

private struct ToastPresenterModifier: ViewModifier {
    @State private var anchor = ToastAnchor()

    func body(content: Content) -> some View {
        content
            .background(
                ToastAnchorReader(anchor: anchor)
            )
            .environment(\.showToast) { toast in
                guard let view = anchor.view else {
                    logger.error("Failed to obtain the toast's presenting view")
                    return
                }
                ToastPresenter.shared.showToast(toast, from: view)
            }
    }
}

/// The presenting view, read when a toast shows to find its window and the bars at the bottom of its screen.
@MainActor
private final class ToastAnchor {
    weak var view: UIView?
}

private struct ToastAnchorReader: UIViewRepresentable {
    let anchor: ToastAnchor

    func makeUIView(context: Context) -> UIView {
        let view = ToastAnchorView()
        view.isUserInteractionEnabled = false
        anchor.view = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        anchor.view = uiView
    }
}

/// Moves the showing toast when the presenting screen resizes, like on rotation, or closes,
/// which can uncover the bars under it.
private final class ToastAnchorView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        ToastPresenter.shared.setNeedsPlacementUpdate()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        ToastPresenter.shared.setNeedsPlacementUpdate()
    }
}
