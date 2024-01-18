//
//  CollectionViewController.swift
//
//
//  Created by Mohamed Afifi on 2024-01-08.
//

import SwiftUI

final class CollectionViewController<
    SectionId: Hashable,
    Item: Identifiable & Hashable,
    ItemContent: View
>: UIViewController, UICollectionViewDelegate {
    typealias CellType = HostingCollectionViewCell<ItemContent>

    // MARK: Lifecycle

    init(
        collectionViewLayout: UICollectionViewLayout,
        content: @escaping (SectionId, Item) -> ItemContent
    ) {
        collectionView = .init(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear

        super.init(nibName: nil, bundle: nil)
        collectionView.delegate = self

        setUpDataSource(content: content)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let collectionView: UICollectionView
    lazy var scroller = CollectionViewScroller<SectionId, Item>(collectionView: collectionView)

    var dataSource: CollectionViewDataSource<SectionId, Item>? {
        didSet {
            scroller.dataSource = dataSource
        }
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        scroller.scrollToInitialItemIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        scroller.animateToSize(size, with: coordinator)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroller.scrollToAnchoredItemIfNeeded()
    }

    // MARK: - Cell Lifecycle

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? CellType)?.cellWillDisplay(animated: false)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        (cell as? CellType)?.cellDidEndDisplaying(animated: false)
    }

    // MARK: - Paging

    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        scroller.targetContentOffsetForProposedContentOffset(proposedContentOffset)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetContentOffset.pointee = scroller.targetContentOffsetForProposedContentOffset(targetContentOffset.pointee)
    }

    // MARK: - Scrolling

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scroller.startInteractiveScrolling()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scroller.endInteractiveScrolling()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scroller.endInteractiveScrolling()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scroller.endInteractiveScrolling()
    }

    override func loadView() {
        view = collectionView
    }

    // MARK: Private

    private func setUpDataSource(content: @escaping (SectionId, Item) -> ItemContent) {
        collectionView.register(CellType.self, forCellWithReuseIdentifier: CellType.reuseId)

        dataSource = CollectionViewDataSource(collectionView: collectionView) {
            [weak self] _, indexPath, itemId in
            guard let self, let dataSource else {
                return nil
            }

            guard let section = dataSource.section(from: indexPath), let item = dataSource.item(at: indexPath) else {
                return nil
            }

            assert(item.id == itemId, "Sections data doesn't match data source snapshot.")

            // Get & configure the cell.
            let cell = collectionView.dequeueReusableCell(CellType.self, for: indexPath)
            cell.configure(content: content(section.id, item), dataId: itemId)

            return cell
        }
    }
}
