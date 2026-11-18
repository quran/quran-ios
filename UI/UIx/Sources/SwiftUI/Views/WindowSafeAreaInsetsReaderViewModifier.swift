//
//  WindowSafeAreaInsetsReaderViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import SwiftUI

extension View {
    /// Reads the window's safe area insets.
    ///
    /// - Parameters:
    ///   - hasVerticalBar: Set to whether the window reserves a column for the vertical bar, like on iPhone Duo.
    public func readWindowSafeAreaInsets(
        _ safeAreaInsets: Binding<EdgeInsets>,
        hasVerticalBar: Binding<Bool> = .constant(false)
    ) -> some View {
        modifier(WindowSafeAreaInsetsReaderViewModifier(safeAreaInsets: safeAreaInsets, hasVerticalBar: hasVerticalBar))
    }
}

private struct WindowSafeAreaInsetsReaderViewModifier: ViewModifier {
    @Binding var safeAreaInsets: EdgeInsets
    @Binding var hasVerticalBar: Bool

    func body(content: Content) -> some View {
        content
            .background(
                WindowSafeAreaInsetsReader(safeAreaInsets: $safeAreaInsets, hasVerticalBar: $hasVerticalBar)
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

        init(safeAreaInsets: Binding<EdgeInsets>, hasVerticalBar: Binding<Bool>) {
            _safeAreaInsetsBinding = safeAreaInsets
            _hasVerticalBarBinding = hasVerticalBar
            super.init(frame: .zero)
            backgroundColor = UIColor.clear
            if #available(iOS 27.1, *) {
                // The vertical bar edge can change without a layout pass.
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
        @Binding var hasVerticalBarBinding: Bool

        override func layoutSubviews() {
            super.layoutSubviews()
            updateWindowSafeAreaInsetsIfNeeded()
        }

        private func updateWindowSafeAreaInsetsIfNeeded() {
            if let window {
                let insets = window.safeAreaInsets
                let newInsets = EdgeInsets(
                    top: insets.top,
                    leading: insets.left,
                    bottom: insets.bottom,
                    trailing: insets.right
                )
                if safeAreaInsetsBinding != newInsets {
                    safeAreaInsetsBinding = newInsets
                }
                let hasVerticalBar = hasVerticalBar(window)
                if hasVerticalBarBinding != hasVerticalBar {
                    hasVerticalBarBinding = hasVerticalBar
                }
            }
        }

        override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
            .zero
        }

        override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
            .zero
        }

        // MARK: Private

        private func hasVerticalBar(_ window: UIWindow) -> Bool {
            guard #available(iOS 27.1, *) else {
                return false
            }
            switch window.traitCollection.verticalBarEdge {
            case .leading, .trailing: return true
            case .unspecified: return false
            @unknown default: return false
            }
        }
    }

    @Binding var safeAreaInsets: EdgeInsets
    @Binding var hasVerticalBar: Bool

    func makeUIView(context: Context) -> UIView {
        let view = WindowSafeAreaInsetsReaderView(safeAreaInsets: $safeAreaInsets, hasVerticalBar: $hasVerticalBar)
        view.isAccessibilityElement = false
        view.isHidden = true
        view.isOpaque = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {}
}
