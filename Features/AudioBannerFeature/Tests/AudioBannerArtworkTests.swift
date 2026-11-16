//
//  AudioBannerArtworkTests.swift
//

import AdvancedAudioOptionsFeature
import AnalyticsFake
import BatchDownloaderFake
import ReciterListFeature
import ReciterService
import SystemDependenciesFake
import XCTest
@testable import AudioBannerFeature
@testable import NoorUI
@testable import QuranAudioKit

@MainActor
final class AudioBannerArtworkTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Different sizes, so the tests can tell the two icons' artwork apart.
        primary = try makeOption(id: "primary", alternateIconName: nil, artworkSide: 1)
        graphite = try makeOption(id: "graphite", alternateIconName: "AppIcon-Graphite", artworkSide: 2)
        iconAccess = AlternateIconAccessFake()
        appIconService = AppIconService(
            catalog: AppIconCatalog(sections: [
                .init(id: "all", title: "All", previewSize: .large, options: [primary, graphite]),
            ]),
            iconAccess: iconAccess,
            bundle: SystemBundleFake()
        )
        downloadsContext = BatchDownloaderFake.makeContext()
    }

    override func tearDown() async throws {
        AppIconAccent.setCurrent(nil)
        downloadsContext = nil
        try? FileManager.default.removeItem(at: directory)
        try await super.tearDown()
    }

    func test_init_showsTheCurrentIconAsTheArtwork() async throws {
        iconAccess.alternateIconName = "AppIcon-Graphite"
        let player = QuranAudioPlayer()

        let viewModel = await makeViewModel(audioPlayer: player)

        let expected = try XCTUnwrap(graphite.artworkImage)
        XCTAssertEqual(player.artwork?.size, expected.size)
        withExtendedLifetime(viewModel) { }
    }

    func test_changingTheIcon_showsTheNewIconAsTheArtwork() async throws {
        let player = QuranAudioPlayer()
        let viewModel = await makeViewModel(audioPlayer: player)
        XCTAssertEqual(player.artwork?.size, try XCTUnwrap(primary.artworkImage).size)

        try await appIconService.set(graphite)

        XCTAssertEqual(player.artwork?.size, try XCTUnwrap(graphite.artworkImage).size)
        withExtendedLifetime(viewModel) { }
    }

    // MARK: Private

    private var directory: URL!
    private var primary: AppIconOption!
    private var graphite: AppIconOption!
    private var iconAccess: AlternateIconAccessFake!
    private var appIconService: AppIconService!
    private var downloadsContext: BatchDownloaderTestContext!

    /// An option whose artwork is a square PNG file of `artworkSide` points.
    private func makeOption(id: String, alternateIconName: String?, artworkSide: CGFloat) throws -> AppIconOption {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: artworkSide, height: artworkSide)
        let data = UIGraphicsImageRenderer(size: size, format: format).pngData { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let url = directory.appendingPathComponent("\(id).png")
        try data.write(to: url)
        return AppIconOption(
            id: id,
            alternateIconName: alternateIconName,
            name: id,
            previewImageName: id,
            // An absolute path, because the test runner's main bundle has no artwork asset catalog.
            artworkImageName: url.path,
            accent: AppIconAccent(light: .black, dark: .white, onDark: .black)
        )
    }

    private func makeViewModel(audioPlayer: QuranAudioPlayer) async -> AudioBannerViewModel {
        AudioBannerViewModel(
            analytics: AnalyticsLibrarySpy(),
            reciterRetreiver: ReciterDataRetriever(),
            recentRecitersService: RecentRecitersService(),
            audioPlayer: audioPlayer,
            appIconService: appIconService,
            downloader: QuranAudioDownloader(
                baseURL: URL(string: "https://files.quran.com")!,
                downloader: await downloadsContext.makeDownloaderDontWaitForSession()
            ),
            reciterListBuilder: ReciterListBuilder(),
            advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder()
        )
    }
}
