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
    @ScaledMetric private var bottomBarsSpacing = 8

    func body(content: Content) -> some View {
        content
            .background(
                ToastAnchorReader(anchor: anchor)
            )
            .environment(\.showToast) { toast in
                guard let view = anchor.view, let windowScene = view.window?.windowScene else {
                    logger.error("Failed to obtain windowScene")
                    return
                }
                let height = max(view.bottomBarsHeight, bottomBarsHeight?() ?? 0)
                let placedToast = toast.clearingBottomBars(height: height, spacing: bottomBarsSpacing)
                ToastPresenter.shared.showToast(placedToast, in: windowScene)
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

private extension UIView {
    /// How far the bars at the bottom of this view's screen, like a tab bar, reach above the window's bottom edge.
    var bottomBarsHeight: CGFloat {
        let screenView = sequence(first: self, next: \.superview).first { $0.next is UIViewController }
        guard let window, let screenView else {
            return 0
        }
        return Toast.bottomBarsHeight(
            windowHeight: window.bounds.height,
            windowBottomInset: window.safeAreaInsets.bottom,
            screenBottom: screenView.convert(screenView.bounds, to: window).maxY,
            screenBottomInset: screenView.safeAreaInsets.bottom
        )
    }
}
