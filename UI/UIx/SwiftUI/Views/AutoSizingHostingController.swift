//
//  AutoSizingHostingController.swift
//
//
//  Created by Afifi, Mohamed on 8/1/21.
//

import SwiftUI

@available(iOS 13.0, *)
public class AutoSizingHostingController<Content: View>: UIHostingController<Content> {
    public var maxPreferredContentSize = CGSize(width: .max, height: .max)

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSize()
    }

    private func setPreferredContentSize(_ newSize: CGSize) {
        // animate the transition only if it is an update to a non-zero size
        if preferredContentSize == .zero || newSize == preferredContentSize {
            preferredContentSize = newSize
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0) {
                self.preferredContentSize = newSize
            }
        }
    }

    private func updatePreferredContentSize() {
        let newSize = sizeThatFits(in: .zero)
        setPreferredContentSize(CGSize(width: min(maxPreferredContentSize.width, newSize.width),
                                       height: min(maxPreferredContentSize.height, newSize.height)))
    }
}
