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
    /// at the bottom of the presenting view's screen, like a tab bar.
    ///
    /// - Parameter bottomBarsHeight: How far bars that the presenting view's screen can't report
    ///   through its safe area, like a floating bar beneath a popover, reach above the window's
    ///   bottom edge. Read when a toast shows.
    public func enableToastPresenter(bottomBarsHeight: (@MainActor () -> CGFloat)? = nil) -> some View {
        modifier(ToastPresenterModifier(bottomBarsHeight: bottomBarsHeight))
    }
}

private struct ToastPresenterKey: EnvironmentKey {
    static let defaultValue: ((Toast) -> Void)? = nil
}

private struct ToastPresenterModifier: ViewModifier {
    let bottomBarsHeight: (@MainActor () -> CGFloat)?

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
                ToastPresenter.shared.showToast(toast, from: view, bottomBarsHeight: bottomBarsHeight?() ?? 0)
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
        let view = UIView()
        view.isUserInteractionEnabled = false
        anchor.view = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        anchor.view = uiView
    }
}
