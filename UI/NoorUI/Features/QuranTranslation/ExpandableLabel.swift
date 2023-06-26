//
//  ExpandableLabel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/23/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import UIKit
import UIx

private enum ExpandState {
    case initial
    case expanded
    case collapsed
}

@MainActor
public class ExpandableLabel {
    // MARK: Lifecycle

    public init() {
        // add the button
        button.normalBackground = .clear
        button.disabledBackground = .clear
        button.highlightedBackground = .systemGray5
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        view.addAutoLayoutSubview(button)
        button.vc.edges()

        // configure the label
        label.onDisplayFinished = { [weak self] in
            self?.isDisplayingSnapshot = false
            self?.updateButtonAvailability()
        }
        view.addAutoLayoutSubview(label.view)
        label.view.vc.edges()
    }

    // MARK: Public

    public let view = UIView()

    public var onExpandCollapseButtonTapped: (() -> Void)?
    public var collapsedNumberOfLines: UInt = 0

    public var attributedText: NSAttributedString? {
        get { label.attributedText }
        set { label.attributedText = newValue }
    }

    public var truncationAttributedText: NSAttributedString? {
        get { label.truncationAttributedText }
        set { label.truncationAttributedText = newValue }
    }

    public func prepareForReuse() {
        expandState = .initial

        isDisplayingSnapshot = false
        snapshot?.removeFromSuperview()
        snapshot = nil

        label.clearContents()
        label.view.isHidden = false
    }

    public func showAsExpanded(_ isExpanded: Bool) {
        switch expandState {
        case .initial:
            break
        case .collapsed:
            isDisplayingSnapshot = isExpanded
        case .expanded:
            isDisplayingSnapshot = !isExpanded
        }
        label.maximumNumberOfLines = isExpanded ? 0 : collapsedNumberOfLines
        label.setNeedsLayout()
        expandState = isExpanded ? .expanded : .collapsed
    }

    public func heightThatFits(width: CGFloat) -> CGFloat {
        let min = CGSize(width: width, height: 0)
        let max = CGSize(width: width, height: .infinity)
        let size = label.sizeThatFits(min: min, max: max)
        return size.height
    }

    // MARK: Internal

    var isTruncated: Bool {
        label.isTruncated
    }

    var lineCount: UInt {
        label.lineCount
    }

    // MARK: Private

    private let button = BackgroundColorButton()
    private var label = AsyncTextLabelSystem.factory()

    private var snapshot: UIView?
    private var expandState: ExpandState = .initial

    private var isDisplayingSnapshot = false {
        didSet {
            if isDisplayingSnapshot == oldValue {
                return
            }
            if isDisplayingSnapshot {
                showSnapshot()
            } else {
                removeSnapshot()
            }
        }
    }

    private func expand() {
        switch expandState {
        case .initial, .expanded:
            break
        case .collapsed:
            isDisplayingSnapshot = true
        }
    }

    private func collapse() {
        switch expandState {
        case .initial, .collapsed:
            break
        case .expanded:
            isDisplayingSnapshot = true
        }
    }

    // MARK: - Snapshot

    private func showSnapshot() {
        label.view.isHidden = true
        if isDisplayingSnapshot {
            if let snapshot = label.view.snapshotView(afterScreenUpdates: false) {
                label.view.superview?.addAutoLayoutSubview(snapshot)
                snapshot.vc.leading(to: label.view)
                snapshot.vc.trailing(to: label.view)
                snapshot.vc.top(to: label.view)
                snapshot.vc.height(by: label.view.bounds.height) // fix the height as label will change height
                self.snapshot = snapshot
            }
        }
    }

    private func removeSnapshot() {
        label.view.isHidden = false
        snapshot?.removeFromSuperview()
        snapshot = nil
    }

    // MARK: - Button

    private func updateButtonAvailability() {
        button.isEnabled = collapsedNumberOfLines != 0 && (label.isTruncated || label.lineCount > collapsedNumberOfLines)
    }

    @objc
    private func buttonTapped() {
        onExpandCollapseButtonTapped?()
    }
}
