//
//  PreferredContentSizeMatchesScrollView.swift
//
//
//  Created by Mohamed Afifi on 2022-12-27.
//

import SwiftUI

public struct PreferredContentSizeMatchesScrollView<ScrollViewContent: View>: View {
    // MARK: Lifecycle

    public init(@ViewBuilder content: () -> ScrollViewContent) {
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        PreferredContentSizeMatchesScrollViewBody(content: content)
    }

    // MARK: Private

    private let content: ScrollViewContent
}

public extension ScrollView {
    @MainActor
    func preferredContentSizeMatchesScrollView() -> some View {
        PreferredContentSizeMatchesScrollView {
            self
        }
    }
}

private struct PreferredContentSizeMatchesScrollViewBody<ScrollViewContent: View>: UIViewControllerRepresentable {
    class PreferredContentSizeMatchesScrollViewController: UIHostingController<ScrollViewContent> {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            view.backgroundColor = nil
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            // Update preferredContentSize in the next run loop to prevent a recursion.
            DispatchQueue.main.async {
                if let scrollView = self.view.firstScrollView() {
                    let height = scrollView.contentSize.height + self.containerSafeAreaHeight
                    if height > self.preferredContentSize.height {
                        self.preferredContentSize = CGSize(width: scrollView.contentSize.width, height: height)
                    }
                }
            }
        }

        /// In a window with a vertical bar, like iPhone Duo's, a popover pointing sideways gives a navigation
        /// controller's content a top safe area even with its bar hidden, which would clip the last row.
        private var containerSafeAreaHeight: CGFloat {
            guard view.window?.traitCollection.hasVerticalBar == true,
                  parent?.navigationController?.isNavigationBarHidden ?? true,
                  let container = parent?.view
            else {
                return 0
            }
            return container.safeAreaInsets.top + container.safeAreaInsets.bottom
        }
    }

    let content: ScrollViewContent

    func makeUIViewController(context: Context) -> PreferredContentSizeMatchesScrollViewController {
        PreferredContentSizeMatchesScrollViewController(rootView: content)
    }

    func updateUIViewController(_ view: PreferredContentSizeMatchesScrollViewController, context: Context) {
        view.rootView = content
    }
}

private extension UIView {
    func firstScrollView() -> UIScrollView? {
        if let scrollView = self as? UIScrollView {
            return scrollView
        }
        for s in subviews {
            if let scrollView = s.firstScrollView() {
                return scrollView
            }
        }
        return nil
    }
}
