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

import UIKit
import KVOController

class QuranViewController: BaseViewController, AudioBannerViewPresenterDelegate,
                        QuranDataSourceDelegate, QuranViewDelegate, QuranNavigationBarDelegate {

    private let bookmarksPersistence: BookmarksPersistence
    private let bookmarksManager: BookmarksManager
    private let quranNavigationBar: QuranNavigationBar

    private let verseTextRetrieval: AnyInteractor<QuranShareData, String>
    private let dataRetriever: AnyDataRetriever<[QuranPage]>
    private let audioViewPresenter: AudioBannerViewPresenter
    private let qarisControllerCreator: AnyCreator<QariTableViewController, ([Qari], Int, UIView?)>
    private let translationsSelectionControllerCreator: AnyCreator<UIViewController, Void>
    private let simplePersistence: SimplePersistence
    private var lastPageUpdater: LastPageUpdater!

    private let dataSource: QuranDataSource

    private let scrollToPageToken = Once()
    private let didLayoutSubviewToken = Once()
    private let interactiveGestureToken = Once()

    private var titleView: QuranPageTitleView? { return navigationItem.titleView as? QuranPageTitleView }

    private var quranView: QuranView! {
        return view as? QuranView
    }

    private var barsTimer: Timer?

    private var interactivePopGestureOldEnabled: Bool?
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

    init(imageService                           : AnyCacheableService<Int, UIImage>, // swiftlint:disable:this function_parameter_count
         pageService                            : AnyCacheableService<Int, TranslationPage>,
         dataRetriever                          : AnyDataRetriever<[QuranPage]>,
         ayahInfoRetriever                      : AyahInfoRetriever,
         audioViewPresenter                     : AudioBannerViewPresenter,
         qarisControllerCreator                 : AnyCreator<QariTableViewController, ([Qari], Int, UIView?)>,
         translationsSelectionControllerCreator : AnyCreator<UIViewController, Void>,
         bookmarksPersistence                   : BookmarksPersistence,
         lastPagesPersistence                   : LastPagesPersistence,
         simplePersistence                      : SimplePersistence,
         verseTextRetrieval                     : AnyInteractor<QuranShareData, String>,
         page                                   : Int,
         lastPage                               : LastPage?) {
        self.initialPage                            = page
        self.dataRetriever                          = dataRetriever
        self.lastPageUpdater                        = LastPageUpdater(persistence: lastPagesPersistence)
        self.bookmarksManager                       = BookmarksManager(bookmarksPersistence: bookmarksPersistence)
        self.simplePersistence                      = simplePersistence
        self.audioViewPresenter                     = audioViewPresenter
        self.qarisControllerCreator                 = qarisControllerCreator
        self.translationsSelectionControllerCreator = translationsSelectionControllerCreator
        self.quranNavigationBar                     = QuranNavigationBar(simplePersistence: simplePersistence)
        self.bookmarksPersistence                   = bookmarksPersistence
        self.verseTextRetrieval                     = verseTextRetrieval

        let imagesDataSource = QuranImagesDataSource(
            imageService: imageService,
            ayahInfoRetriever: ayahInfoRetriever,
            bookmarkPersistence: bookmarksPersistence)

        let translationsDataSource = QuranTranslationsDataSource(
            pageService: pageService,
            ayahInfoRetriever: ayahInfoRetriever,
            bookmarkPersistence: bookmarksPersistence)

        let dataSources = [imagesDataSource.asBasicDataSourceRepresentable(), translationsDataSource.asBasicDataSourceRepresentable()]
        let handlers = [imagesDataSource.asAnyQuranDataSourceHandler(), translationsDataSource.asAnyQuranDataSourceHandler()]
        dataSource = QuranDataSource(dataSources: dataSources, handlers: handlers)

        super.init(nibName: nil, bundle: nil)

        updateTranslationView(initialization: true)

        self.lastPageUpdater.configure(initialPage: page, lastPage: lastPage)

        audioViewPresenter.delegate = self
        imagesDataSource.delegate = self

        automaticallyAdjustsScrollViewInsets = false

        // page behavior
        let pageBehavior = ScrollViewPageBehavior()
        dataSource.scrollViewDelegate = pageBehavior
        kvoController.observe(pageBehavior, keyPath: #keyPath(ScrollViewPageBehavior.currentPage), options: .new) { [weak self] (_, _, _) in
            self?.onPageChanged()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func loadView() {
        view = QuranView(bookmarksPersistence: bookmarksPersistence, verseTextRetrieval: verseTextRetrieval)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        quranView.delegate = self
        quranNavigationBar.delegate = self

        configureAudioView()
        quranView.collectionView.ds_useDataSource(dataSource)

        // set the custom title view
        navigationItem.titleView = QuranPageTitleView()

        dataRetriever.retrieve { [weak self] items in
            self?.dataSource.setItems(items)
            self?.scrollToFirstPage()
        }

        audioViewPresenter.onViewDidLoad()
    }

    private func configureAudioView() {
        quranView.audioView.onTouchesBegan = { [weak self] in
            self?.stopBarHiddenTimer()
        }
        audioViewPresenter.view = quranView.audioView
        quranView.audioView.delegate = audioViewPresenter
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        navigationController?.setNavigationBarHidden(false, animated: animated)
        interactiveGestureToken.once {
            interactivePopGestureOldEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled
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
        navigationController?.interactivePopGestureRecognizer?.isEnabled = interactivePopGestureOldEnabled ?? true
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

    func quranView(_ quranView: QuranView, didSelectTextToShare text: String, sourceView: UIView, sourceRect: CGRect) {
        ShareController.share(text: text, sourceView: sourceView, sourceRect: sourceRect, sourceViewController: self, handler: nil)
    }

    private func setBarsHidden(_ hidden: Bool) {
        // remove the timer
        barsHiddenTimerExecuted = true
        stopBarHiddenTimer()

        navigationController?.setNavigationBarHidden(hidden, animated: true)
        quranView.setBarsHidden(hidden)

        // animate the change
        UIView.animate(withDuration: 0.3, animations: {
            self.statusBarHidden = hidden
            self.view.layoutIfNeeded()
        })
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
        quranView.collectionView.scrollToItem(at: indexPath,
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
        // only apply if there is a change
        guard page.pageNumber != titleView?.pageNumber else {
            return
        }
        titleView?.setPageNumber(page.pageNumber, navigationBar: navigationController?.navigationBar)

        bookmarksManager.calculateIsBookmarked(pageNumber: page.pageNumber)
            .then(on: .main) { _ -> Void in
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
                                 numberOfSelectedTranslations: simplePersistence.valueForKey(.selectedTranslations).count)
        lastPageUpdater.updateTo(page: page)
    }

    func onBookmarkButtonTapped() {
        guard let page = currentPage() else { return }

        bookmarksManager
            .toggleBookmarking(pageNumber: page.pageNumber)
            .cauterize(tag: "bookmarksPersistence.toggleBookmarking")
    }

    func onTranslationButtonTapped() {
        updateTranslationView(initialization: false)
    }

    func onSelectTranslationsButtonTapped() {
        let controller = translationsSelectionControllerCreator.create()
        present(controller, animated: true, completion: nil)
    }

    func showQariListSelectionWithQari(_ qaris: [Qari], selectedIndex: Int) {
        let controller = qarisControllerCreator.create((qaris, selectedIndex, quranView.audioView))
        controller.onSelectedIndexChanged = { [weak self] index in
            self?.audioViewPresenter.setQariIndex(index)
        }
        present(controller, animated: true, completion: nil)
    }

    func highlightAyah(_ ayah: AyahNumber) {
        var set = Set<AyahNumber>()
        set.insert(ayah)
        dataSource.highlightAyaht(set)

        // persist if not active
        guard UIApplication.shared.applicationState != .active else { return }
        Queue.background.async {
            let page = ayah.getStartPage()
            self.updateLatestPageTo(page: page)
            Crash.setValue(page, forKey: .QuranPage)
        }
    }

    func removeHighlighting() {
        dataSource.highlightAyaht(Set())
    }

    func currentPage() -> QuranPage? {
        return quranView.visibleIndexPath().map { dataSource.selectedBasicDataSource.item(at: $0) }
    }

    func onErrorOccurred(error: Error) {
        showErrorAlert(error: error)
    }

    private func updateTranslationView(initialization: Bool) {
        let isTranslationView = quranNavigationBar.isTranslationView
        dataSource.selectedDataSourceIndex = isTranslationView ? 1 : 0
        let noTranslationsSelected = simplePersistence.valueForKey(.selectedTranslations).isEmpty
        if !initialization && isTranslationView && noTranslationsSelected {
            onSelectTranslationsButtonTapped()
        }
    }
}
