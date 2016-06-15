//
//  QuranViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import KVOController_Swift

private let cellReuseId = "cell"

class QuranViewController: UIViewController, AudioBannerViewPresenterDelegate {

    let persistence: SimplePersistence
    let dataRetriever: AnyDataRetriever<[QuranPage]>

    let pageDataSource: QuranPagesDataSource

    let audioViewPresenter: AudioBannerViewPresenter
    let qarisControllerCreator: AnyCreator<QariTableViewController>

    let scrollToPageToken = Once()
    let didLayoutSubviewToken = Once()

    init(persistence: SimplePersistence,
         imageService: QuranImageService,
         dataRetriever: AnyDataRetriever<[QuranPage]>,
         ayahInfoRetriever: AyahInfoRetriever,
         audioViewPresenter: AudioBannerViewPresenter,
         qarisControllerCreator: AnyCreator<QariTableViewController>) {
        self.persistence = persistence
        self.dataRetriever = dataRetriever
        self.audioViewPresenter = audioViewPresenter
        self.qarisControllerCreator = qarisControllerCreator
        self.pageDataSource = QuranPagesDataSource(reuseIdentifier: cellReuseId, imageService: imageService, ayahInfoRetriever: ayahInfoRetriever)
        super.init(nibName: nil, bundle: nil)

        audioViewPresenter.delegate = self

        automaticallyAdjustsScrollViewInsets = false

        // page behavior
        let pageBehavior = ScrollViewPageBehavior()
        pageDataSource.scrollViewDelegate = pageBehavior
        observe(retainedObservable: pageBehavior, keyPath: "currentPage", options: [.New]) { [weak self] (observable, change: ChangeData<Int>) in
            self?.onPageChanged()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var initialPage: Int = 0 {
        didSet {
            title = Quran.nameForSura(Quran.PageSuraStart[initialPage - 1])
        }
    }

    weak var audioView: DefaultAudioBannerView? {
        didSet {
            audioView?.onTouchesBegan = { [weak self] in
                self?.stopBarHiddenTimer()
            }
            audioViewPresenter.view = audioView
            audioView?.delegate = audioViewPresenter
        }
    }

    weak var collectionView: UICollectionView?
    weak var layout: UICollectionViewFlowLayout?
    weak var bottomBarConstraint: NSLayoutConstraint?

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
        view = QuranView()

        createCollectionView()
        createAudioBanner()

        // hide bars on tap
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapped(_:))))
        
    }

    private func createAudioBanner() {
        let audioView = DefaultAudioBannerView()
        view.addAutoLayoutSubview(audioView)
        view.pinParentHorizontal(audioView)
        bottomBarConstraint = view.addParentBottomConstraint(audioView)

        self.audioView = audioView
    }

    private func createCollectionView() {
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

        collectionView.backgroundColor = UIColor.readingBackground()
        collectionView.pagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(UINib(nibName: "QuranPageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellReuseId)
        collectionView.ds_useDataSource(pageDataSource)

        self.layout = layout
        self.collectionView = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataRetriever.retrieve { [weak self] (data: [QuranPage]) in
            self?.pageDataSource.items = data
            self?.collectionView?.reloadData()
            self?.scrollToFirstPage()
        }

        audioViewPresenter.onViewDidLoad()

        // start hidding bars timer
        startHiddenBarsTimer()
    }

    private var interactivePopGestureOldEnabled: Bool?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().idleTimerDisabled = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
        interactivePopGestureOldEnabled = navigationController?.interactivePopGestureRecognizer?.enabled
        navigationController?.interactivePopGestureRecognizer?.enabled = false
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.sharedApplication().idleTimerDisabled = false
        navigationController?.interactivePopGestureRecognizer?.enabled = interactivePopGestureOldEnabled ?? true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didLayoutSubviewToken.once {}
        scrollToFirstPage()
    }

    private func scrollToFirstPage() {
        guard let index = pageDataSource.items.indexOf({ $0.pageNumber == initialPage }) where didLayoutSubviewToken.executed else {
            return
        }

        scrollToPageToken.once {
            let indexPath = NSIndexPath(forItem: index, inSection: 0)
            scrollToIndexPath(indexPath, animated: false)

            onPageChangedToPage(pageDataSource.itemAtIndexPath(indexPath))
        }
    }

    func stopBarHiddenTimer() {
        timer?.cancel()
        timer = nil
    }
    

    //MARK: - Gestures recognizers handlers -
    
    func onViewTapped(sender: UITapGestureRecognizer) {
        guard let audioView = audioView where !audioView.bounds.contains(sender.locationInView(audioView)) else {
            return
        }

        setBarsHidden(navigationController?.navigationBarHidden == false)
    }

    private func setBarsHidden(hidden: Bool) {
        navigationController?.setNavigationBarHidden(hidden, animated: true)

        if let bottomBarConstraint = bottomBarConstraint {
            view.removeConstraint(bottomBarConstraint)
        }
        if let audioView = audioView {
            if hidden {
                bottomBarConstraint = view.addSiblingVerticalContiguous(top: view, bottom: audioView)
            } else {
                bottomBarConstraint = view.addParentBottomConstraint(audioView)
            }
        }

        UIView.animateWithDuration(0.3) {
            self.statusBarHidden = hidden
            self.view.layoutIfNeeded()
        }

        // remove the timer
        stopBarHiddenTimer()
    }

    private func startHiddenBarsTimer() {
        timer = Timer(interval: 3) { [weak self] in
            self?.setBarsHidden(true)
        }
    }

    private func scrollToIndexPath(indexPath: NSIndexPath, animated: Bool) {
        collectionView?.scrollToItemAtIndexPath(indexPath,
                                                atScrollPosition: .CenteredHorizontally,
                                                animated: false)
    }

    private func onPageChanged() {
        guard let page = currentPage() else { return }
        onPageChangedToPage(page)
    }

    private func onPageChangedToPage(page: QuranPage) {
        updateBarToPage(page)
    }

    private func updateBarToPage(page: QuranPage) {
        title = Quran.nameForSura(page.startAyah.sura)

        // only persist if active
        if UIApplication.sharedApplication().applicationState == .Active {
            persistence.setValue(page.pageNumber, forKey: PersistenceKeyBase.LastViewedPage)
            Crash.setValue(page.pageNumber, forKey: .QuranPage)
        }
    }

    func showQariListSelectionWithQari(qaris: [Qari], selectedIndex: Int) {
        let controller = qarisControllerCreator.create()
        controller.setQaris(qaris)
        controller.selectedIndex = selectedIndex
        controller.onSelectedIndexChanged = { [weak self] index in
            self?.audioViewPresenter.setQariIndex(index)
        }

        controller.preferredContentSize = CGSize(width: 400, height: 500)
        controller.modalPresentationStyle = .Popover
        controller.popoverPresentationController?.delegate = self
        controller.popoverPresentationController?.sourceView = audioView
        controller.popoverPresentationController?.sourceRect = audioView?.bounds ?? CGRect.zero
        controller.popoverPresentationController?.permittedArrowDirections = .Down
        presentViewController(controller, animated: true, completion: nil)
    }

    func highlightAyah(ayah: AyahNumber) {
        var set = Set<AyahNumber>()
        set.insert(ayah)
        pageDataSource.highlightAyaht(set)

        // persist if not active
        guard UIApplication.sharedApplication().applicationState != .Active else { return }
        Queue.background.async {
            let page = ayah.getStartPage()
            self.persistence.setValue(page, forKey: PersistenceKeyBase.LastViewedPage)
            Crash.setValue(page, forKey: .QuranPage)
        }
    }

    func removeHighlighting() {
        pageDataSource.highlightAyaht(Set())
    }

    func currentPage() -> QuranPage? {
        guard let offset = collectionView?.contentOffset,
            let indexPath = collectionView?.indexPathForItemAtPoint(CGPoint(x: offset.x + view.bounds.width / 2, y: 0)) else {
            return nil
        }
        let page = pageDataSource.itemAtIndexPath(indexPath)
        return page
    }
}

extension QuranViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .FullScreen
    }

    func presentationController(controller: UIPresentationController,
                                viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return QariNavigationController(rootViewController: controller.presentedViewController)
    }
}
