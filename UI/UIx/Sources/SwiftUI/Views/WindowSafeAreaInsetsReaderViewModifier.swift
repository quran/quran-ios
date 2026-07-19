//
//  WindowSafeAreaInsetsReaderViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import SwiftUI

extension View {
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

        init(safeAreaInsets: Binding<EdgeInsets>) {
            _safeAreaInsetsBinding = safeAreaInsets
            super.init(frame: .zero)
            backgroundColor = UIColor.clear
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Internal

        @Binding var safeAreaInsetsBinding: EdgeInsets

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

    func makeUIView(context: Context) -> UIView {
        let view = WindowSafeAreaInsetsReaderView(safeAreaInsets: $safeAreaInsets)
        view.isAccessibilityElement = false
        view.isHidden = true
        view.isOpaque = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {}
}
