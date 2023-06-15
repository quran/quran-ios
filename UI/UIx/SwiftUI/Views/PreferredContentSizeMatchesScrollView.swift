//
//  PreferredContentSizeMatchesScrollView.swift
//
//
//  Created by Mohamed Afifi on 2022-12-27.
//

import SwiftUI

public struct PreferredContentSizeMatchesScrollView<ScrollViewContent: View>: View {
    private let content: ScrollViewContent

    public init(@ViewBuilder content: () -> ScrollViewContent) {
        self.content = content()
    }

    public var body: some View {
        PreferredContentSizeMatchesScrollViewBody(content: content)
    }
}

public extension ScrollView {
    func preferredContentSizeMatchesScrollView() -> some View {
        PreferredContentSizeMatchesScrollView {
            self
        }
    }
}

private struct PreferredContentSizeMatchesScrollViewBody<ScrollViewContent: View>: UIViewControllerRepresentable {
    let content: ScrollViewContent

    func makeUIViewController(context: Context) -> PreferredContentSizeMatchesScrollViewController<ScrollViewContent> {
        PreferredContentSizeMatchesScrollViewController(rootView: content)
    }

    func updateUIViewController(_ view: PreferredContentSizeMatchesScrollViewController<ScrollViewContent>, context: Context) {
        view.rootView = content
    }

    class PreferredContentSizeMatchesScrollViewController<ScrollViewContent: View>: UIHostingController<ScrollViewContent> {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            view.backgroundColor = nil
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            // Update preferredContentSize in the next run loop to prevent a recursion.
            DispatchQueue.main.async {
                if let scrollView = self.view.firstScrollView() {
                    if scrollView.contentSize.height > self.preferredContentSize.height {
                        self.preferredContentSize = scrollView.contentSize
                    }
                }
            }
        }
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
