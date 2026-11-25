//
//  WindowSafeAreaInsetsReaderViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import SwiftUI

extension View {
    /// Reads the window's safe area insets, with leading and trailing in the view's layout direction.
    ///
    /// The insets update on layout passes, and with `verticalBarAnimation` when `verticalBarContent` changes in the
    /// environment.
    public func readWindowSafeAreaInsets(
        _ safeAreaInsets: Binding<EdgeInsets>,
        verticalBarAnimation: Animation? = nil
    ) -> some View {
        modifier(WindowSafeAreaInsetsReaderViewModifier(
            safeAreaInsets: safeAreaInsets,
            verticalBarAnimation: verticalBarAnimation
        ))
    }
}

/// What the content shows in the window's vertical-bar column.
///
/// The screen that shows or hides the status bar and its controls there sets it. A change moves the window's safe
/// area without a layout pass, so window safe-area readers re-read it when it changes.
public struct VerticalBarContent: Equatable, Sendable {
    // MARK: Lifecycle

    public init(statusBarHidden: Bool = false, showsBarItems: Bool = false) {
        self.statusBarHidden = statusBarHidden
        self.showsBarItems = showsBarItems
    }

    // MARK: Public

    /// Whether the status bar is hidden from the column.
    public var statusBarHidden: Bool

    /// Whether the screen's controls show in the column.
    public var showsBarItems: Bool
}

extension EnvironmentValues {
    /// What the content shows in the window's vertical-bar column, set by the screen that shows or hides the status
    /// bar and its controls there. `readWindowSafeAreaInsets(_:verticalBarAnimation:)` readers re-read the window's
    /// safe area when it changes.
    public var verticalBarContent: VerticalBarContent {
        get { self[VerticalBarContentKey.self] }
        set { self[VerticalBarContentKey.self] = newValue }
    }
}

private struct VerticalBarContentKey: EnvironmentKey {
    static let defaultValue = VerticalBarContent()
}

private struct WindowSafeAreaInsetsReaderViewModifier: ViewModifier {
    @Binding var safeAreaInsets: EdgeInsets
    let verticalBarAnimation: Animation?
    @Environment(\.verticalBarContent) var verticalBarContent

    func body(content: Content) -> some View {
        content
            .background(
                WindowSafeAreaInsetsReader(
                    safeAreaInsets: $safeAreaInsets,
                    verticalBarAnimation: verticalBarAnimation,
                    verticalBarContent: verticalBarContent
                )
                .frame(maxWidth: .infinity)
                .frame(height: 0.5)
                .accessibility(hidden: true)
                .allowsHitTesting(false)
            )
    }
}

private struct WindowSafeAreaInsetsReader: UIViewRepresentable {
    class WindowSafeAreaInsetsReaderView: UIView {
        // MARK: Lifecycle

        init(
            safeAreaInsets: Binding<EdgeInsets>,
            layoutDirection: LayoutDirection,
            verticalBarAnimation: Animation?,
            verticalBarContent: VerticalBarContent
        ) {
            _safeAreaInsetsBinding = safeAreaInsets
            self.layoutDirection = layoutDirection
            self.verticalBarAnimation = verticalBarAnimation
            self.verticalBarContent = verticalBarContent
            super.init(frame: .zero)
            backgroundColor = UIColor.clear
            if #available(iOS 27.1, *) {
                // The window's safe area moves with the vertical bar without a layout pass.
                registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) {
                    (view: WindowSafeAreaInsetsReaderView, _: UITraitCollection) in
                    view.updateWindowSafeAreaInsetsIfNeeded()
                }
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Internal

        @Binding var safeAreaInsetsBinding: EdgeInsets

        /// The SwiftUI layout direction whose leading and trailing the insets use.
        var layoutDirection: LayoutDirection {
            didSet {
                if layoutDirection != oldValue {
                    setNeedsLayout()
                }
            }
        }

        var verticalBarAnimation: Animation?

        var verticalBarContent: VerticalBarContent {
            didSet {
                guard verticalBarContent != oldValue else {
                    return
                }
                // After SwiftUI's update, and again a turn later in case the window's safe area updates late.
                DispatchQueue.main.async { [weak self] in
                    self?.updateWindowSafeAreaInsetsAnimated()
                    DispatchQueue.main.async {
                        self?.updateWindowSafeAreaInsetsAnimated()
                    }
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            updateWindowSafeAreaInsetsIfNeeded()
        }

        private func updateWindowSafeAreaInsetsIfNeeded() {
            if let window {
                let newInsets = EdgeInsets(window.safeAreaInsets, layoutDirection: layoutDirection)
                if safeAreaInsetsBinding != newInsets {
                    safeAreaInsetsBinding = newInsets
                }
            }
        }

        private func updateWindowSafeAreaInsetsAnimated() {
            withAnimation(verticalBarAnimation) {
                updateWindowSafeAreaInsetsIfNeeded()
            }
        }

        override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
            .zero
        }

        override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
            .zero
        }
    }

    @Binding var safeAreaInsets: EdgeInsets
    let verticalBarAnimation: Animation?
    let verticalBarContent: VerticalBarContent

    func makeUIView(context: Context) -> WindowSafeAreaInsetsReaderView {
        let view = WindowSafeAreaInsetsReaderView(
            safeAreaInsets: $safeAreaInsets,
            layoutDirection: context.environment.layoutDirection,
            verticalBarAnimation: verticalBarAnimation,
            verticalBarContent: verticalBarContent
        )
        view.isAccessibilityElement = false
        view.isHidden = true
        view.isOpaque = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: WindowSafeAreaInsetsReaderView, context: Context) {
        view.layoutDirection = context.environment.layoutDirection
        view.verticalBarAnimation = verticalBarAnimation
        view.verticalBarContent = verticalBarContent
    }
}

extension EdgeInsets {
    /// UIKit's left and right insets as leading and trailing in `layoutDirection`.
    init(_ insets: UIEdgeInsets, layoutDirection: LayoutDirection) {
        self.init(
            top: insets.top,
            left: insets.left,
            bottom: insets.bottom,
            right: insets.right,
            layoutDirection: layoutDirection
        )
    }
}
