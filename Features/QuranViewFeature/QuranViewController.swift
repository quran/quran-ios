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

import Combine
import Localization
import NoorUI
import QuranKit
import QuranTextKit
import SwiftUI
import Timing
import UIKit
import UIx
import VLogging

class QuranViewController: BaseViewController, QuranViewDelegate,
    QuranPresentable, PopoverPresenterDelegate, ForcedNavigationBarVisibilityController
{
    // MARK: Lifecycle

    init(interactor: QuranInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
        interactor.presenter = self
        interactor.start()
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let interactor: QuranInteractor

    var pagesView: UIView { quranView!.contentView! }

    // MARK: - View hierarchy

    var navigationBarHidden: Bool { true }

    override var prefersHomeIndicatorAutoHidden: Bool {
        prefersStatusBarHidden
    }

    override var prefersStatusBarHidden: Bool {
        // hide if it is compact size or status bar is shown
        statusBarHidden || traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact))
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    override func loadView() {
        view = QuranView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .readingBackground
        quranView?.navigationItem.largeTitleDisplayMode = .never
        quranView?.delegate = self

        // set the custom title view
        quranView?.navigationItem.titleView = TwoLineNavigationTitleView(
            firstLineFont: .boldSystemFont(ofSize: 15),
            secondLineFont: .systemFont(ofSize: 15, weight: .light)
        )

        let backImage: UIImage?
        backImage = UIImage(systemName: "chevron.backward")

        quranView?.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: backImage,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        setupContentStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Content Status

    func setupContentStatus() {
        interactor.$contentStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateContentStatus($0) }
            .store(in: &cancellables)
    }

    func hideBars() {
        setBarsHidden(true)
    }

    func startHiddenBarsTimer() {
        // increate the timer duration to give existing users the time to see the new buttons
        barsTimer = Timer(interval: 5) { [weak self] in
            if self?.presentedViewController == nil {
                self?.setBarsHidden(true)
            }
        }
    }

    // MARK: - Quran View Delegate

    func onQuranViewTapped(_ quranView: QuranView) {
        if interactor.contentStatus == nil && quranView.contentView != nil {
            setBarsHidden(!statusBarHidden)
        }
    }

    // MARK: - View Controllable

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint, completion: @escaping () -> Void) {
        let activityViewController = UIActivityViewController(activityItems: lines, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            completion()
        }
        if let sharePresentationController = activityViewController.popoverPresentationController {
            sharePresentationController.sourceView = sourceView
            sharePresentationController.sourceRect = CGRect(x: point.x, y: point.y, width: 1, height: 1)
        }
        present(activityViewController, animated: true, completion: nil)
    }

    func presentWordPointer(_ viewController: UIViewController) {
        addChild(viewController)
        quranView?.addWordPointerView(viewController.view)
        viewController.didMove(toParent: self)
    }

    func dismissWordPointer(_ viewController: UIViewController) {
        removeChild(viewController)
    }

    func presentMoreMenu(_ viewController: UIViewController) {
        presentPopover(viewController, pointingTo: quranView!.navigationItem.rightBarButtonItems!.first!)
    }

    func presentTranslationsSelection(_ viewController: UIViewController) {
        let translationsNavigationController = TranslationsSelectionNavigationController(rootViewController: viewController)
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "x.circle"),
            style: .done,
            target: self,
            action: #selector(onTranslationsSelectionDoneTapped)
        )
        present(translationsNavigationController, animated: true, completion: nil)
    }

    func presentAudioBanner(_ audioBanner: UIViewController) {
        addChild(audioBanner)
        quranView?.addAudioBannerView(audioBanner.view)
        audioBanner.didMove(toParent: self)
        setAudioBarHidden(false)
    }

    func presentAyahMenu(_ viewController: UIViewController, in sourceView: UIView, at point: CGPoint) {
        popoverPresenter.present(
            presenting: self,
            presented: viewController,
            pointingTo: sourceView,
            at: CGRect(x: point.x, y: point.y, width: 1, height: 1),
            permittedArrowDirections: []
        )
    }

    func presentQuranContent(_ viewController: UIViewController) {
        addContent(viewController)
    }

    func presentTranslatedVerse(_ viewController: UIViewController, didDismiss: @escaping () -> Void) {
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        if let navigationController = viewController as? UINavigationController {
            navigationController.visibleViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(dismissTranslatedVerse)
            )
        }
        presentationsMonitor.monitor(viewController, actions: .init(didDismiss: { _ in
            didDismiss()
        }))
        present(viewController, animated: true)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if let presentedViewController {
            presentationsMonitor.dismiss(presentedViewController)
        }
        super.dismiss(animated: flag, completion: completion)
    }

    func dismissPresentedViewController(completion: (() -> Void)?) {
        dismiss(animated: true, completion: completion)
    }

    func didDismissPopover() {
        interactor.didDismissPopover()
    }

    func setVisiblePages(_ pages: [Page]) {
        title = pages.map { $0.startSura.localizedName(withPrefix: true) }.joined(separator: " | ")
        updateTitle(pages)
    }

    func updateBookmark(_ isBookmarked: Bool) {
        updateRightBarItems(animated: false, isBookmarked: isBookmarked)
    }

    // MARK: Private

    private class TranslationsSelectionNavigationController: BaseNavigationController {}

    private var contentStatusView: UIHostingController<ContentStatusView>?

    private var cancellables: Set<AnyCancellable> = []
    private lazy var popoverPresenter = PhonePopoverPresenter(delegate: self)
    private let presentationsMonitor = PresentationsMonitor()

    // MARK: - Navigation bars

    private var barsTimer: Timing.Timer?

    // MARK: - Navigation Bar

    private lazy var moreNavigationButton: UIBarButtonItem = {
        let moreImage = UIImage.symbol("ellipsis.circle")
        return UIBarButtonItem(image: moreImage, style: .plain, target: self, action: #selector(onMoreBarButtonTapped(_:)))
    }()

    private var titleView: TwoLineNavigationTitleView? { quranView?.navigationItem.titleView as? TwoLineNavigationTitleView }
    private var quranView: QuranView? {
        view as? QuranView
    }

    private var statusBarHidden = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    private func stopBarHiddenTimer() {
        barsTimer?.cancel()
        barsTimer = nil
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func updateContentStatus(_ newStatus: ContentStatusView.State?) {
        if let newStatus {
            if let contentStatusView {
                contentStatusView.rootView = ContentStatusView(state: newStatus)
            } else {
                let contentStatusView = UIHostingController(rootView: ContentStatusView(state: newStatus))
                self.contentStatusView = contentStatusView
                addContent(contentStatusView)
            }
        } else {
            if let contentStatusView {
                removeChild(contentStatusView)
            }
        }
    }

    private func setBarsHidden(_ hidden: Bool) {
        // remove the timer
        stopBarHiddenTimer()

        // make it visible
        if quranView?.navigationBar.isHidden ?? true, !hidden {
            quranView?.navigationBar.isHidden = false
        }

        // animate the change
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, animations: {
            self.statusBarHidden = hidden
            self.setAudioBarHidden(hidden)
            self.quranView?.navigationBar.alpha = hidden ? 0 : 1
        }, completion: { _ in
            self.quranView?.navigationBar.isHidden = hidden
        })
    }

    private func setAudioBarHidden(_ hidden: Bool) {
        quranView?.setBarsHidden(hidden)
    }

    private func addContent(_ viewController: UIViewController) {
        addChild(viewController)
        quranView?.addContentView(viewController.view)
        viewController.didMove(toParent: self)
    }

    @objc
    private func dismissTranslatedVerse() {
        dismiss(animated: true)
    }

    @objc
    private func onTranslationsSelectionDoneTapped() {
        logger.info("Quran: translations selection dismissed")
        dismiss(animated: true)
    }

    private func updateTitle(_ pages: [Page]) {
        if pages.isEmpty {
            titleView?.firstLine = ""
            titleView?.secondLine = ""
            return
        }
        let suras = pages.map(\.startSura)
        let juzs = pages.map(\.startJuz)
        let pageNumbers = pages.map(\.pageNumber).map(NumberFormatter.shared.format).joined(separator: " - ")
        let pageDescription = lFormat(
            "page_description",
            table: .android,
            pageNumbers,
            NumberFormatter.shared.format(juzs.min()!.juzNumber)
        )
        titleView?.firstLine = suras.min()!.localizedName(withPrefix: true)
        titleView?.secondLine = pageDescription
    }

    private func updateRightBarItems(animated: Bool, isBookmarked: Bool) {
        let bookmarkImage = UIImage.symbol(isBookmarked ? "bookmark.fill" : "bookmark")
        let bookmark = UIBarButtonItem(image: bookmarkImage, style: .plain, target: self, action: #selector(onBookmarkButtonTapped))
        if isBookmarked {
            bookmark.tintColor = .systemRed
        }

        quranView?.navigationItem.setRightBarButtonItems([moreNavigationButton, bookmark], animated: animated)
    }

    @objc
    private func onBookmarkButtonTapped() {
        Task {
            await interactor.toogleBookmark()
        }
    }

    @objc
    private func onMoreBarButtonTapped(_ barButton: UIBarButtonItem) {
        interactor.onMoreBarButtonTapped()
    }
}
