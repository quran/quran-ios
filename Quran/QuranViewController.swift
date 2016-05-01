//
//  QuranViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class QuranViewController: UIViewController {

//    let audioView: AudioBannerView = unimplemented()
//    let pageDataSource: QuranPagesDataSource = unimplemented()

    var currentPage: Int = 0

    weak var collectionView: UICollectionView!

    var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return statusBarHidden
    }

    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }

    override func loadView() {
        super.loadView()

        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.addAutoLayoutSubview(collectionView)
        view.pinParentAllDirections(collectionView)

        collectionView.backgroundColor = UIColor.whiteColor()

        self.collectionView = collectionView

        // hide bars on tap
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapped(_:))))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print(currentPage)
    }

    func onViewTapped(sender: UITapGestureRecognizer) {
        navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: true)
        statusBarHidden = navigationController?.navigationBarHidden == true
    }
}
