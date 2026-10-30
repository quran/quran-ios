#if QURAN_SYNC
import AnnotationsService
import Combine
import ImageService
import QuranAnnotations
import QuranKit
import ReadingService
import TestResources
import XCTest
@testable import QuranImageFeature

@MainActor
final class ContentOverlayTests: XCTestCase {
    func test_imagePage_showsOnlyItsReadingBookmarks() {
        let reading = Reading.hafs_1405
        let page = reading.quran.pages[0]
        let service = VerseOverlayService()
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

        assertShowsOnlyThisPagesAyahAndPageReadingBookmarks(
            service: service,
            page: page,
            objectWillChange: model.objectWillChange,
            ayahReadingBookmarks: { model.ayahReadingBookmarks },
            pageReadingBookmarks: { model.pageReadingBookmarks }
        )
    }

    func test_linePage_showsOnlyItsReadingBookmarks() throws {
        let reading = Reading.hafs_1441
        let page = reading.quran.pages[0]
        let service = VerseOverlayService()
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

        assertShowsOnlyThisPagesAyahAndPageReadingBookmarks(
            service: service,
            page: page,
            objectWillChange: model.objectWillChange,
            ayahReadingBookmarks: { model.ayahReadingBookmarks },
            pageReadingBookmarks: { model.pageReadingBookmarks }
        )
    }

    private func assertShowsOnlyThisPagesAyahAndPageReadingBookmarks(
        service: VerseOverlayService,
        page: Page,
        objectWillChange: ObservableObjectPublisher,
        ayahReadingBookmarks: () -> [AyahNumber: [ReadingBookmarkSlot]],
        pageReadingBookmarks: () -> [ReadingBookmarkSlot],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let other = page.quran.pages[1]
        var updates = 0
        let subscription = objectWillChange.sink { updates += 1 }
        defer { subscription.cancel() }

        service.overlays.readingBookmarks = [
            bookmark(.teal, at: .ayah(other.firstVerse)),
            bookmark(.orange, at: .page(other)),
        ]
        XCTAssertEqual(updates, 0, file: file, line: line)
        XCTAssertTrue(ayahReadingBookmarks().isEmpty, file: file, line: line)
        XCTAssertTrue(pageReadingBookmarks().isEmpty, file: file, line: line)

        service.overlays.notedVerses = [page.firstVerse]
        service.overlays.collectionVerses = [page.firstVerse]
        XCTAssertTrue(ayahReadingBookmarks().isEmpty, file: file, line: line)

        service.overlays.readingBookmarks += [
            bookmark(.red, at: .ayah(page.firstVerse)),
            bookmark(.teal, at: .page(page)),
        ]
        XCTAssertEqual(ayahReadingBookmarks(), [page.firstVerse: [.red]], file: file, line: line)
        XCTAssertEqual(pageReadingBookmarks(), [.teal], file: file, line: line)
    }

    private func bookmark(_ slot: ReadingBookmarkSlot, at placement: PlacedReadingBookmark.Placement) -> PlacedReadingBookmark {
        PlacedReadingBookmark(id: "\(slot)-\(placement)", slot: slot, placement: placement, modifiedOn: .distantPast)
    }
}
#endif
