//
//  HostingCollectionViewCell.swift
//
//
//  Created by Mohamed Afifi on 2024-01-07.
//

import SwiftUI

final class HostingCollectionViewCell<Content: View>: UICollectionViewCell {
    // MARK: Internal

    func configure(content: Content, dataId: AnyHashable) {
        self.dataId = dataId
        let content = EpoxySwiftUIHostingView<Content>.Content(rootView: content, dataID: dataId)
        if let hostingView {
            hostingView.setContent(content, animated: false)
        } else {
            let hostingView = EpoxySwiftUIHostingView(style: .init(reuseBehavior: .reusable, initialContent: content))
            setViewIfNeeded(view: hostingView)
        }
    }

    func cellWillDisplay(animated: Bool) {
        hostingView?.handleWillDisplay(animated: animated)
    }

    func cellDidEndDisplaying(animated: Bool) {
        hostingView?.handleDidEndDisplaying(animated: animated)
    }

    // MARK: Private

    private var dataId: AnyHashable?
    private var hostingView: EpoxySwiftUIHostingView<Content>?

    private func setViewIfNeeded(view: EpoxySwiftUIHostingView<Content>) {
        guard hostingView == nil else {
            return
        }
        hostingView = view

        view.translatesAutoresizingMaskIntoConstraints = false
        // Use the existing content view size so that we don't have to wait for auto layout to give this
        // view an initial size.
        view.frame = contentView.bounds
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
