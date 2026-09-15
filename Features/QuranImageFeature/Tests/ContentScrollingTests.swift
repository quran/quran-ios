import AnnotationsService
import ImageService
import QuranGeometry
import QuranKit
import ReadingService
import SwiftUI
import TestResources
import XCTest
@testable import QuranImageFeature

@MainActor
final class ContentScrollingTests: XCTestCase {
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

    func testPageImagesScrollToInitialAndUpdatedVerseInLandscape() async throws {
        let reading = Reading.hafs_1405
        let previousReading = ReadingPreferences.shared.reading
        ReadingPreferences.shared.reading = reading
        defer { ReadingPreferences.shared.reading = previousReading }
        let page = reading.quran.pages[603]
        let initialAyah = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 114, ayah: 1))
        let nextAyah = try XCTUnwrap(AyahNumber(quran: reading.quran, sura: 113, ayah: 1))
        let overlayService = VerseOverlayService()
        overlayService.overlays.navigationTarget = initialAyah
        let model = ContentImageViewModel(
            reading: reading,
            page: page,
            imageDataService: ImageDataService(
                ayahInfoDatabase: TestResources.resourceURL("hafs_1405_ayahinfo.db"),
                imagesURL: TestResources.testDataURL.appendingPathComponent("images"),
                ayahMarkerURL: nil
            ),
            overlayService: overlayService
        )
        #if QURAN_SYNC
        let view = ContentImageView(viewModel: model, onAnnotatedAyahTap: { _, _ in })
        #else
        let view = ContentImageView(viewModel: model)
        #endif
        let host = host(view)
        defer { host.window.isHidden = true }
        let scrollView = try XCTUnwrap(findScrollView(in: host.controller.view))

        for ayah in [initialAyah, nextAyah] {
            if ayah == nextAyah { overlayService.overlays.navigationTarget = ayah }
            await waitUntil("Page image scrolls to \(ayah)", diagnostics: {
                "scale=\(model.scale.scale), image=\(model.imageFrame), "
                    + "offset=\(scrollView.contentOffset), content=\(scrollView.contentSize)"
            }) {
                guard let frame = model.imagePage?.wordFrames.verseStartFrame(for: ayah), model.scale.scale > 0 else { return false }
                let viewport = scrollView.convert(scrollView.bounds, to: nil)
                let targetY = model.imageFrame.minY + frame.rect.scaled(by: model.scale).minY
                let expectedY = viewport.minY + (viewport.height - 1) * 0.2
                return scrollView.contentOffset.y > 0 && abs(targetY - expectedY) < 2
            }
        }
    }

    func testLineImagesScrollToInitialAndUpdatedVerseInLandscape() async throws {
        let reading = Reading.hafs_1441
        let metrics = try XCTUnwrap(reading.linePageMetrics)
        let page = reading.quran.pages[0]
        let initialAyah = page.quran.suras[0].verses[5]
        let nextAyah = page.quran.suras[0].verses[1]
        let root = try makeLinePageFiles(metrics: metrics)
        defer { try? FileManager.default.removeItem(at: root) }
        let overlayService = VerseOverlayService()
        overlayService.overlays.navigationTarget = initialAyah
        let model = ContentLineViewModel(
            reading: reading,
            page: page,
            linePageAssetService: LinePageAssetService(
                readingDirectory: root, metrics: metrics, quran: reading.quran, ayahMarkerURL: nil
            ),
            overlayService: overlayService
        )
        #if QURAN_SYNC
        let view = ContentLineView(viewModel: model, onAnnotatedAyahTap: { _, _ in })
        #else
        let view = ContentLineView(viewModel: model)
        #endif
        let host = host(view)
        defer { host.window.isHidden = true }
        let scrollView = try XCTUnwrap(findScrollView(in: host.controller.view))

        for ayah in [initialAyah, nextAyah] {
            if ayah == nextAyah { overlayService.overlays.navigationTarget = ayah }
            await waitUntil("Line images scroll to \(ayah)", diagnostics: {
                "spans=\(model.geometryData.highlightSpans.count), "
                    + "offset=\(scrollView.contentOffset), content=\(scrollView.contentSize)"
            }) {
                guard scrollView.contentOffset.y > 0 else { return false }
                let viewport = scrollView.convert(scrollView.bounds, to: nil)
                // Sample inside the line below the 20% scroll anchor: adjacent line images overlap.
                // Use the renderer's hit geometry, including header and readable insets.
                let lineCenterY = viewport.minY + viewport.height * 0.2 + CGFloat(metrics.lineHeightRatio) * viewport.width / 2
                return stride(from: viewport.minX, through: viewport.maxX, by: 2).contains { x in
                    model.verseAtGlobalPoint(CGPoint(x: x, y: lineCenterY)) == ayah
                }
            }
        }
    }

    private var animationsWereEnabled = true

    private func host(_ view: some View) -> (window: UIWindow, controller: UIViewController) {
        let controller = UIHostingController(rootView: view.frame(width: 800, height: 300).ignoresSafeArea())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 300))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        return (window, controller)
    }

    private func waitUntil(_ description: String, diagnostics: () -> String, predicate: @escaping @MainActor () -> Bool) async {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in MainActor.assumeIsolated { predicate() } },
            object: nil
        )
        expectation.expectationDescription = description
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "\(description): \(diagnostics())")
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        return view.subviews.lazy.compactMap { self.findScrollView(in: $0) }.first
    }

    private func makeLinePageFiles(metrics: LinePageMetrics) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let images = root.appendingPathComponent("images_\(metrics.widthParameter)")
        let database = images.appendingPathComponent("databases")
        let lines = images.appendingPathComponent("width_\(metrics.widthParameter)/1")
        try FileManager.default.createDirectory(at: database, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: lines, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: TestResources.resourceURL("line_page_ayahinfo.db"),
            to: database.appendingPathComponent("ayahinfo_\(metrics.widthParameter).db")
        )
        let imageSize = CGSize(width: CGFloat(metrics.widthParameter), height: CGFloat(metrics.intrinsicLineHeight))
        let image = UIGraphicsImageRenderer(size: imageSize).pngData { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
        }
        for line in 1 ... metrics.lineCount {
            try image.write(to: lines.appendingPathComponent("\(line).png"))
        }
        return root
    }
}
