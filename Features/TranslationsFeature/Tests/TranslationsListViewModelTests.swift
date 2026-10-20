//
//  TranslationsListViewModelTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import BatchDownloader
import BatchDownloaderFake
import NetworkSupport
import NetworkSupportFake
import QuranText
import TestResources
import TranslationPersistence
import TranslationServiceFake
import Utilities
import XCTest
@testable import TranslationService
@testable import TranslationsFeature

@MainActor
final class TranslationsListViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        preferences.reset()
        fileNamePrefix = "TranslationsListViewModelTests-\(UUID().uuidString)"
        databasesURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileNamePrefix, isDirectory: true)
        try FileManager.default.createDirectory(at: databasesURL, withIntermediateDirectories: true)
        serverSession = NetworkSessionFake(queue: .main, delegate: nil)
        downloadsContext = BatchDownloaderFake.makeContext()
        (downloadManager, downloadSession) = await downloadsContext.makeDownloader()
    }

    override func tearDown() async throws {
        startTask?.cancel()
        await startTask?.value
        startTask = nil
        for translation in serverTranslations {
            for file in translation.localFiles {
                try? FileManager.default.removeItem(at: file.url)
            }
        }
        serverTranslations = []
        try? FileManager.default.removeItem(at: databasesURL)
        preferences.reset()
        downloadManager = nil
        downloadSession = nil
        downloadsContext = nil
        serverSession = nil
        try await super.tearDown()
    }

    // MARK: - Upgrade availability

    func test_downloadedTranslationsWithOlderInstalledVersion_needUpgrade() async throws {
        let selected = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: TextVersion.old)
        let downloaded = try await makeTranslation(id: 2, version: TextVersion.new, installedVersion: TextVersion.old)
        preferences.selectedTranslationIds = [selected.id]

        let viewModel = try await startViewModel()

        XCTAssertEqual(viewModel.selectedTranslations, [TranslationItem(info: selected, progress: .needsUpgrade)])
        XCTAssertEqual(viewModel.downloadedTranslations, [TranslationItem(info: downloaded, progress: .needsUpgrade)])
    }

    func test_upToDateDownloadedTranslation_doesNotNeedUpgrade() async throws {
        let upToDate = try await makeTranslation(id: 1, version: TextVersion.old, installedVersion: TextVersion.old)

        let viewModel = try await startViewModel()

        XCTAssertEqual(viewModel.downloadedTranslations, [TranslationItem(info: upToDate, progress: .notDownloading)])
    }

    func test_downloadedTranslationNewerThanServer_doesNotNeedUpgrade() async throws {
        let newer = try await makeTranslation(id: 1, version: TextVersion.old, installedVersion: TextVersion.new)

        let viewModel = try await startViewModel()

        XCTAssertEqual(viewModel.downloadedTranslations, [TranslationItem(info: newer, progress: .notDownloading)])
    }

    func test_notDownloadedTranslation_doesNotNeedUpgrade() async throws {
        let notDownloaded = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: nil)

        let viewModel = try await startViewModel()

        XCTAssertEqual(viewModel.availableTranslations, [TranslationItem(info: notDownloaded, progress: .notDownloading)])
    }

    // MARK: - Upgrading

    func test_upgradingSelectedTranslation_installsNewVersionAndKeepsSelection() async throws {
        let outdated = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: TextVersion.old)
        let other = try await makeTranslation(id: 2, version: TextVersion.old, installedVersion: TextVersion.old)
        preferences.selectedTranslationIds = [outdated.id, other.id]
        let viewModel = try await startViewModel()
        XCTAssertEqual(item(outdated, in: viewModel)?.progress, .needsUpgrade)

        let download = try await startDownloading(outdated, in: viewModel)
        try await completeDownload(download, textVersion: TextVersion.new)
        await waitUntilDownloadEnded(outdated, in: viewModel)

        XCTAssertEqual(viewModel.selectedTranslations, [
            TranslationItem(info: installed(outdated, version: TextVersion.new), progress: .notDownloading),
            TranslationItem(info: other, progress: .notDownloading),
        ])
        XCTAssertEqual(preferences.selectedTranslationIds, [outdated.id, other.id])
    }

    func test_upgradingUnselectedTranslation_keepsItUnselected() async throws {
        let outdated = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: TextVersion.old)
        let viewModel = try await startViewModel()
        XCTAssertEqual(item(outdated, in: viewModel)?.progress, .needsUpgrade)

        let download = try await startDownloading(outdated, in: viewModel)
        try await completeDownload(download, textVersion: TextVersion.new)
        await waitUntilDownloadEnded(outdated, in: viewModel)

        XCTAssertEqual(viewModel.downloadedTranslations, [
            TranslationItem(info: installed(outdated, version: TextVersion.new), progress: .notDownloading),
        ])
        XCTAssertEqual(preferences.selectedTranslationIds, [])
    }

    func test_cancellingUpgrade_keepsInstalledVersionAndSelection() async throws {
        let outdated = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: TextVersion.old)
        let other = try await makeTranslation(id: 2, version: TextVersion.old, installedVersion: TextVersion.old)
        preferences.selectedTranslationIds = [other.id]
        let viewModel = try await startViewModel()

        _ = try await startDownloading(outdated, in: viewModel)
        let downloadingItem = try XCTUnwrap(item(outdated, in: viewModel))
        await viewModel.cancelDownloading(downloadingItem)
        await waitUntilDownloadEnded(outdated, in: viewModel)

        XCTAssertEqual(item(outdated, in: viewModel), TranslationItem(info: outdated, progress: .needsUpgrade))
        XCTAssertEqual(preferences.selectedTranslationIds, [other.id])
    }

    // MARK: - Auto-selection

    func test_completedNewDownload_selectsTranslation() async throws {
        let translation = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: nil)
        let viewModel = try await startViewModel()

        let download = try await startDownloading(translation, in: viewModel)
        try await completeDownload(download, textVersion: TextVersion.new)
        await waitUntilDownloadEnded(translation, in: viewModel)

        XCTAssertEqual(item(translation, in: viewModel)?.info, installed(translation, version: TextVersion.new))
        XCTAssertEqual(preferences.selectedTranslationIds, [translation.id])
    }

    func test_cancelledDownload_doesNotSelectTranslation() async throws {
        let translation = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: nil)
        let viewModel = try await startViewModel()

        _ = try await startDownloading(translation, in: viewModel)
        let downloadingItem = try XCTUnwrap(item(translation, in: viewModel))
        await viewModel.cancelDownloading(downloadingItem)
        await waitUntilDownloadEnded(translation, in: viewModel)

        XCTAssertEqual(viewModel.availableTranslations, [TranslationItem(info: translation, progress: .notDownloading)])
        XCTAssertEqual(preferences.selectedTranslationIds, [])
    }

    func test_failedDownload_doesNotSelectTranslation() async throws {
        let translation = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: nil)
        let viewModel = try await startViewModel()

        let download = try await startDownloading(translation, in: viewModel)
        downloadSession.failDownloadTask(download, error: URLError(.timedOut))
        await waitUntilDownloadEnded(translation, in: viewModel)

        XCTAssertEqual(viewModel.availableTranslations, [TranslationItem(info: translation, progress: .notDownloading)])
        XCTAssertEqual(preferences.selectedTranslationIds, [])
    }

    // MARK: Private

    /// Text versions stored in the TestResources translation databases.
    private enum TextVersion {
        static let old = 5
        static let new = 8
    }

    private static let databaseResources = [
        TextVersion.old: "quran.en.khanhilali.db",
        TextVersion.new: "quran.ensi.db",
    ]

    private let baseURL = URL(validURL: "https://example.com")
    private let preferences = SelectedTranslationsPreferences.shared

    private var fileNamePrefix: String!
    private var databasesURL: URL!
    private var serverSession: NetworkSessionFake!
    private var downloadsContext: BatchDownloaderTestContext!
    private var downloadManager: DownloadManager!
    private var downloadSession: NetworkSessionFake!
    private var serverTranslations: [Translation] = []
    private var startTask: Task<Void, Never>?

    /// Saves a translation that the server lists, installing the database with `installedVersion` when given.
    private func makeTranslation(id: Translation.ID, version: Int, installedVersion: Int?) async throws -> Translation {
        let fileName = "\(fileNamePrefix!)-\(id).db"
        let translation = Translation(
            id: id,
            displayName: "Translation \(id)",
            translator: nil,
            translatorForeign: nil,
            fileURL: URL(validURL: "https://example.com/\(fileName)"),
            fileName: fileName,
            languageCode: "en",
            version: version,
            installedVersion: installedVersion
        )
        serverTranslations.append(translation)
        try await GRDBActiveTranslationsPersistence(directory: databasesURL).insert(translation)
        if let installedVersion {
            let destination = translation.localPath.url
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try FileManager.default.copyItem(at: databaseURL(textVersion: installedVersion), to: destination)
        }
        return translation
    }

    private func startViewModel() async throws -> TranslationsListViewModel {
        try serverSession.respondWithTranslations(serverTranslations, baseURL: baseURL)
        let viewModel = TranslationsListViewModel(
            analytics: NoopAnalytics(),
            translationsRepository: TranslationsRepository(
                databasesURL: databasesURL,
                networkManager: NetworkManager(session: serverSession, baseURL: baseURL)
            ),
            localTranslationsRetriever: LocalTranslationsRetriever(databasesURL: databasesURL),
            deleter: TranslationDeleter(databasesURL: databasesURL),
            downloader: TranslationsDownloader(downloader: downloadManager)
        )
        startTask = Task { await viewModel.start() }
        await waitUntil { !viewModel.loading }
        XCTAssertNil(viewModel.error)
        return viewModel
    }

    private func startDownloading(_ translation: Translation, in viewModel: TranslationsListViewModel) async throws -> SessionTask {
        let item = try XCTUnwrap(item(translation, in: viewModel))
        await viewModel.startDownloading(item)
        let download = downloadSession.downloads.first { $0.originalRequest?.url == translation.fileURL }
        return try XCTUnwrap(download)
    }

    private func completeDownload(_ download: SessionTask, textVersion: Int) async throws {
        let location = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileNamePrefix!)-download-\(UUID().uuidString).db")
        try FileManager.default.copyItem(at: databaseURL(textVersion: textVersion), to: location)
        await downloadSession.completeDownloadTask(download, location: location, totalBytes: 100, progressLoops: 1)
    }

    /// Waits until the list stops showing the download, which happens after it reloads the local translations.
    private func waitUntilDownloadEnded(
        _ translation: Translation,
        in viewModel: TranslationsListViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await waitUntil(file: file, line: line) {
            guard let item = self.item(translation, in: viewModel) else {
                return false
            }
            if case .downloading = item.progress {
                return false
            }
            return true
        }
    }

    private func item(_ translation: Translation, in viewModel: TranslationsListViewModel) -> TranslationItem? {
        let items = viewModel.selectedTranslations + viewModel.downloadedTranslations + viewModel.availableTranslations
        return items.first { $0.id == translation.id }
    }

    private func installed(_ translation: Translation, version: Int) -> Translation {
        var translation = translation
        translation.installedVersion = version
        return translation
    }

    private func databaseURL(textVersion: Int) throws -> URL {
        let resource = try XCTUnwrap(Self.databaseResources[textVersion])
        return TestResources.resourceURL(resource)
    }

    private func waitUntil(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }
}

private struct NoopAnalytics: AnalyticsLibrary {
    func logEvent(_ name: String, value: String) { }
}
