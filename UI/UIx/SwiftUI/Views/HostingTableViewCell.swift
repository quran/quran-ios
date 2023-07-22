//
//  HostingTableViewCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/26/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
private class NoNavigationHostingController<C: View>: UIHostingController<C> {
    override var navigationController: UINavigationController? {
        nil
    }
}

@available(iOS 13.0, *)
private final class ViewHostingController<Content: View> {
    // MARK: Lifecycle

    init(view: UIView, contentView: UIView?) {
        self.view = view
        self.contentView = contentView ?? view
        hostingController.view.backgroundColor = .clear
    }

    deinit {
        // remove parent
        hostingController.parent?.removeChild(hostingController)
    }

    // MARK: Internal

    func set(rootView: Content, parentController: UIViewController) {
        guard let contentView else {
            return
        }
        hostingController.rootView = rootView
        hostingController.view.invalidateIntrinsicContentSize()

        let requiresControllerMove = hostingController.parent != parentController
        if requiresControllerMove {
            // remove old parent if exists
            hostingController.parent?.removeChild(hostingController)
            parentController.addChild(hostingController)
        }

        if !contentView.subviews.contains(hostingController.view) {
            contentView.addAutoLayoutSubview(hostingController.view)
            hostingController.view.vc.edges()
        }

        if requiresControllerMove {
            hostingController.didMove(toParent: parentController)
        }
    }

    // MARK: Private

    private let hostingController = NoNavigationHostingController<Content?>(rootView: nil)

    private weak var view: UIView?
    private weak var contentView: UIView?
}

@available(iOS 13.0, *)
public final class HostingTableViewCell<Content: View>: UITableViewCell {
    // MARK: Public

    public func set(rootView: Content, parentController: UIViewController) {
        hostingController.set(rootView: rootView, parentController: parentController)
    }

    // MARK: Private

    private lazy var hostingController = ViewHostingController<Content?>(view: self, contentView: contentView)
}
