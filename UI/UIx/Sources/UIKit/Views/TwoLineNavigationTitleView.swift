//
//  TwoLineNavigationTitleView.swift
//
//
//  Created by Mohamed Afifi on 2023-01-02.
//

import UIKit

public class TwoLineNavigationTitleView: UIView {
    // MARK: Lifecycle

    public init(firstLineFont: UIFont, secondLineFont: UIFont) {
        self.firstLineFont = firstLineFont
        self.secondLineFont = secondLineFont
        super.init(frame: .zero)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var firstLine: String = "" {
        didSet { updateAttributedText() }
    }

    public var secondLine: String = "" {
        didSet { updateAttributedText() }
    }

    override public var intrinsicContentSize: CGSize {
        label.attributedText?.size() ?? .zero
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateIsCompressed()
    }

    // MARK: Private

    private let label = UILabel()

    private let firstLineFont: UIFont
    private let secondLineFont: UIFont

    private var isCompressed = false {
        didSet { updateAttributedText() }
    }

    private func setUp() {
        label.numberOfLines = 0
        label.textAlignment = .center

        label.translatesAutoresizingMaskIntoConstraints = false
        addAutoLayoutSubview(label)
        label.vc.center()
    }

    private func updateIsCompressed(_ size: CGSize? = nil) {
        if let containerHeight = navigationBar?.bounds.height ?? size?.height {
            isCompressed = containerHeight < 34
        }
    }

    private func updateAttributedText() {
        let string = NSMutableAttributedString(string: firstLine, attributes: [
            .font: firstLineFont,
        ])
        if !isCompressed {
            string.append(NSAttributedString(string: "\n"))
        } else {
            string.append(NSAttributedString(string: "  "))
        }
        string.append(NSAttributedString(string: secondLine, attributes: [
            .font: secondLineFont,
        ]))
        label.attributedText = string
    }
}

private extension UIView {
    var navigationBar: UINavigationBar? {
        if let navigationBar = self as? UINavigationBar {
            return navigationBar
        } else {
            return superview?.navigationBar
        }
    }
}
