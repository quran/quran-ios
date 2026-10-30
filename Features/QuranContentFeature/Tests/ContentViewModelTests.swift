import AnalyticsFake
import AnnotationsService
import CombineSchedulers
import QuranAnnotations
import QuranImageFeature
import QuranKit
import QuranText
import QuranTextKit
import UIKit
import XCTest
@testable import QuranContentFeature
@testable import QuranTranslationFeature
#if QURAN_SYNC
import MobileSyncTestSupport
#endif

@MainActor
final class ContentViewModelTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        #if QURAN_SYNC
        try await MobileSyncTestDatabase.shared.reset()
        #endif
        previousQuranMode = QuranContentStatePreferences.shared.quranMode
        QuranContentStatePreferences.shared.quranMode = .arabic
    }

    override func tearDown() async throws {
        QuranContentStatePreferences.shared.quranMode = previousQuranMode
        #if QURAN_SYNC
        try await MobileSyncTestDatabase.shared.reset()
        #endif
        try await super.tearDown()
    }

    func testDismissingTheAyahMenuClearsTheSelectionAfterNavigating() {
        let sut = makeSUT()
        sut.onPageContentAppear(pagingStrategy: .singlePage)

        sut.onViewLongPressStarted(at: .zero, sourceView: UIView(), verse: verse(5))
        scheduler.advance()

        XCTAssertEqual(service.overlays.selectedVerses, [verse(5)])
        XCTAssertNil(service.overlays.navigationHighlight)

        sut.removeAyahMenuHighlight()
        scheduler.advance()

        XCTAssertEqual(service.overlays.selectedVerses, [])
        XCTAssertEqual(sut.overlays, service.overlays)
    }

    func testPlaybackOnAnotherPageCanStopAfterNavigating() {
        let playing = Quran.hafsMadani1405.pages[2].firstVerse
        let sut = makeSUT()

        sut.highlightReadingAyah(playing)
        scheduler.advance()

        XCTAssertEqual(sut.visiblePages, [playing.page])
        XCTAssertEqual(service.overlays.playingVerses, [playing])
        XCTAssertNil(service.overlays.navigationTarget)
        XCTAssertNil(service.overlays.navigationHighlight)

        sut.highlightReadingAyah(nil)
        scheduler.advance()

        XCTAssertEqual(service.overlays.playingVerses, [])
        XCTAssertEqual(sut.overlays, service.overlays)
    }

    func testHighlightFadesAfterContentScrollsToTheTarget() {
        let sut = makeSUT()

        service.consumeNavigationTarget(verse(1))
        scheduler.advance(by: .milliseconds(1500))

        XCTAssertNil(service.overlays.navigationHighlight)
        withExtendedLifetime(sut) { }
    }

    func testDragHidesTheNavigation() {
        let sut = makeSUT()

        sut.onUserWillBeginDragScroll()

        XCTAssertNil(service.overlays.navigationTarget)
        XCTAssertNil(service.overlays.navigationHighlight)
    }

    func testPageChangeClearsTheNavigation() {
        let sut = makeSUT()

        sut.visiblePages = [Quran.hafsMadani1405.pages[2]]

        XCTAssertNil(service.overlays.navigationTarget)
        XCTAssertNil(service.overlays.navigationHighlight)
    }

    func testModeChangeScrollsRebuiltContentToTheNavigatedVerse() {
        let sut = makeSUT()
        sut.onPageContentAppear(pagingStrategy: .singlePage)
        service.consumeNavigationTarget(verse(1))

        QuranContentStatePreferences.shared.quranMode = .translation
        sut.onPageContentAppear(pagingStrategy: .singlePage)

        XCTAssertEqual(service.overlays.navigationTarget, verse(1))
    }

    func testPaginationChangeScrollsRebuiltContentToTheNavigatedVerse() {
        let sut = makeSUT()
        sut.onPageContentAppear(pagingStrategy: .singlePage)
        service.consumeNavigationTarget(verse(1))

        sut.onPageContentAppear(pagingStrategy: .singlePage)

        XCTAssertNil(service.overlays.navigationTarget)

        sut.onPageContentAppear(pagingStrategy: .doublePage)

        XCTAssertEqual(service.overlays.navigationTarget, verse(1))
    }

    func testDragStopsRebuiltContentFromScrollingBack() {
        let sut = makeSUT()
        sut.onPageContentAppear(pagingStrategy: .singlePage)
        service.consumeNavigationTarget(verse(1))

        sut.onUserWillBeginDragScroll()
        QuranContentStatePreferences.shared.quranMode = .translation
        sut.onPageContentAppear(pagingStrategy: .singlePage)

        XCTAssertNil(service.overlays.navigationTarget)
    }

    func testPlaybackStopsRebuiltContentFromScrollingBack() {
        let sut = makeSUT()
        sut.onPageContentAppear(pagingStrategy: .singlePage)

        sut.highlightReadingAyah(verse(3))
        scheduler.advance()
        QuranContentStatePreferences.shared.quranMode = .translation
        sut.onPageContentAppear(pagingStrategy: .singlePage)
        sut.highlightReadingAyah(nil)
        scheduler.advance()

        XCTAssertNil(service.overlays.navigationTarget)
        XCTAssertNil(service.overlays.firstScrollingVerse())
    }

    func testModeChangeScrollsTheIncomingContentNotTheOutgoingContent() async {
        let sut = makeSUT()
        sut.onPageContentAppear(pagingStrategy: .singlePage)
        let outgoing = makeTranslationContent()
        outgoing.onAppear()
        await drainMainQueue()
        XCTAssertNil(service.overlays.navigationTarget)
        var outgoingScrolls: [AyahNumber?] = []
        let outgoingSubscription = outgoing.$scrollToItem.dropFirst().sink { outgoingScrolls.append($0?.ayah) }
        defer { outgoingSubscription.cancel() }

        // SwiftUI may show the incoming pages before it removes the outgoing ones.
        QuranContentStatePreferences.shared.quranMode = .translation
        sut.onPageContentAppear(pagingStrategy: .singlePage)
        outgoing.onDisappear()
        let incoming = makeTranslationContent()
        incoming.onAppear()
        await drainMainQueue()

        XCTAssertEqual(outgoingScrolls, [])
        XCTAssertEqual(incoming.scrollToItem?.ayah, verse(1))
        XCTAssertNil(service.overlays.navigationTarget)
    }

    // MARK: Private

    private let service = VerseOverlayService()
    private let scheduler = DispatchQueue.test
    private let container = AppDependenciesStub()
    private var previousQuranMode = QuranMode.arabic

    private func verse(_ ayah: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: ayah)!
    }

    /// Translation content for the navigated page, already loaded.
    private func makeTranslationContent() -> ContentTranslationViewModel {
        let unavailableURL = URL(fileURLWithPath: "/tmp/unavailable-quran-content-test")
        let viewModel = ContentTranslationViewModel(
            localTranslationsRetriever: .init(databasesURL: unavailableURL),
            dataService: .init(databasesURL: unavailableURL, quranFileURL: unavailableURL),
            overlayService: service
        )
        let verses = verse(1).page.verses
        viewModel.verses = verses
        viewModel.commitLoadedContent(
            verses: verses,
            translations: [],
            verseTexts: Dictionary(uniqueKeysWithValues: verses.map { verse in
                (verse, VerseText(arabicText: "Arabic", translations: [], arabicPrefix: [], arabicSuffix: []))
            })
        )
        return viewModel
    }

    /// Runs the content view models' scrolls, which they defer to the next main-queue turn.
    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    private func makeSUT() -> ContentViewModel {
        let deps = ContentViewModel.Deps(
            analytics: AnalyticsLibrarySpy(),
            lastPageUpdater: LastPageUpdater(service: container.lastPageService()),
            quran: .hafsMadani1405,
            overlayService: service,
            imageDataSourceBuilder: ContentImageBuilder(container: container, overlayService: service),
            translationDataSourceBuilder: ContentTranslationBuilder(container: container, overlayService: service)
        )
        let input = QuranInput(initialPage: verse(1).page, lastPage: nil, navigationAyah: verse(1))
        return ContentViewModel(deps: deps, input: input, scheduler: scheduler.eraseToAnyScheduler())
    }
}
