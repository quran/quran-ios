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
    /// - Parameter excludingVerticalBar: Whether to leave out the column the system reserves for the vertical bar,
    ///   like on iPhone Duo. Pass `true` only for full-bleed reading content in a screen without system bars,
    ///   which hides the status bar while reading, so the column is empty.
    public func readWindowSafeAreaInsets(_ safeAreaInsets: Binding<EdgeInsets>, excludingVerticalBar: Bool = false) -> some View {
        modifier(WindowSafeAreaInsetsReaderViewModifier(safeAreaInsets: safeAreaInsets, excludingVerticalBar: excludingVerticalBar))
    }
}

private struct WindowSafeAreaInsetsReaderViewModifier: ViewModifier {
    @Binding var safeAreaInsets: EdgeInsets
    let excludingVerticalBar: Bool

    func body(content: Content) -> some View {
        content
            .background(
                WindowSafeAreaInsetsReader(safeAreaInsets: $safeAreaInsets, excludingVerticalBar: excludingVerticalBar)
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

        init(safeAreaInsets: Binding<EdgeInsets>, excludingVerticalBar: Bool) {
            _safeAreaInsetsBinding = safeAreaInsets
            self.excludingVerticalBar = excludingVerticalBar
            super.init(frame: .zero)
            backgroundColor = UIColor.clear
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Internal

        @Binding var safeAreaInsetsBinding: EdgeInsets
        var excludingVerticalBar: Bool

        override func layoutSubviews() {
            super.layoutSubviews()
            updateWindowSafeAreaInsetsIfNeeded()
        }

        override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
            .zero
        }

        override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
            .zero
        }

        // MARK: Private

        private func updateWindowSafeAreaInsetsIfNeeded() {
            if let window {
                let insets = insets(of: window)
                let newInsets = EdgeInsets(
                    top: insets.top,
                    leading: insets.left,
                    bottom: insets.bottom,
                    trailing: insets.right
                )
                if safeAreaInsetsBinding != newInsets {
                    safeAreaInsetsBinding = newInsets
                }
            }
        }

        private func insets(of window: UIWindow) -> UIEdgeInsets {
            var insets = window.safeAreaInsets
            guard excludingVerticalBar, #available(iOS 27.1, *) else {
                return insets
            }
            let isRightToLeft = window.effectiveUserInterfaceLayoutDirection == .rightToLeft
            switch window.traitCollection.verticalBarEdge {
            case .leading:
                if isRightToLeft { insets.right = 0 } else { insets.left = 0 }
            case .trailing:
                if isRightToLeft { insets.left = 0 } else { insets.right = 0 }
            default:
                break
            }
            return insets
        }
    }

    @Binding var safeAreaInsets: EdgeInsets
    let excludingVerticalBar: Bool

    func makeUIView(context: Context) -> UIView {
        let view = WindowSafeAreaInsetsReaderView(safeAreaInsets: $safeAreaInsets, excludingVerticalBar: excludingVerticalBar)
        view.isAccessibilityElement = false
        view.isHidden = true
        view.isOpaque = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        (view as? WindowSafeAreaInsetsReaderView)?.excludingVerticalBar = excludingVerticalBar
    }
}
