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
    func test_imagePage_ignoresUnrelatedAnnotationsAndReceivesVisibilityChanges() {
        let reading = Reading.hafs_1405
        let page = reading.quran.pages[0]
        let other = reading.quran.pages[1].firstVerse
        let service = VerseOverlayService()
        service.overlays.annotationsHidden = true
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
        XCTAssertTrue(model.annotationsHidden)
        var updates = 0
        let subscription = model.objectWillChange.sink { updates += 1 }
        defer { subscription.cancel() }

        service.overlays.notedVerses = [other]
        XCTAssertEqual(updates, 0)
        XCTAssertTrue(model.ayahAnnotations.isEmpty)

        service.overlays.notedVerses.insert(page.firstVerse)
        XCTAssertEqual(updates, 1)
        XCTAssertEqual(model.ayahAnnotations, [page.firstVerse: [.note]])

        service.overlays.annotationsHidden = false
        XCTAssertFalse(model.annotationsHidden)
        service.overlays.annotationsHidden = true
        XCTAssertTrue(model.annotationsHidden)
        XCTAssertEqual(model.ayahAnnotations, [page.firstVerse: [.note]])
    }

    func test_linePage_ignoresUnrelatedAnnotationsAndReceivesVisibilityChanges() throws {
        let reading = Reading.hafs_1441
        let page = reading.quran.pages[0]
        let other = reading.quran.pages[1].firstVerse
        let service = VerseOverlayService()
        service.overlays.annotationsHidden = true
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
        XCTAssertTrue(model.annotationsHidden)
        var updates = 0
        let subscription = model.objectWillChange.sink { updates += 1 }
        defer { subscription.cancel() }

        service.overlays.notedVerses = [other]
        XCTAssertEqual(updates, 0)
        XCTAssertTrue(model.ayahAnnotations.isEmpty)

        service.overlays.notedVerses.insert(page.firstVerse)
        XCTAssertEqual(updates, 1)
        XCTAssertEqual(model.ayahAnnotations, [page.firstVerse: [.note]])

        service.overlays.annotationsHidden = false
        XCTAssertFalse(model.annotationsHidden)
        service.overlays.annotationsHidden = true
        XCTAssertTrue(model.annotationsHidden)
        XCTAssertEqual(model.ayahAnnotations, [page.firstVerse: [.note]])
    }
}
#endif
