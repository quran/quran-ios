import AnnotationsService
import Combine
import ImageService
import QuranKit
import ReadingService
import TestResources
import XCTest
@testable import QuranImageFeature

@MainActor
final class ContentNavigationTargetTests: XCTestCase {
    override func setUp() {
        super.setUp()
        previousReading = ReadingPreferences.shared.reading
        ReadingPreferences.shared.reading = reading
    }

    override func tearDown() {
        ReadingPreferences.shared.reading = previousReading
        super.tearDown()
    }

    func testPageImageScrollsToTheNavigationTargetOnceLoadedThenConsumesIt() async throws {
        let target = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 114, ayah: 1))
        let service = VerseOverlayService()
        let model = makeModel(overlayService: service)
        model.onAppear()
        var scrolls: [AyahNumber?] = []
        let subscription = model.$scrollToVerse.dropFirst().sink { scrolls.append($0) }
        defer { subscription.cancel() }

        service.overlays.navigationTarget = target
        await drainMainQueue()

        XCTAssertEqual(scrolls, [])
        XCTAssertEqual(service.overlays.navigationTarget, target)

        await model.loadImagePage()
        await drainMainQueue()

        XCTAssertEqual(scrolls, [target])
        XCTAssertNil(service.overlays.navigationTarget)
    }

    func testConsumedNavigationTargetDoesNotScrollBackWhenPlaybackStops() async throws {
        let target = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 114, ayah: 1))
        let playing = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 113, ayah: 1))
        let service = VerseOverlayService()
        service.overlays.navigationTarget = target
        let model = makeModel(overlayService: service)
        model.onAppear()
        await model.loadImagePage()
        await drainMainQueue()
        var scrolls: [AyahNumber?] = []
        let subscription = model.$scrollToVerse.dropFirst().sink { scrolls.append($0) }
        defer { subscription.cancel() }

        service.overlays.playingVerses = [playing]
        await drainMainQueue()
        service.overlays.playingVerses = []
        await drainMainQueue()

        XCTAssertEqual(scrolls, [playing])
    }

    func testNavigationTargetOnAnotherPageIsLeftForThatPage() async {
        let target = reading.quran.pages[602].firstVerse
        let service = VerseOverlayService()
        service.overlays.navigationTarget = target
        let model = makeModel(overlayService: service)
        model.onAppear()

        await model.loadImagePage()
        await drainMainQueue()

        XCTAssertEqual(service.overlays.navigationTarget, target)
    }

    func testDisappearedPageImageDoesNotConsumeAPendingNavigationTarget() async throws {
        let target = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 114, ayah: 1))
        let service = VerseOverlayService()
        let model = makeModel(overlayService: service)
        model.onAppear()
        await model.loadImagePage()
        await drainMainQueue()

        service.overlays.navigationTarget = target
        model.onDisappear()
        await drainMainQueue()

        XCTAssertNil(model.scrollToVerse)
        XCTAssertEqual(service.overlays.navigationTarget, target)

        model.onAppear()
        await drainMainQueue()

        XCTAssertEqual(model.scrollToVerse, target)
        XCTAssertNil(service.overlays.navigationTarget)
    }

    func testLinePageConsumesOnlyItsOwnPagesNavigationTarget() async throws {
        let reading = Reading.hafs_1441
        let metrics = try XCTUnwrap(reading.linePageMetrics)
        let root = try makeLinePageFiles(metrics: metrics)
        defer { try? FileManager.default.removeItem(at: root) }
        let page = reading.quran.pages[0]
        let otherPageTarget = reading.quran.pages[1].firstVerse
        let service = VerseOverlayService()
        service.overlays.navigationTarget = otherPageTarget
        let model = ContentLineViewModel(
            reading: reading,
            page: page,
            linePageAssetService: LinePageAssetService(
                readingDirectory: root, metrics: metrics, quran: reading.quran, ayahMarkerURL: nil
            ),
            overlayService: service
        )
        model.onAppear()

        await model.loadLinePage()
        await drainMainQueue()

        XCTAssertFalse(model.geometryData.highlightSpans.isEmpty)
        XCTAssertEqual(service.overlays.navigationTarget, otherPageTarget)

        let target = page.verses[3]
        service.overlays.navigationTarget = target
        await drainMainQueue()

        XCTAssertEqual(model.scrollToVerse, target)
        XCTAssertNil(service.overlays.navigationTarget)
    }

    func testReaderScrollForgetsTheVerseSoReappearingDoesNotScrollBack() async throws {
        let target = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 114, ayah: 1))
        let service = VerseOverlayService()
        service.overlays.navigationTarget = target
        let model = makeModel(overlayService: service)
        model.onAppear()
        await model.loadImagePage()
        await drainMainQueue()
        XCTAssertEqual(model.scrollToVerse, target)

        model.onReaderScroll()
        XCTAssertNil(model.scrollToVerse)

        model.onDisappear()
        model.onAppear()
        await drainMainQueue()
        XCTAssertNil(model.scrollToVerse)
    }

    func testSameVerseRequestedAfterReaderScrollScrollsAgain() async throws {
        let target = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 114, ayah: 1))
        let service = VerseOverlayService()
        service.overlays.navigationTarget = target
        let model = makeModel(overlayService: service)
        model.onAppear()
        await model.loadImagePage()
        await drainMainQueue()
        var scrolls: [AyahNumber?] = []
        let subscription = model.$scrollToVerse.dropFirst().sink { scrolls.append($0) }
        defer { subscription.cancel() }

        model.onReaderScroll()
        service.overlays.navigationTarget = target
        await drainMainQueue()

        XCTAssertEqual(scrolls, [nil, target])
        XCTAssertNil(service.overlays.navigationTarget)
    }

    func testNextPlayingVerseScrollsAfterReaderScrolledAway() async throws {
        let first = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 113, ayah: 1))
        let second = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 113, ayah: 2))
        let service = VerseOverlayService()
        let model = makeModel(overlayService: service)
        model.onAppear()
        await model.loadImagePage()
        service.overlays.playingVerses = [first]
        await drainMainQueue()
        var scrolls: [AyahNumber?] = []
        let subscription = model.$scrollToVerse.dropFirst().sink { scrolls.append($0) }
        defer { subscription.cancel() }

        model.onReaderScroll()
        service.overlays.playingVerses = [second]
        await drainMainQueue()

        XCTAssertEqual(scrolls, [nil, second])
    }

    func testLinePageReaderScrollForgetsTheVerseUntilTheNextRequest() async throws {
        let reading = Reading.hafs_1441
        let metrics = try XCTUnwrap(reading.linePageMetrics)
        let root = try makeLinePageFiles(metrics: metrics)
        defer { try? FileManager.default.removeItem(at: root) }
        let page = reading.quran.pages[0]
        let target = page.verses[3]
        let service = VerseOverlayService()
        service.overlays.navigationTarget = target
        let model = ContentLineViewModel(
            reading: reading,
            page: page,
            linePageAssetService: LinePageAssetService(
                readingDirectory: root, metrics: metrics, quran: reading.quran, ayahMarkerURL: nil
            ),
            overlayService: service
        )
        model.onAppear()
        await model.loadLinePage()
        await drainMainQueue()
        XCTAssertEqual(model.scrollToVerse, target)

        model.onReaderScroll()
        model.onDisappear()
        model.onAppear()
        await drainMainQueue()
        XCTAssertNil(model.scrollToVerse)

        service.overlays.navigationTarget = target
        await drainMainQueue()
        XCTAssertEqual(model.scrollToVerse, target)
    }

    // MARK: Private

    private let reading = Reading.hafs_1405
    private var previousReading = Reading.hafs_1405

    private func makeModel(overlayService: VerseOverlayService) -> ContentImageViewModel {
        ContentImageViewModel(
            reading: reading,
            page: reading.quran.pages[603],
            imageDataService: ImageDataService(
                ayahInfoDatabase: TestResources.resourceURL("hafs_1405_ayahinfo.db"),
                imagesURL: TestResources.testDataURL.appendingPathComponent("images"),
                ayahMarkerURL: nil
            ),
            overlayService: overlayService
        )
    }

    /// Runs the view model's scrolls, which it defers to the next main-queue turn.
    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
