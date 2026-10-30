//
//  ContentTranslationReaderScrollTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-30.
//

import AnnotationsService
import Combine
import QuranKit
import QuranText
import QuranTextKit
import SwiftUI
import TranslationService
import XCTest
@testable import QuranTranslationFeature
@testable import UIx

@MainActor
final class ContentTranslationReaderScrollTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // The package test runner has no window scene to drive scroll animations.
        animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(animationsWereEnabled)
        super.tearDown()
    }

    func testReaderScrollForgetsTheItemSoReappearingDoesNotScrollBack() async {
        let service = VerseOverlayService()
        service.overlays.navigationTarget = verses[1]
        let sut = makeSUT(overlayService: service)
        sut.onAppear()
        await drainMainQueue()
        XCTAssertEqual(sut.scrollToItem?.ayah, verses[1])

        sut.onReaderScroll()
        XCTAssertNil(sut.scrollToItem)

        sut.onDisappear()
        sut.onAppear()
        await drainMainQueue()
        XCTAssertNil(sut.scrollToItem)
    }

    func testSameVerseRequestedAfterReaderScrollScrollsAgain() async {
        let service = VerseOverlayService()
        service.overlays.navigationTarget = verses[1]
        let sut = makeSUT(overlayService: service)
        sut.onAppear()
        await drainMainQueue()
        var scrolls: [AyahNumber?] = []
        let subscription = sut.$scrollToItem.dropFirst().sink { scrolls.append($0?.ayah) }
        defer { subscription.cancel() }

        sut.onReaderScroll()
        service.overlays.navigationTarget = verses[1]
        await drainMainQueue()

        XCTAssertEqual(scrolls, [nil, verses[1]])
        XCTAssertNil(service.overlays.navigationTarget)
    }

    func testNextPlayingVerseScrollsAfterReaderScrolledAway() async {
        let service = VerseOverlayService()
        service.overlays.playingVerses = [verses[0]]
        let sut = makeSUT(overlayService: service)
        sut.onAppear()
        await drainMainQueue()
        var scrolls: [AyahNumber?] = []
        let subscription = sut.$scrollToItem.dropFirst().sink { scrolls.append($0?.ayah) }
        defer { subscription.cancel() }

        sut.onReaderScroll()
        service.overlays.playingVerses = [verses[1]]
        await drainMainQueue()

        XCTAssertEqual(scrolls, [nil, verses[1]])
    }

    func testListKeepsTheReaderPositionWhenResizedAfterTheyScroll() async throws {
        let list = try hostList()
        defer { list.window.isHidden = true }
        await waitUntilScrolled(list)

        // XCTest can't drive the list's pan gesture, so run what its `.began` runs.
        try XCTUnwrap(list.window.findSubview(ofType: ScrollDragObserverView.self)).action()
        scrollToTop(list.scrollView)
        resize(list.window, to: CGSize(width: 420, height: 460))
        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNil(list.viewModel.scrollToItem)
        XCTAssertEqual(list.scrollView.contentOffset.y, -list.scrollView.adjustedContentInset.top, accuracy: 1)
    }

    func testListKeepsTheVerseInViewWhenResizedBeforeTheReaderScrolls() async throws {
        let list = try hostList()
        defer { list.window.isHidden = true }
        await waitUntilScrolled(list)

        scrollToTop(list.scrollView)
        resize(list.window, to: CGSize(width: 420, height: 460))

        await waitUntilScrolled(list)
    }

    // MARK: Private

    private struct HostedList {
        let window: UIWindow
        let scrollView: UIScrollView
        let viewModel: ContentTranslationViewModel
    }

    private var animationsWereEnabled = true
    private let verses = Array(Quran.hafsMadani1405.pages[2].verses.prefix(3))

    /// A view model showing `verses` with one translation.
    private func makeSUT(overlayService: VerseOverlayService) -> ContentTranslationViewModel {
        let viewModel = makeContentTranslationViewModel(overlayService: overlayService)
        viewModel.verses = verses
        viewModel.commitLoadedContent(
            verses: verses,
            translations: [makeTranslation(id: 1)],
            verseTexts: Dictionary(uniqueKeysWithValues: verses.map { ($0, makeVerseText(translationCount: 1)) })
        )
        return viewModel
    }

    /// Hosts a page's translation, long enough to scroll, with its last verse as the navigation target.
    private func hostList() throws -> HostedList {
        let pageVerses = Quran.hafsMadani1405.pages[2].verses
        let service = VerseOverlayService()
        service.overlays.navigationTarget = pageVerses.last
        let viewModel = makeSUT(overlayService: service)
        let longText = String(repeating: "A long translation line that wraps. ", count: 12)
        viewModel.verses = pageVerses
        viewModel.commitLoadedContent(
            verses: pageVerses,
            translations: [makeTranslation(id: 1)],
            verseTexts: Dictionary(uniqueKeysWithValues: pageVerses.map { verse in
                (verse, makeVerseText(translationCount: 1) { _ in longText })
            })
        )
        #if QURAN_SYNC
        let view = ContentTranslationView(viewModel: viewModel, onAyahNumberTapped: nil)
        #else
        let view = ContentTranslationView(viewModel: viewModel)
        #endif
        let controller = UIHostingController(rootView: view.ignoresSafeArea())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        let scrollView = try XCTUnwrap(window.findSubview(ofType: UICollectionView.self) ?? window.findSubview(ofType: UITableView.self))
        return HostedList(window: window, scrollView: scrollView, viewModel: viewModel)
    }

    private func waitUntilScrolled(_ list: HostedList) async {
        let scrollView = list.scrollView
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                MainActor.assumeIsolated {
                    scrollView.contentOffset.y > -scrollView.adjustedContentInset.top + 1
                }
            },
            object: nil
        )
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "List scrolls to the verse: offset=\(scrollView.contentOffset), content=\(scrollView.contentSize)")
    }

    private func scrollToTop(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.adjustedContentInset.top), animated: false)
    }

    private func resize(_ window: UIWindow, to size: CGSize) {
        window.frame = CGRect(origin: .zero, size: size)
        window.layoutIfNeeded()
    }
}
