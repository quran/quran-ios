//
//  QuranViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import KVOController
import QueuePlayer
import RIBs
import UIKit

protocol QuranPresentableListener: class {
    func onAdvancedAudioOptionsButtonTapped()
    func onWordPointerTapped()
    func onMoreBarButtonTapped()
    func onQariListButtonTapped()
}

class QuranViewController: BaseViewController, AudioBannerViewPresenterDelegate,
                        QuranDataSourceDelegate, QuranViewDelegate, QuranNavigationBarDelegate,
                        QuranViewControllable, QuranPresentable {

    var verseRuns: Runs { return audioViewPresenter.verseRuns }
    var listRuns: Runs { return audioViewPresenter.listRuns }
    var audioRange: VerseRange? { return audioViewPresenter.audioRange }
    var isWordPointerActive: Bool { return quranNavigationBar.isWordPointerActive }

    weak var listener: QuranPresentableListener?

    private lazy var popoverPresenter = PopoverPresenter()
    private lazy var qariListPresenter = QariListPresenter()

    private let wordByWordPersistence: WordByWordTranslationPersistence
    private let bookmarksPersistence: BookmarksPersistence
    private let bookmarksManager: BookmarksManager
    private let quranNavigationBar: QuranNavigationBar

    private let verseTextRetrieval: AnyInteractor<QuranShareData, [String]>
    private let pagesRetriever: QuranPagesDataRetrieverType
    private let audioViewPresenter: AudioBannerViewPresenter
    private let translationsSelectionControllerCreator: AnyGetCreator<UIViewController>
    private var simplePersistence: SimplePersistence
    private var lastPageUpdater: LastPageUpdater

    private let dataSource: QuranDataSource

    private let scrollToPageToken = Once()
    private let didLayoutSubviewToken = Once()
    private let interactiveGestureToken = Once()

    private let highlightedSearchAyah: AyahNumber?

    private var titleView: QuranPageTitleView? { return navigationItem.titleView as? QuranPageTitleView }

    private var quranView: QuranView? {
        return view as? QuranView
    }

    private var barsTimer: VFoundation.Timer?

    private var interactivePopGestureOldEnabled: Bool = true
    private var barsHiddenTimerExecuted = false

    override var screen: Analytics.Screen {
        return isTranslationView ? .quranArabic : .quranTranslation
    }

    private var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    private var initialPage: Int = 0 {
        didSet {
            title = Quran.nameForSura(Quran.PageSuraStart[initialPage - 1], withPrefix: true)
            titleView?.setPageNumber(initialPage, navigationBar: navigationController?.navigationBar)
        }
    }

    private var isTranslationView: Bool {
        set { simplePersistence.setValue(newValue, forKey: .showQuranTranslationView) }
        get { return simplePersistence.valueForKey(.showQuranTranslationView) }
    }

    var isBookmarked: Bool {
        return bookmarksManager.isBookmarked
    }

    var lastViewedPage: Int {
        return lastPageUpdater.lastPage?.page ?? initialPage
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

    init(imageService                           : AnyCacheableService<Int, QuranUIImage>,
         pageService                            : AnyCacheableService<Int, TranslationPage>,
         pagesRetriever                         : QuranPagesDataRetrieverType,
         ayahInfoRetriever                      : AyahInfoRetriever,
         audioViewPresenter                     : AudioBannerViewPresenter,
         translationsSelectionControllerCreator : AnyGetCreator<UIViewController>,
         bookmarksPersistence                   : BookmarksPersistence,
         lastPagesPersistence                   : LastPagesPersistence,
         simplePersistence                      : SimplePersistence,
         verseTextRetrieval                     : AnyInteractor<QuranShareData, [String]>,
         wordByWordPersistence                  : WordByWordTranslationPersistence,
         page                                   : Int,
         lastPage                               : LastPage?,
         highlightedSearchAyah                  : AyahNumber?) {
        self.initialPage                            = page
        self.pagesRetriever                         = pagesRetriever
        self.lastPageUpdater                        = LastPageUpdater(persistence: lastPagesPersistence)
        self.bookmarksManager                       = BookmarksManager(bookmarksPersistence: bookmarksPersistence)
        self.simplePersistence                      = simplePersistence
        self.audioViewPresenter                     = audioViewPresenter
        self.translationsSelectionControllerCreator = translationsSelectionControllerCreator
        self.quranNavigationBar                     = QuranNavigationBar(simplePersistence: simplePersistence)
        self.bookmarksPersistence                   = bookmarksPersistence
        self.verseTextRetrieval                     = verseTextRetrieval
        self.highlightedSearchAyah                  = highlightedSearchAyah
        self.wordByWordPersistence                  = wordByWordPersistence

        let imagesDataSource = QuranImagesDataSource(
            imageService: imageService,
            ayahInfoRetriever: ayahInfoRetriever,
            bookmarkPersistence: bookmarksPersistence)

        let translationsDataSource = QuranTranslationsDataSource(
            pageService: pageService,
            ayahInfoRetriever: ayahInfoRetriever,
            bookmarkPersistence: bookmarksPersistence)

        let dataSources = [imagesDataSource.asBasicDataSourceRepresentable(), translationsDataSource.asBasicDataSourceRepresentable()]
        let handlers: [QuranDataSourceHandler] = [imagesDataSource, translationsDataSource]
        dataSource = QuranDataSource(dataSources: dataSources, handlers: handlers)

        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true

        self.lastPageUpdater.configure(initialPage: page, lastPage: lastPage)

        audioViewPresenter.delegate = self
        imagesDataSource.delegate = self

        automaticallyAdjustsScrollViewInsets = false

        // page behavior
        let pageBehavior = ScrollViewPageBehavior()
        dataSource.scrollViewDelegate = pageBehavior
        kvoController.observe(pageBehavior, keyPath: #keyPath(ScrollViewPageBehavior.currentPage), options: .new) {  [weak self] (_, _, _) in
            self?.onPageChanged()
        }
        pageBehavior.onScrollViewWillBeginDragging = { [weak self] in
            self?.setBarsHidden(true)
        }

        dataSource.onScrollViewWillBeginDragging = { [weak self] in
            self?.setBarsHidden(true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func loadView() {
        view = QuranView(bookmarksPersistence: bookmarksPersistence,
                         verseTextRetrieval: verseTextRetrieval,
                         wordByWordPersistence: wordByWordPersistence,
                         simplePersistence: simplePersistence)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        kind = .backgroundOLED
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        updateSafeAreaInsets(hidden: navigationController?.isNavigationBarHidden == true)
        quranView?.delegate = self
        quranNavigationBar.delegate = self

        configureAudioView()
        quranView?.collectionView.ds_useDataSource(dataSource)

        // set the custom title view
        navigationItem.titleView = QuranPageTitleView()

        pagesRetriever.getPages()
            .done(on: .main) { [weak self] items -> Void in
                self?.dataSource.setItems(items)
                self?.scrollToFirstPage()
            }

        audioViewPresenter.onViewDidLoad()
    }

    private func configureAudioView() {
        quranView?.audioView.onTouchesBegan = { [weak self] in
            self?.stopBarHiddenTimer()
        }
        audioViewPresenter.view = quranView?.audioView
        quranView?.audioView.delegate = audioViewPresenter
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
        interactiveGestureToken.once {
            interactivePopGestureOldEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled ?? interactivePopGestureOldEnabled
        }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        // start hiding bars timer
        if !barsHiddenTimerExecuted {
            startHiddenBarsTimer()
        }

        // reload when coming from translation
        if presentedViewController is TranslationsSelectionNavigationController {
            dataSource.invalidate()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = interactivePopGestureOldEnabled
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didLayoutSubviewToken.once {}
        scrollToFirstPage()
    }

    fileprivate func scrollToFirstPage() {
        let currentIndex = dataSource.selectedBasicDataSource.items.index(where: { $0.pageNumber == initialPage })
        guard let index = currentIndex, didLayoutSubviewToken.executed else {
            return
        }

        scrollToPageToken.once {
            let indexPath = IndexPath(item: index, section: 0)
            scrollToIndexPath(indexPath, animated: false)
            onPageChangedToPage(dataSource.selectedBasicDataSource.item(at: indexPath))

            if let highlightedSearchAyah = highlightedSearchAyah {
                dataSource.highlightSearchAyaht([highlightedSearchAyah])
            }
        }
    }

    func stopBarHiddenTimer() {
        barsTimer?.cancel()
        barsTimer = nil
    }

    // MARK: - Quran View Delegate

    func onQuranViewTapped(_ quranView: QuranView) {
        setBarsHidden(navigationController?.isNavigationBarHidden == false)
    }

    func quranViewHideBars() {
        setBarsHidden(true)
    }

    func quranView(_ quranView: QuranView, didSelectTextLinesToShare textLines: [String], sourceView: UIView, sourceRect: CGRect) {
        ShareController.share(textLines: textLines, sourceView: sourceView, sourceRect: sourceRect, sourceViewController: self, handler: nil)
    }

    func onWordPointerTapped() {
        listener?.onWordPointerTapped()
    }

    func presentTranslationTextTypeSelectionViewController(_ viewController: ViewControllable) {
        popoverPresenter.present(presenting: self,
                                 presented: viewController.uiviewController,
                                 pointingTo: unwrap(quranView).pointer,
                                 at: quranView?.pointer.bounds ?? .zero,
                                 permittedArrowDirections: [.left, .right])
    }

    func presentMoreMenuViewController(_ viewController: ViewControllable) {
        popoverPresenter.present(presenting: self,
                                 presented: viewController.uiviewController,
                                 poiontingTo: unwrap(navigationItem.rightBarButtonItems?.first))
    }

    private func setBarsHidden(_ hidden: Bool) {
        // remove the timer
        barsHiddenTimerExecuted = true
        stopBarHiddenTimer()

        navigationController?.setNavigationBarHidden(hidden, animated: true)
        quranView?.setBarsHidden(hidden)

        // animate the change
        UIView.animate(withDuration: 0.3, animations: {
            self.updateSafeAreaInsets(hidden: hidden)

            self.statusBarHidden = hidden
            self.view.layoutIfNeeded()
        })
    }

    private func updateSafeAreaInsets(hidden: Bool) {
        if #available(iOS 11.0, *) {
            let navigationBarHeight = self.navigationController?.navigationBar.bounds.height ?? 0
            self.additionalSafeAreaInsets = UIEdgeInsets(top: hidden ? 0 : -navigationBarHeight, left: 0, bottom: 0, right: 0)
        }
    }

    fileprivate func startHiddenBarsTimer() {
        // increate the timer duration to give existing users the time to see the new buttons
        barsTimer = Timer(interval: 5) { [weak self] in
            if self?.presentedViewController == nil {
                self?.setBarsHidden(true)
            }
        }
    }

    fileprivate func scrollToIndexPath(_ indexPath: IndexPath, animated: Bool) {
        quranView?.collectionView.scrollToItem(at: indexPath,
                                               at: .centeredHorizontally,
                                               animated: false)
    }

    fileprivate func onPageChanged() {
        dataSource.highlightSearchAyaht([])
        guard let page = currentPage() else { return }
        onPageChangedToPage(page)
    }

    fileprivate func onPageChangedToPage(_ page: QuranPage) {
        updateBarToPage(page)
    }

    fileprivate func updateBarToPage(_ page: QuranPage) {
        // only apply if there is a change
        guard page.pageNumber != titleView?.pageNumber else {
            return
        }
        titleView?.setPageNumber(page.pageNumber, navigationBar: navigationController?.navigationBar)

        bookmarksManager.calculateIsBookmarked(pageNumber: page.pageNumber)
            .done(on: .main) { _ -> Void in
                guard page.pageNumber == self.currentPage()?.pageNumber else { return }
                self.quranNavigationBar.updateRightBarItems(animated: false)
            }.cauterize(tag: "bookmarksPersistence.isPageBookmarked")

        // only persist if active
        if UIApplication.shared.applicationState == .active {
            Crash.setValue(page.pageNumber, forKey: .QuranPage)
            updateLatestPageTo(page: page.pageNumber)
        }
    }

    private func updateLatestPageTo(page: Int) {
        Analytics.shared.showing(quranPage: page,
                                 isTranslation: isTranslationView,
                                 numberOfSelectedTranslations: simplePersistence.valueForKey(.selectedTranslations).count,
                                 fontSize: simplePersistence.fontSize,
                                 theme: simplePersistence.theme)
        lastPageUpdater.updateTo(page: page)
    }

    func onBookmarkButtonTapped() {
        guard let page = currentPage() else { return }

        bookmarksManager
            .toggleBookmarking(pageNumber: page.pageNumber)
            .cauterize(tag: "bookmarksPersistence.toggleBookmarking")
    }

    func onMoreButtonTapped(_ barButton: UIBarButtonItem) {
        listener?.onMoreBarButtonTapped()
    }

    func presentTranslationsSelection() {
        let controller = translationsSelectionControllerCreator.create(())
        present(controller, animated: true, completion: nil)
    }

    func showWordPointer() {
        quranNavigationBar.isWordPointerActive = true
        quranView?.showPointer()
    }

    func hideWordPointer() {
        quranNavigationBar.isWordPointerActive = false
        quranView?.hidePointer()
    }

    func reloadView() {
        dataSource.invalidate()
    }

    func setQuranMode(_ quranMode: QuranMode) {
        dataSource.selectedDataSourceIndex = quranMode == .arabic ? 0 : 1
    }

    func onQariListButtonTapped() {
        listener?.onQariListButtonTapped()
    }

    func presentQariList(_ viewController: ViewControllable) {
        qariListPresenter.present(presenting: self, presented: viewController.uiviewController, pointingTo: unwrap(quranView).audioView)
    }

    func updateSelectedQari() {
        audioViewPresenter.updateSelectedQari()
    }

    func onAdvancedAudioOptionsButtonTapped() {
        listener?.onAdvancedAudioOptionsButtonTapped()
    }

    func updateAudioOptions(to options: AdvancedAudioOptions) {
        guard let page = currentPage() else { return }
        audioViewPresenter.verseRuns = options.verseRuns
        audioViewPresenter.listRuns = options.listRuns
        audioViewPresenter.play(from: options.range.lowerBound, to: options.range.upperBound, page: page)
    }

    func play(from: AyahNumber) {
        guard let page = currentPage() else { return }
        audioViewPresenter.verseRuns = .one
        audioViewPresenter.listRuns = .one
        audioViewPresenter.play(from: from, to: nil, page: page)
    }

    func highlightAyah(_ ayah: AyahNumber) {
        var set = Set<AyahNumber>()
        set.insert(ayah)
        dataSource.highlightAyaht(set)

        // persist if not active
        guard UIApplication.shared.applicationState != .active else { return }
        DispatchQueue.global().async {
            let page = ayah.getStartPage()
            self.updateLatestPageTo(page: page)
            Crash.setValue(page, forKey: .QuranPage)
        }
    }

    func removeHighlighting() {
        dataSource.highlightAyaht(Set())
    }

    func currentPage() -> QuranPage? {
        return quranView?.visibleIndexPath().map { dataSource.selectedBasicDataSource.item(at: $0) }
    }

    func onErrorOccurred(error: Error) {
        showErrorAlert(error: error)
    }
}
