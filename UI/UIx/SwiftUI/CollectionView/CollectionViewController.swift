//
//  CollectionViewController.swift
//
//
//  Created by Mohamed Afifi on 2024-01-08.
//

import SwiftUI

final class CollectionViewController<ItemContent: View>: UIViewController, UICollectionViewDelegate {
    typealias CellType = HostingCollectionViewCell<ItemContent>

    // MARK: Lifecycle

    init(collectionViewLayout: UICollectionViewLayout) {
        collectionView = .init(frame: .zero, collectionViewLayout: collectionViewLayout)
        super.init(nibName: nil, bundle: nil)
        collectionView.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? CellType)?.cellWillDisplay(animated: false)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        (cell as? CellType)?.cellDidEndDisplaying(animated: false)
    }

    // MARK: Internal

    let collectionView: UICollectionView

    override func loadView() {
        view = collectionView
    }
}
