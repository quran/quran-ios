//
//  QuranViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

private let cellReuseId = "cell"

class QuranViewController: UIViewController {

//    let audioView: AudioBannerView = unimplemented()
    let pageDataSource: QuranPagesDataSource

    let pagesRange = Truth.QuranPagesRange

    init(imageService: QuranImageService) {
        pageDataSource = QuranPagesDataSource(reuseIdentifier: cellReuseId, imageService: imageService)
        super.init(nibName: nil, bundle: nil)
        automaticallyAdjustsScrollViewInsets = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var currentPage: Int = 0

    weak var collectionView: UICollectionView?
    weak var layout: UICollectionViewFlowLayout?

    var timer: Timer?

    var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return statusBarHidden || traitCollection.containsTraitsInCollection(UITraitCollection(verticalSizeClass: .Compact))
    }

    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func loadView() {
        super.loadView()

        let layout = QuranPageFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        if #available(iOS 9.0, *) {
            collectionView.semanticContentAttribute = .ForceRightToLeft
        }
        view.addAutoLayoutSubview(collectionView)
        view.pinParentAllDirections(collectionView)

        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.pagingEnabled = true
        collectionView.registerNib(UINib(nibName: "QuranPageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellReuseId)
        collectionView.ds_useDataSource(pageDataSource)

        self.layout = layout
        self.collectionView = collectionView

        // hide bars on tap
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapped(_:))))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // load the list of items
        pageDataSource.items = pagesRange.map { QuranPage(pageNumber: $0) }

        print(currentPage)

        // start bars timer
        startHiddenBarsTimer()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    var scrollToPageToken = Once()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollToPageToken.once {
            guard let index = self.pagesRange.indexOf(self.currentPage) else {
                return
            }
            self.scrollToIndexPath(NSIndexPath(forItem: index - self.pagesRange.startIndex, inSection: 0), animated: false)
        }
    }

//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//
//        coordinator.animateAlongsideTransition({ (_) in
//            self.layout?.invalidateLayout()
//            }, completion: nil)
//
////        guard let visibleIndex = collectionView?.indexPathsForVisibleItems().first else {
////            return
////        }
//
//
//    }

    func onViewTapped(sender: UITapGestureRecognizer) {
        setBarsHidden(navigationController?.navigationBarHidden == false)
    }

    private func setBarsHidden(hidden: Bool) {
        navigationController?.setNavigationBarHidden(hidden, animated: true)
        UIView.animateWithDuration(0.3) {
            self.statusBarHidden = self.navigationController?.navigationBarHidden == true
        }

        // remove the timer
        timer = nil
    }

    private func startHiddenBarsTimer() {
        timer = Timer(interval: 2) { [weak self] in
            self?.setBarsHidden(true)
        }
    }

    private func scrollToIndexPath(indexPath: NSIndexPath, animated: Bool) {
        // The 0 delay is a workaround for semanticContentAttribute = .ForceRightToLeft
        Queue.main.after(0) {
            self.collectionView?.scrollToItemAtIndexPath(indexPath,
                                                    atScrollPosition: .CenteredHorizontally,
                                                    animated: false)
        }
    }
}
