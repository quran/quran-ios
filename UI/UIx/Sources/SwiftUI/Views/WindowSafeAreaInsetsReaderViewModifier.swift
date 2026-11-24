//
//  WindowSafeAreaInsetsReaderViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import SwiftUI

extension View {
    /// Reads the window's safe area insets, with leading and trailing in the view's layout direction.
    public func readWindowSafeAreaInsets(_ safeAreaInsets: Binding<EdgeInsets>) -> some View {
        modifier(WindowSafeAreaInsetsReaderViewModifier(safeAreaInsets: safeAreaInsets))
    }
}

private struct WindowSafeAreaInsetsReaderViewModifier: ViewModifier {
    @Binding var safeAreaInsets: EdgeInsets

    func body(content: Content) -> some View {
        content
            .background(
                WindowSafeAreaInsetsReader(safeAreaInsets: $safeAreaInsets)
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

        init(safeAreaInsets: Binding<EdgeInsets>, layoutDirection: LayoutDirection) {
            _safeAreaInsetsBinding = safeAreaInsets
            self.layoutDirection = layoutDirection
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

        override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
            .zero
        }

        override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
            .zero
        }
    }

    @Binding var safeAreaInsets: EdgeInsets

    func makeUIView(context: Context) -> WindowSafeAreaInsetsReaderView {
        let view = WindowSafeAreaInsetsReaderView(
            safeAreaInsets: $safeAreaInsets,
            layoutDirection: context.environment.layoutDirection
        )
        view.isAccessibilityElement = false
        view.isHidden = true
        view.isOpaque = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: WindowSafeAreaInsetsReaderView, context: Context) {
        view.layoutDirection = context.environment.layoutDirection
    }
}

extension EdgeInsets {
    /// UIKit's left and right insets as leading and trailing in `layoutDirection`.
    init(_ insets: UIEdgeInsets, layoutDirection: LayoutDirection) {
        let isRightToLeft = layoutDirection == .rightToLeft
        self.init(
            top: insets.top,
            leading: isRightToLeft ? insets.right : insets.left,
            bottom: insets.bottom,
            trailing: isRightToLeft ? insets.left : insets.right
        )
    }
}
