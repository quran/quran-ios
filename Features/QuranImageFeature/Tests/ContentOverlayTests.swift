#if QURAN_SYNC
import AnnotationsService
import Combine
import ImageService
import QuranKit
import ReadingService
import TestResources
import XCTest
@testable import QuranImageFeature

@MainActor
final class ContentOverlayTests: XCTestCase {
    func test_imagePage_ignoresUnrelatedIndicatorsAndReceivesVisibilityChanges() {
        let reading = Reading.hafs_1405
        let page = reading.quran.pages[0]
        let other = reading.quran.pages[1].firstVerse
        let service = VerseOverlayService()
        service.overlays.indicatorsHidden = true
        let model = ContentImageViewModel(
            reading: reading,
            page: page,
            imageDataService: ImageDataService(
                ayahInfoDatabase: TestResources.resourceURL("hafs_1405_ayahinfo.db"),
                imagesURL: TestResources.testDataURL.appendingPathComponent("images"),
                ayahMarkerURL: nil
            ),
            overlayService: service
        )
        XCTAssertTrue(model.indicatorsHidden)
        var updates = 0
        let subscription = model.objectWillChange.sink { updates += 1 }
        defer { subscription.cancel() }

        service.overlays.notedVerses = [other]
        XCTAssertEqual(updates, 0)
        XCTAssertTrue(model.ayahIndicators.isEmpty)

        service.overlays.notedVerses.insert(page.firstVerse)
        XCTAssertEqual(updates, 1)
        XCTAssertEqual(model.ayahIndicators, [page.firstVerse: [.note]])

        service.overlays.indicatorsHidden = false
        XCTAssertFalse(model.indicatorsHidden)
        service.overlays.indicatorsHidden = true
        XCTAssertTrue(model.indicatorsHidden)
        XCTAssertEqual(model.ayahIndicators, [page.firstVerse: [.note]])
    }

    func test_linePage_ignoresUnrelatedIndicatorsAndReceivesVisibilityChanges() throws {
        let reading = Reading.hafs_1441
        let page = reading.quran.pages[0]
        let other = reading.quran.pages[1].firstVerse
        let service = VerseOverlayService()
        service.overlays.indicatorsHidden = true
        let model = ContentLineViewModel(
            reading: reading,
            page: page,
            linePageAssetService: LinePageAssetService(
                readingDirectory: TestResources.testDataURL,
                metrics: try XCTUnwrap(reading.linePageMetrics),
                quran: reading.quran,
                ayahMarkerURL: nil
            ),
            overlayService: service
        )
        XCTAssertTrue(model.indicatorsHidden)
        var updates = 0
        let subscription = model.objectWillChange.sink { updates += 1 }
        defer { subscription.cancel() }

        service.overlays.notedVerses = [other]
        XCTAssertEqual(updates, 0)
        XCTAssertTrue(model.ayahIndicators.isEmpty)

        service.overlays.notedVerses.insert(page.firstVerse)
        XCTAssertEqual(updates, 1)
        XCTAssertEqual(model.ayahIndicators, [page.firstVerse: [.note]])

        service.overlays.indicatorsHidden = false
        XCTAssertFalse(model.indicatorsHidden)
        service.overlays.indicatorsHidden = true
        XCTAssertTrue(model.indicatorsHidden)
        XCTAssertEqual(model.ayahIndicators, [page.firstVerse: [.note]])
    }
}
#endif
