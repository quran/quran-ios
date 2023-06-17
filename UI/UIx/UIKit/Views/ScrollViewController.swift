//
//  ScrollViewController.swift
//
//
//  Created by Afifi, Mohamed on 7/25/21.
//

import UIKit

public class ScrollViewController: UIViewController {
    // MARK: Lifecycle

    public init(content: UIViewController) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public private(set) lazy var scrollView: UIScrollView = UIScrollView()

    override public func loadView() {
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true

        addChild(content)
        scrollView.addAutoLayoutSubview(content.view)

        content.view.vc.edges()
        content.view.vc.height(to: scrollView)

        content.didMove(toParent: self)
        view = scrollView
    }

    override public func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        preferredContentSize = container.preferredContentSize
    }

    // MARK: Private

    private let content: UIViewController
}
