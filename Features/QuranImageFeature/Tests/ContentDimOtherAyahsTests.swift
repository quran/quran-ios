import AnnotationsService
import Combine
import ImageService
import QuranKit
import ReadingService
import TestResources
import XCTest
@testable import QuranImageFeature

@MainActor
final class ContentDimOtherAyahsTests: XCTestCase {
    // MARK: Image pages

    func test_imagePage_leavesThePlayingVerseUndimmed() {
        let page = Reading.hafs_1405.quran.pages[0]
        let service = dimmingService()
        let model = makeImageModel(page: page, service: service)

        service.overlays.playingVerses = [page.verses[1]]

        XCTAssertEqual(model.decorations.undimmedVerses, [page.verses[1]])
    }

    func test_imagePage_dimsTheWholePageWhileAudioPlaysOnAnotherPage() {
        let quran = Reading.hafs_1405.quran
        let service = dimmingService()
        let model = makeImageModel(page: quran.pages[0], service: service)

        service.overlays.playingVerses = [quran.pages[1].firstVerse]

        XCTAssertEqual(model.decorations.undimmedVerses, [])
    }

    func test_imagePage_undimsWhenDimOtherAyahsTurnsOff() {
        let page = Reading.hafs_1405.quran.pages[0]
        let service = dimmingService()
        service.overlays.playingVerses = [page.verses[1]]
        let model = makeImageModel(page: page, service: service)

        service.overlays.dimsOtherAyahs = false

        XCTAssertNil(model.decorations.undimmedVerses)
    }

    func test_imagePage_doesNotRedrawWhileAudioMovesBetweenVersesOfAnotherPage() {
        let quran = Reading.hafs_1405.quran
        let service = dimmingService()
        service.overlays.playingVerses = [quran.pages[1].verses[0]]
        let model = makeImageModel(page: quran.pages[0], service: service)
        var changes = 0
        let subscription = model.objectWillChange.sink { changes += 1 }
        defer { subscription.cancel() }

        service.overlays.playingVerses = [quran.pages[1].verses[1]]

        XCTAssertEqual(changes, 0)
    }

    // MARK: Line pages

    func test_linePage_leavesThePlayingVerseUndimmed() throws {
        let page = Reading.hafs_1441.quran.pages[0]
        let service = dimmingService()
        let model = try makeLineModel(page: page, service: service)

        service.overlays.playingVerses = [page.verses[1]]

        XCTAssertEqual(model.undimmedVerses, [page.verses[1]])
    }

    func test_linePage_dimsTheWholePageWhileAudioPlaysOnAnotherPage() throws {
        let quran = Reading.hafs_1441.quran
        let service = dimmingService()
        let model = try makeLineModel(page: quran.pages[0], service: service)

        service.overlays.playingVerses = [quran.pages[1].firstVerse]

        XCTAssertEqual(model.undimmedVerses, [])
    }

    func test_linePage_doesNotRedrawWhileAudioMovesBetweenVersesOfAnotherPage() throws {
        let quran = Reading.hafs_1441.quran
        let service = dimmingService()
        service.overlays.playingVerses = [quran.pages[1].verses[0]]
        let model = try makeLineModel(page: quran.pages[0], service: service)
        var changes = 0
        let subscription = model.objectWillChange.sink { changes += 1 }
        defer { subscription.cancel() }

        service.overlays.playingVerses = [quran.pages[1].verses[1]]

        XCTAssertEqual(changes, 0)
    }

    func test_linePage_laysOutHighlightRectsForTheUndimmedSelection() async throws {
        let page = Reading.hafs_1441.quran.pages[0]
        let selected = page.verses[3]
        let service = dimmingService()
        service.overlays.playingVerses = [page.verses[1]]
        service.overlays.selectedVerses = [selected]

        let rectVerses = try await highlightRectVerses(page: page, service: service)

        XCTAssertTrue(rectVerses.contains(selected))
    }

    func test_linePage_laysOutHighlightRectsForTheUndimmedNavigationHighlight() async throws {
        let page = Reading.hafs_1441.quran.pages[0]
        let highlighted = page.verses[4]
        let service = dimmingService()
        service.overlays.playingVerses = [page.verses[1]]
        service.overlays.navigationHighlight = highlighted

        let rectVerses = try await highlightRectVerses(page: page, service: service)

        XCTAssertTrue(rectVerses.contains(highlighted))
    }

    // MARK: Private

    private func dimmingService() -> VerseOverlayService {
        let service = VerseOverlayService()
        service.overlays.dimsOtherAyahs = true
        return service
    }

    private func makeImageModel(page: Page, service: VerseOverlayService) -> ContentImageViewModel {
        ContentImageViewModel(
            reading: .hafs_1405,
            page: page,
            imageDataService: ImageDataService(
                ayahInfoDatabase: TestResources.resourceURL("hafs_1405_ayahinfo.db"),
                imagesURL: TestResources.testDataURL.appendingPathComponent("images"),
                ayahMarkerURL: nil
            ),
            overlayService: service
        )
    }

    private func makeLineModel(page: Page, service: VerseOverlayService, readingDirectory: URL = TestResources.testDataURL) throws -> ContentLineViewModel {
        let reading = Reading.hafs_1441
        return ContentLineViewModel(
            reading: reading,
            page: page,
            linePageAssetService: LinePageAssetService(
                readingDirectory: readingDirectory,
                metrics: try XCTUnwrap(reading.linePageMetrics),
                quran: reading.quran,
                ayahMarkerURL: nil
            ),
            overlayService: service
        )
    }

    /// Verses with highlight rects on the loaded line page; the dim's cutouts come from these.
    private func highlightRectVerses(page: Page, service: VerseOverlayService) async throws -> Set<AyahNumber> {
        let root = try makeLinePageFiles(metrics: try XCTUnwrap(Reading.hafs_1441.linePageMetrics))
        defer { try? FileManager.default.removeItem(at: root) }
        let model = try makeLineModel(page: page, service: service, readingDirectory: root)
        await model.loadLinePage()
        let size = CGSize(width: 400, height: 800)
        let layout = try XCTUnwrap(model.layout(for: size, showHeaderFooter: false))
        return Set(layout.highlightRects.map(\.ayah))
    }
}
