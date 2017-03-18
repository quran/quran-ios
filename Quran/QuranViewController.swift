//
//  QuranViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import KVOController

private let cellReuseId = "cell"

class QuranViewController: UIViewController, AudioBannerViewPresenterDelegate, QuranPagesDataSourceDelegate {

    private let bookmarksPersistence: BookmarksPersistence
    private let lastPagesPersistence: LastPagesPersistence
    private let dataRetriever: AnyDataRetriever<[QuranPage]>
    private let audioViewPresenter: AudioBannerViewPresenter
    private let qarisControllerCreator: AnyCreator<QariTableViewController, Void>
    private let simplePersistence: SimplePersistence
    private var lastPageUpdater: LastPageUpdater!

    private let pageDataSource: QuranPagesDataSource

    private let scrollToPageToken = Once()
    private let didLayoutSubviewToken = Once()

    private var titleView: QuranPageTitleView? { return navigationItem.titleView as? QuranPageTitleView }
    private weak var collectionView: UICollectionView?
    private weak var layout: UICollectionViewFlowLayout?
    private weak var bottomBarConstraint: NSLayoutConstraint?

    private var barsTimer: Timer?

    private weak var audioView: DefaultAudioBannerView? {
        didSet {
            audioView?.onTouchesBegan = { [weak self] in
                self?.stopBarHiddenTimer()
            }
            audioViewPresenter.view = audioView
            audioView?.delegate = audioViewPresenter
        }
    }

    private var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    private var initialPage: Int = 0 {
        didSet {
            title = Quran.nameForSura(Quran.PageSuraStart[initialPage - 1])
            updateTitle(sura: Quran.nameForSura(Quran.PageSuraStart[initialPage - 1]), pageNumber: initialPage)
        }
    }

    private var isBookmarked: Bool = false
    private var isTranslationView: Bool {
        set { simplePersistence.setValue(newValue, forKey: .showQuranTranslationView) }
        get { return simplePersistence.valueForKey(.showQuranTranslationView) }
    }

    init(imageService: QuranImageService,
         dataRetriever: AnyDataRetriever<[QuranPage]>,
         ayahInfoRetriever: AyahInfoRetriever,
         audioViewPresenter: AudioBannerViewPresenter,
         qarisControllerCreator: AnyCreator<QariTableViewController, Void>,
         bookmarksPersistence: BookmarksPersistence,
         lastPagesPersistence: LastPagesPersistence,
        simplePersistence: SimplePersistence,
         page: Int,
         lastPage: LastPage?) {
        self.dataRetriever          = dataRetriever
        self.audioViewPresenter     = audioViewPresenter
        self.qarisControllerCreator = qarisControllerCreator
        self.bookmarksPersistence   = bookmarksPersistence
        self.lastPagesPersistence   = lastPagesPersistence
        self.initialPage            = page
        self.lastPageUpdater        = LastPageUpdater(persistence: lastPagesPersistence)
        self.simplePersistence      = simplePersistence

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
        kvoController.observe(pageBehavior, keyPath: "currentPage", options: .new) { [weak self] (_, _, _) in
            self?.onPageChanged()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
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
        view.pinParentHorizontal(audioView)
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
        view.pinParentAllDirections(collectionView)

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

        // set the custom title view
        navigationItem.titleView = QuranPageTitleView()

        dataRetriever.retrieve { [weak self] (data: [QuranPage]) in
            self?.pageDataSource.items = data
            self?.collectionView?.reloadData()
            self?.scrollToFirstPage()
        }

        audioViewPresenter.onViewDidLoad()

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

    private func updateTitle(sura: String, pageNumber: Int) {
        let pageDescriptionFormat = NSLocalizedString("page_description", tableName: "Android", comment: "")
        let pageDescription = String.localizedStringWithFormat(pageDescriptionFormat, pageNumber, Juz.juzFromPage(pageNumber).juzNumber)
        titleView?.titleLabel.text = sura
        titleView?.detailsLabel.text = pageDescription
        titleView?.sizeToFit()
        navigationController?.navigationBar.setNeedsLayout()
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
        barsTimer?.cancel()
        barsTimer = nil
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
        // increate the timer duration to give existing users the time to rel
        barsTimer = Timer(interval: 5) { [weak self] in
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
        updateTitle(sura: Quran.nameForSura(page.startAyah.sura), pageNumber: page.pageNumber)

        DispatchQueue.bookmarks
            .promise { (self.bookmarksPersistence.isPageBookmarked(page.pageNumber), page.pageNumber) }
            .then(on: .main) { (bookmarked, page) -> Void in
                guard page == self.currentPage()?.pageNumber else { return }
                self.isBookmarked = bookmarked
                self.updateRightBarItems(animated: false)
            }.cauterize(tag: "bookmarksPersistence.isPageBookmarked")

        // only persist if active
        if UIApplication.shared.applicationState == .active {
            Crash.setValue(page.pageNumber, forKey: .QuranPage)
            lastPageUpdater.updateTo(page: page.pageNumber)
        }
    }

    private func updateRightBarItems(animated: Bool) {
        let bookmarkImage = isBookmarked ? #imageLiteral(resourceName: "bookmark-filled") : #imageLiteral(resourceName: "bookmark-empty")
        let bookmark = UIBarButtonItem(image: bookmarkImage, style: .plain, target: self, action: #selector(bookmarkButtonTapped))
        if isBookmarked {
            bookmark.tintColor = .bookmark()
        }

        let translationImage = isTranslationView ? #imageLiteral(resourceName: "globe_filled-25") : #imageLiteral(resourceName: "globe-25")
        let translation = UIBarButtonItem(image: translationImage, style: .plain, target: self, action: #selector(translationButtonTapped))

        var barItems = [translation, bookmark]
        if isTranslationView {
            let translationsSelection = UIBarButtonItem(image: #imageLiteral(resourceName: "Checklist_25"),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(selectTranslationsButtonTapped))
            barItems.insert(translationsSelection, at: 0)
        }

        navigationItem.setRightBarButtonItems(barItems, animated: animated)
    }

    @objc private func bookmarkButtonTapped() {
        guard let page = currentPage() else { return }
        isBookmarked = !isBookmarked
        self.updateRightBarItems(animated: false)

        if isBookmarked {
            Queue.background.async { try? self.bookmarksPersistence.removePageBookmark(atPage: page.pageNumber) }
        } else {
            Queue.background.async { try? self.bookmarksPersistence.insertPageBookmark(forPage: page.pageNumber) }
        }
    }

    @objc private func translationButtonTapped() {
        isTranslationView = !isTranslationView
        self.updateRightBarItems(animated: true)
    }

    @objc private func selectTranslationsButtonTapped() {

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

    func onErrorOccurred(error: Error) {
        showErrorAlert(error: error)
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
