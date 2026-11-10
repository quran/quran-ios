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
    ///   - excludingVerticalBar: Whether to leave out the column the system reserves for the vertical bar,
    ///     like on iPhone Duo. Pass `true` only for full-bleed reading content in a screen without system bars,
    ///     which hides the status bar while reading, so the column is empty.
    ///   - hasVerticalBar: Set to whether the window reserves a column for the vertical bar, like on iPhone Duo.
    public func readWindowSafeAreaInsets(
        _ safeAreaInsets: Binding<EdgeInsets>,
        excludingVerticalBar: Bool = false,
        hasVerticalBar: Binding<Bool> = .constant(false)
    ) -> some View {
        modifier(WindowSafeAreaInsetsReaderViewModifier(
            safeAreaInsets: safeAreaInsets,
            hasVerticalBar: hasVerticalBar,
            excludingVerticalBar: excludingVerticalBar
        ))
    }
}

private struct WindowSafeAreaInsetsReaderViewModifier: ViewModifier {
    @Binding var safeAreaInsets: EdgeInsets
    @Binding var hasVerticalBar: Bool
    let excludingVerticalBar: Bool

    func body(content: Content) -> some View {
        content
            .background(
                WindowSafeAreaInsetsReader(
                    safeAreaInsets: $safeAreaInsets,
                    hasVerticalBar: $hasVerticalBar,
                    excludingVerticalBar: excludingVerticalBar
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

        init(safeAreaInsets: Binding<EdgeInsets>, hasVerticalBar: Binding<Bool>, excludingVerticalBar: Bool) {
            _safeAreaInsetsBinding = safeAreaInsets
            _hasVerticalBarBinding = hasVerticalBar
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
        @Binding var hasVerticalBarBinding: Bool
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
                let hasVerticalBar = verticalBarEdge(of: window) != nil
                if hasVerticalBarBinding != hasVerticalBar {
                    hasVerticalBarBinding = hasVerticalBar
                }
            }
        }

        /// Mirrors UIKit's `UIVerticalBarEdge` raw values (iOS 27.1).
        private enum VerticalBarEdge: Int {
            case leading = 1
            case trailing = 2
        }

        private func verticalBarEdge(of window: UIWindow) -> VerticalBarEdge? {
            guard #available(iOS 27.1, *) else {
                return nil
            }
            // Read `UITraitCollection.verticalBarEdge` by key so this compiles with SDKs older than iOS 27.1,
            // like the one CI builds with. It's a public UIKit property; `0` means unspecified.
            guard let rawValue = window.traitCollection.value(forKey: "verticalBarEdge") as? Int else {
                return nil
            }
            return VerticalBarEdge(rawValue: rawValue)
        }

        private func insets(of window: UIWindow) -> UIEdgeInsets {
            var insets = window.safeAreaInsets
            guard excludingVerticalBar else {
                return insets
            }
            let isRightToLeft = window.effectiveUserInterfaceLayoutDirection == .rightToLeft
            switch verticalBarEdge(of: window) {
            case .leading:
                if isRightToLeft { insets.right = 0 } else { insets.left = 0 }
            case .trailing:
                if isRightToLeft { insets.left = 0 } else { insets.right = 0 }
            case nil:
                break
            }
            return insets
        }
    }

    @Binding var safeAreaInsets: EdgeInsets
    @Binding var hasVerticalBar: Bool
    let excludingVerticalBar: Bool

    func makeUIView(context: Context) -> UIView {
        let view = WindowSafeAreaInsetsReaderView(
            safeAreaInsets: $safeAreaInsets,
            hasVerticalBar: $hasVerticalBar,
            excludingVerticalBar: excludingVerticalBar
        )
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
