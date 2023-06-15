//
//  PopoverNavigationController.swift
//
//
//  Created by Afifi, Mohamed on 9/6/21.
//

import UIKit

private class ContentSizeUpdatableNavigationController: UINavigationController {
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        preferredContentSize = container.preferredContentSize
    }
}

public class PopoverNavigationController: UIViewController, UINavigationControllerDelegate {
    public let wrapped: UINavigationController

    public init(rootViewController: UIViewController) {
        wrapped = ContentSizeUpdatableNavigationController(rootViewController: rootViewController)
        super.init(nibName: nil, bundle: nil)
        wrapped.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        addFullScreenChild(wrapped)
    }

    override public func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        preferredContentSize = container.preferredContentSize
    }

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.preferredContentSize = viewController.preferredContentSize
    }
}
