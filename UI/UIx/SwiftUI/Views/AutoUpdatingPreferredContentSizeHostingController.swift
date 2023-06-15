//
//  AutoUpdatingPreferredContentSizeHostingController.swift
//
//
//  Created by Mohamed Afifi on 2023-01-29.
//

import SwiftUI

public class AutoUpdatingPreferredContentSizeHostingController<Content: View>: UIHostingController<Content> {
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = nil
    }

    override public func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        // animate the transition only if it is an update to a non-zero size
        if preferredContentSize == .zero || container.preferredContentSize == preferredContentSize {
            preferredContentSize = container.preferredContentSize
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0) {
                self.preferredContentSize = container.preferredContentSize
            }
        }
    }
}
