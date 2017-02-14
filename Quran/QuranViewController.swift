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

class QuranViewController: UIViewController, AudioBannerViewPresenterDelegate, QuranPagesDataSourceDelegate {

    private let bookmarksPersistence: BookmarksPersistence
    private let lastPagesPersistence: LastPagesPersistence

    private let dataRetriever: AnyDataRetriever<[QuranPage]>

    private let pageDataSource: QuranPagesDataSource

    private let audioViewPresenter: AudioBannerViewPresenter
    private let qarisControllerCreator: AnyCreator<QariTableViewController, Void>

    private let scrollToPageToken = Once()
    private let didLayoutSubviewToken = Once()

    private var isBookmarked: Bool?
    private var backButtonItem: UIBarButtonItem? = nil

    private var lastPageUpdater: LastPageUpdater!

    init(imageService: QuranImageService,
         dataRetriever: AnyDataRetriever<[QuranPage]>,
         ayahInfoRetriever: AyahInfoRetriever,
         audioViewPresenter: AudioBannerViewPresenter,
         qarisControllerCreator: AnyCreator<QariTableViewController, Void>,
         bookmarksPersistence: BookmarksPersistence,
         lastPagesPersistence: LastPagesPersistence,
         page: Int,
         lastPage: LastPage?) {
        self.dataRetriever          = dataRetriever
        self.audioViewPresenter     = audioViewPresenter
        self.qarisControllerCreator = qarisControllerCreator
        self.bookmarksPersistence   = bookmarksPersistence
        self.lastPagesPersistence   = lastPagesPersistence
        self.initialPage            = page
        self.lastPageUpdater        = LastPageUpdater(persistence: lastPagesPersistence)

        self.pageDataSource = QuranPagesDataSource(
            reuseIdentifier: cellReuseId,
            imageService: imageService,
            ayahInfoRetriever: ayahInfoRetriever,
            bookmarkPersistence: bookmarksPersistence)

        super.init(nibName: nil, bundle: nil)

        self.lastPageUpdater.configure(initialPage: page, lastPage: lastPage)

        audioViewPresenter.delegate = self
        self.pageDataSource.delegate = self

        automaticallyAdjustsScrollViewInsets = false

        // page behavior
        let pageBehavior = ScrollViewPageBehavior()
        pageDataSource.scrollViewDelegate = pageBehavior
        observe(retainedObservable: pageBehavior, keyPath: "currentPage", options: [.new]) { [weak self] (_, _: ChangeData<Int>) in
            self?.onPageChanged()
        }
        backButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    private var initialPage: Int = 0 {
        didSet {
            title = Quran.nameForSura(Quran.PageSuraStart[initialPage - 1])
            backButtonItem?.title = title
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

    override var prefersStatusBarHidden: Bool {
        return statusBarHidden || traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact))
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func loadView() {
        view = QuranView()

        createCollectionView()
        createAudioBanner()

        // hide bars on tap
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapped(_:))))

    }

    fileprivate func createAudioBanner() {
        let audioView = DefaultAudioBannerView()
        view.addAutoLayoutSubview(audioView)
        _ = view.pinParentHorizontal(audioView)
        bottomBarConstraint = view.addParentBottomConstraint(audioView)

        self.audioView = audioView
    }

    fileprivate func createCollectionView() {
        let layout = QuranPageFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        if #available(iOS 9.0, *) {
            collectionView.semanticContentAttribute = .forceRightToLeft
        }
        view.addAutoLayoutSubview(collectionView)
        _ = view.pinParentAllDirections(collectionView)

        collectionView.backgroundColor = UIColor.readingBackground()
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(UINib(nibName: "QuranPageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellReuseId)
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

        // hide the title, because we'll set it on the left side
        navigationItem.titleView = UILabel()
        navigationController?.navigationBar.topItem?.backBarButtonItem = backButtonItem

        // start hiding bars timer
        startHiddenBarsTimer()
    }

    fileprivate var interactivePopGestureOldEnabled: Bool?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
        interactivePopGestureOldEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = interactivePopGestureOldEnabled ?? true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didLayoutSubviewToken.once {}
        scrollToFirstPage()
    }

    fileprivate func scrollToFirstPage() {
        guard let index = pageDataSource.items.index(where: { $0.pageNumber == initialPage }), didLayoutSubviewToken.executed else {
            return
        }

        scrollToPageToken.once {
            let indexPath = IndexPath(item: index, section: 0)
            scrollToIndexPath(indexPath, animated: false)

            onPageChangedToPage(pageDataSource.item(at: indexPath))
        }
    }

    func stopBarHiddenTimer() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - QuranPagesDataSourceDelegate

    func share(ayahText: String, from cell: QuranPageCollectionViewCell) {
        ShareController.showShareActivityWithText(ayahText, sourceViewController: self, handler: nil)
    }

    func lastViewedPage() -> Int {
        return lastPageUpdater.lastPage?.page ?? initialPage
    }

    // MARK: - Gestures recognizers handlers

    func onViewTapped(_ sender: UITapGestureRecognizer) {
        guard let audioView = audioView, !audioView.bounds.contains(sender.location(in: audioView)) else {
            return
        }
        setBarsHidden(navigationController?.isNavigationBarHidden == false)
    }

    fileprivate func setBarsHidden(_ hidden: Bool) {
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

        UIView.animate(withDuration: 0.3, animations: {
            self.statusBarHidden = hidden
            self.view.layoutIfNeeded()
        })

        // remove the timer
        stopBarHiddenTimer()
    }

    fileprivate func startHiddenBarsTimer() {
        timer = Timer(interval: 3) { [weak self] in
            self?.setBarsHidden(true)
        }
    }

    fileprivate func scrollToIndexPath(_ indexPath: IndexPath, animated: Bool) {
        collectionView?.scrollToItem(at: indexPath,
                                                at: .centeredHorizontally,
                                                animated: false)
    }

    fileprivate func onPageChanged() {
        guard let page = currentPage() else { return }
        onPageChangedToPage(page)
    }

    fileprivate func onPageChangedToPage(_ page: QuranPage) {
        updateBarToPage(page)
    }

    fileprivate func updateBarToPage(_ page: QuranPage) {
        title = Quran.nameForSura(page.startAyah.sura)
        backButtonItem?.title = title

        isBookmarked = nil
        Queue.bookmarks.async({ (self.bookmarksPersistence.isPageBookmarked(page.pageNumber), page.pageNumber) }) { (bookmarked, page) in
            guard page == self.currentPage()?.pageNumber else { return }
            self.isBookmarked = bookmarked
            self.showBookmarkIcon(selected: bookmarked)
        }

        // only persist if active
        if UIApplication.shared.applicationState == .active {
            Crash.setValue(page.pageNumber, forKey: .QuranPage)
            lastPageUpdater.updateTo(page: page.pageNumber)
        }
    }

    private func showBookmarkIcon(selected: Bool) {
        let item: UIBarButtonItem
        if selected {
            item = UIBarButtonItem(image: UIImage(named: "bookmark-filled"), style: .plain, target: self, action: #selector(bookmarkButtonTapped))
            item.tintColor = UIColor.bookmark()
        } else {
            item = UIBarButtonItem(image: UIImage(named: "bookmark-empty"), style: .plain, target: self, action: #selector(bookmarkButtonTapped))
        }
        navigationItem.rightBarButtonItem = item
    }

    @objc private func bookmarkButtonTapped() {
        guard let isBookmarked = isBookmarked, let page = currentPage() else { return }
        self.isBookmarked = !isBookmarked
        showBookmarkIcon(selected: !isBookmarked)

        if isBookmarked {
            Queue.background.async { try? self.bookmarksPersistence.removePageBookmark(atPage: page.pageNumber) }
        } else {
            Queue.background.async { try? self.bookmarksPersistence.insertPageBookmark(forPage: page.pageNumber) }
        }
    }

    func showQariListSelectionWithQari(_ qaris: [Qari], selectedIndex: Int) {
        let controller = qarisControllerCreator.create(parameters: Void())
        controller.setQaris(qaris)
        controller.selectedIndex = selectedIndex
        controller.onSelectedIndexChanged = { [weak self] index in
            self?.audioViewPresenter.setQariIndex(index)
        }

        controller.preferredContentSize = CGSize(width: 400, height: 500)
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.delegate = self
        controller.popoverPresentationController?.sourceView = audioView
        controller.popoverPresentationController?.sourceRect = audioView?.bounds ?? CGRect.zero
        controller.popoverPresentationController?.permittedArrowDirections = .down
        present(controller, animated: true, completion: nil)
    }

    func highlightAyah(_ ayah: AyahNumber) {
        var set = Set<AyahNumber>()
        set.insert(ayah)
        pageDataSource.highlightAyaht(set)

        // persist if not active
        guard UIApplication.shared.applicationState != .active else { return }
        Queue.background.async {
            let page = ayah.getStartPage()
            self.lastPageUpdater.updateTo(page: page)
            Crash.setValue(page, forKey: .QuranPage)
        }
    }

    func removeHighlighting() {
        pageDataSource.highlightAyaht(Set())
    }

    func currentPage() -> QuranPage? {
        guard let offset = collectionView?.contentOffset,
            let indexPath = collectionView?.indexPathForItem(at: CGPoint(x: offset.x + view.bounds.width / 2, y: 0)) else {
            return nil
        }
        let page = pageDataSource.item(at: indexPath)
        return page
    }
}

extension QuranViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .fullScreen
    }

    func presentationController(_ controller: UIPresentationController,
                                viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return QariNavigationController(rootViewController: controller.presentedViewController)
    }
}
