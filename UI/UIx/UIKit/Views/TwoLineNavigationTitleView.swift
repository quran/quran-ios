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

    /// Called when the title is tapped. Setting this enables a tap gesture; clearing it removes it.
    public var onTap: (() -> Void)? {
        didSet { updateTapGesture() }
    }

    override public var intrinsicContentSize: CGSize {
        label.attributedText?.size() ?? .zero
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateIsCompressed()
    }

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // When a tap handler is set, expand the hit area so taps reliably
        // register even if the navigation bar lays this view out tighter than
        // its visible label.
        if onTap != nil {
            let expanded = bounds.insetBy(dx: -60, dy: -12)
            if expanded.contains(point) { return true }
        }
        return super.point(inside: point, with: event)
    }

    // MARK: Private

    private let label = UILabel()

    private let firstLineFont: UIFont
    private let secondLineFont: UIFont

    private var isCompressed = false {
        didSet { updateAttributedText() }
    }

    private var tapGesture: UITapGestureRecognizer?
    private var didInvalidateOnFirstNonEmptyText = false

    private func setUp() {
        label.numberOfLines = 0
        label.textAlignment = .center

        label.translatesAutoresizingMaskIntoConstraints = false
        addAutoLayoutSubview(label)
        label.vc.center()
    }

    private func updateTapGesture() {
        if onTap != nil, tapGesture == nil {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            addGestureRecognizer(gesture)
            isUserInteractionEnabled = true
            tapGesture = gesture
        } else if onTap == nil, let tapGesture {
            removeGestureRecognizer(tapGesture)
            self.tapGesture = nil
        }
    }

    @objc
    private func handleTap() {
        onTap?()
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
        // Invalidate ONCE, the first time the text becomes non-empty. Without
        // this, the navigation bar keeps the zero-sized layout it computed
        // when this view was instantiated with empty text, and hit-testing
        // misses the title view. Skipping subsequent invalidations keeps
        // page-changes cheap (no UINavigationBar relayout per swipe).
        if !didInvalidateOnFirstNonEmptyText, !firstLine.isEmpty || !secondLine.isEmpty {
            didInvalidateOnFirstNonEmptyText = true
            invalidateIntrinsicContentSize()
        }
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
