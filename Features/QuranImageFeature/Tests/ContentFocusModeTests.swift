import AnnotationsService
import ImageService
import QuranKit
import ReadingService
import TestResources
import XCTest
@testable import QuranImageFeature

@MainActor
final class ContentFocusModeTests: XCTestCase {
    func test_imagePage_focusesThePlayingVerseOnlyWhileFocusModeIsOn() {
        let reading = Reading.hafs_1405
        let page = reading.quran.pages[0]
        let recited = page.verses[1]
        let service = VerseOverlayService()
        let model = makeImageModel(reading: reading, page: page, service: service)

        service.overlays.playingVerses = [recited]
        XCTAssertNil(model.decorations.focusedVerses)

        service.overlays.focusModeEnabled = true
        XCTAssertEqual(model.decorations.focusedVerses, [recited])

        service.overlays.playingVerses = []
        XCTAssertNil(model.decorations.focusedVerses)
    }

    func test_imagePage_dimsTheWholePageWhileAudioPlaysOnAnotherPage() {
        let reading = Reading.hafs_1405
        let page = reading.quran.pages[0]
        let service = VerseOverlayService()
        service.overlays.focusModeEnabled = true
        let model = makeImageModel(reading: reading, page: page, service: service)

        service.overlays.playingVerses = [reading.quran.pages[1].firstVerse]

        XCTAssertEqual(model.decorations.focusedVerses, [])
    }

    func test_linePage_followsFocusModeAndThePlayingVerse() throws {
        let reading = Reading.hafs_1441
        let page = reading.quran.pages[0]
        let recited = page.verses[1]
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

        service.overlays.playingVerses = [recited]
        XCTAssertNil(model.focusedVerses)

        service.overlays.focusModeEnabled = true
        XCTAssertEqual(model.focusedVerses, [recited])

        service.overlays.playingVerses = [reading.quran.pages[1].firstVerse]
        XCTAssertEqual(model.focusedVerses, [])

        service.overlays.focusModeEnabled = false
        XCTAssertNil(model.focusedVerses)
    }

    private func makeImageModel(reading: Reading, page: Page, service: VerseOverlayService) -> ContentImageViewModel {
        ContentImageViewModel(
            reading: reading,
            page: page,
            imageDataService: ImageDataService(
                ayahInfoDatabase: TestResources.resourceURL("hafs_1405_ayahinfo.db"),
                imagesURL: TestResources.testDataURL.appendingPathComponent("images"),
                ayahMarkerURL: nil
            ),
            overlayService: service
        )
    }
}
