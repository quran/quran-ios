//
//  QuranView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

protocol QuranViewDelegate: class {
    func onQuranViewTapped(_ quranView: QuranView)
}

class QuranView: UIView {

    weak var delegate: QuranViewDelegate?

    private weak var bottomBarConstraint: NSLayoutConstraint?

    lazy var audioView: DefaultAudioBannerView = {
        let audioView = DefaultAudioBannerView()
        self.addAutoLayoutSubview(audioView)
        self.pinParentHorizontal(audioView)
        self.bottomBarConstraint = self.addParentBottomConstraint(audioView)
        return audioView
    }()

    lazy var collectionView: UICollectionView = {
        let layout = QuranPageFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        if #available(iOS 9.0, *) {
            collectionView.semanticContentAttribute = .forceRightToLeft
        }
        self.addAutoLayoutSubview(collectionView)
        self.pinParentAllDirections(collectionView)

        collectionView.backgroundColor = UIColor.readingBackground()
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(cell: QuranPageCollectionViewCell.self)

        return collectionView
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapped(_:))))
        bringSubview(toFront: audioView)
    }

    func visibleIndexPath() -> IndexPath? {
        let offset = collectionView.contentOffset
        return collectionView.indexPathForItem(at: CGPoint(x: offset.x + bounds.width / 2, y: 0))
    }

    func setBarsHidden(_ hidden: Bool) {
        if let bottomBarConstraint = self.bottomBarConstraint {
            removeConstraint(bottomBarConstraint)
        }
        if hidden {
            bottomBarConstraint = addSiblingVerticalContiguous(top: self, bottom: audioView)
        } else {
            bottomBarConstraint = addParentBottomConstraint(audioView)
        }
    }

    func onViewTapped(_ sender: UITapGestureRecognizer) {
        guard !audioView.bounds.contains(sender.location(in: audioView)) else {
            return
        }
        delegate?.onQuranViewTapped(self)
    }
}
