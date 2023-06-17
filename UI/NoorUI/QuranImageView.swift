//
//  QuranImageView.swift
//
//
//  Created by Mohamed Afifi on 2023-04-19.
//

import UIKit

public class QuranImageView: UIView {
    // MARK: Lifecycle

    public init(topView: UIView, bottomView: UIView, fullWindowView: Bool) {
        self.topView = topView
        self.bottomView = bottomView
        self.fullWindowView = fullWindowView
        super.init(frame: .zero)

        addSubview(scrollView)
        scrollView.addSubview(content)

        content.addAutoLayoutSubview(topView)
        topView.vc.horizontalEdges(inset: ContentDimension.interSpacing)
        topView.vc.top()

        content.addAutoLayoutSubview(bottomView)
        bottomView.vc.horizontalEdges()
        bottomView.vc.bottom()

        mainImageView.contentMode = .scaleAspectFit
        content.addSubview(mainImageView)

        scrollView.contentInsetAdjustmentBehavior = .never
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public let mainImageView = UIImageView()
    public let scrollView = UIScrollView()

    override public func layoutSubviews() {
        super.layoutSubviews()
        topView.layoutIfNeeded()
        bottomView.layoutIfNeeded()
        updateViewsLayout()
    }

    // MARK: Private

    private let content = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 0)))
    private let topView: UIView
    private let bottomView: UIView

    private let fullWindowView: Bool

    private func updateViewsLayout() {
        let margin = fullWindowView ? ContentDimension.insets(of: self) : .zero
        let imageTopMargin = topView.frame.height > 0 ? ContentDimension.interSpacing : 0
        let imageBottomMargin = bottomView.frame.height > 0 ? ContentDimension.interSpacing : 0
        scrollView.frame = bounds

        content.frame.origin.x = margin.leading
        content.frame.size.width = bounds.width - content.frame.minX - margin.trailing
        leadingOfParent([mainImageView])
        content.equalWidths([mainImageView])

        content.frame.origin.y = margin.top

        mainImageView.frame.origin.y = topView.frame.height + imageTopMargin

        let heightInset = content.frame.minY + mainImageView.frame.origin.y + imageTopMargin + margin.bottom + bottomView.bounds.height
        let imageAvailableHeight = bounds.height - heightInset

        let imageHeight: CGFloat
        if let imageSize = mainImageView.image?.size, mainImageView.frame.width > imageAvailableHeight {
            // add fill height
            imageHeight = mainImageView.frame.width * (imageSize.height / imageSize.width)
            scrollView.isScrollEnabled = true
        } else {
            // add fit height
            imageHeight = imageAvailableHeight
            scrollView.isScrollEnabled = false
        }

        mainImageView.frame.size.height = imageHeight

        bottomView.frame.origin.y = mainImageView.frame.maxY + imageBottomMargin
        content.frame.size.height = bottomView.frame.maxY
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: content.frame.maxY + margin.bottom)
    }
}

private extension UIView {
    func heightMatches(_ others: [UIView]) {
        frame.size.height = others.map(\.bounds.height).max()!
    }

    func leadingTopOfParent() {
        frame.origin = .zero
    }

    func trailingTopOfParent() {
        frame.origin = CGPoint(x: superview!.bounds.width - bounds.width, y: 0)
    }

    func equalWidths(_ others: [UIView]) {
        others.forEach { $0.frame.size.width = bounds.width }
    }

    func leadingOfParent(_ others: [UIView]) {
        others.forEach { $0.frame.origin.x = 0 }
    }
}
