//
//  AsyncTextLabel.swift
//
//
//  Created by Mohamed Afifi on 2023-06-20.
//

import UIKit

// TODO: Remove when Texture supports swift package manager.

public protocol AsyncTextLabel {
    init()
    var view: UIView { get }

    var maximumNumberOfLines: UInt { get set }
    var attributedText: NSAttributedString? { get set }
    var truncationAttributedText: NSAttributedString? { get set }

    var onDisplayFinished: (() -> Void)? { get set }

    var isTruncated: Bool { get }
    var lineCount: UInt { get }

    func setNeedsLayout()
    func clearContents()
    func sizeThatFits(min: CGSize, max: CGSize) -> CGSize
}

public enum AsyncTextLabelSystem {
    // MARK: Public

    public static func bootstrap(_ factory: @escaping () -> AsyncTextLabel) {
        lock.sync {
            precondition(!initialized, "AsyncTextLabelSystem can only be initialized once.")
            self.factory = factory
            initialized = true
        }
    }

    // MARK: Internal

    private(set) static var factory: (() -> AsyncTextLabel)!

    // MARK: Private

    private static let lock = NSLock()
    private static var initialized = false
}
