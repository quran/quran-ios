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

    // MARK: - Downloads running when the list opens

    func test_completedNewDownloadRunningOnOpen_selectsTranslation() async throws {
        let translation = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: nil)
        let download = try await startDownloadingWithoutViewModel(translation)
        let viewModel = try await startViewModel()
        await downloadSession.writeDownloadData(download, bytesWritten: 50, totalBytes: 100)
        await waitUntil { self.item(translation, in: viewModel).map(self.isDownloading) == true }

        try await completeDownload(download, textVersion: TextVersion.new)
        await waitUntilInstalled(translation, version: TextVersion.new, in: viewModel)

        XCTAssertEqual(preferences.selectedTranslationIds, [translation.id])
    }

    func test_completedUpgradeRunningOnOpen_keepsTranslationUnselected() async throws {
        let outdated = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: TextVersion.old)
        let download = try await startDownloadingWithoutViewModel(outdated)
        let viewModel = try await startViewModel()
        await downloadSession.writeDownloadData(download, bytesWritten: 50, totalBytes: 100)
        await waitUntil { self.item(outdated, in: viewModel).map(self.isDownloading) == true }

        try await completeDownload(download, textVersion: TextVersion.new)
        await waitUntilInstalled(outdated, version: TextVersion.new, in: viewModel)

        XCTAssertEqual(preferences.selectedTranslationIds, [])
    }

    // MARK: - Changes during downloads

    func test_serverVersionChangeDuringDownload_keepsShowingProgress() async throws {
        let translation = try await makeTranslation(id: 1, version: TextVersion.old, installedVersion: nil)
        let viewModel = try await startViewModel()

        _ = try await startDownloading(translation, in: viewModel)
        let updated = try await refreshServer(translation, version: TextVersion.new, in: viewModel)

        let downloadingItem = try XCTUnwrap(item(translation, in: viewModel))
        XCTAssertEqual(downloadingItem.info, updated)
        XCTAssertTrue(isDownloading(downloadingItem))
    }

    func test_completedNewDownloadAfterServerVersionChange_selectsTranslation() async throws {
        let translation = try await makeTranslation(id: 1, version: TextVersion.old, installedVersion: nil)
        let viewModel = try await startViewModel()

        let download = try await startDownloading(translation, in: viewModel)
        let updated = try await refreshServer(translation, version: TextVersion.new, in: viewModel)
        try await completeDownload(download, textVersion: TextVersion.new)
        await waitUntilDownloadEnded(translation, in: viewModel)

        XCTAssertEqual(
            item(translation, in: viewModel),
            TranslationItem(info: installed(updated, version: TextVersion.new), progress: .notDownloading)
        )
        XCTAssertEqual(preferences.selectedTranslationIds, [translation.id])
    }

    func test_deletingTranslationDuringUpgrade_endsDownload() async throws {
        let outdated = try await makeTranslation(id: 1, version: TextVersion.new, installedVersion: TextVersion.old)
        let viewModel = try await startViewModel()

        _ = try await startDownloading(outdated, in: viewModel)
        let downloadingItem = try XCTUnwrap(item(outdated, in: viewModel))
        let deleteAction = try XCTUnwrap(viewModel.deleteTranslation(downloadingItem))
        await deleteAction()
        await waitUntilDownloadEnded(outdated, in: viewModel)

        XCTAssertEqual(viewModel.availableTranslations, [
            TranslationItem(info: installed(outdated, version: nil), progress: .notDownloading),
        ])
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

    /// Starts downloading `translation` outside the list, as a download that was running before the list opened.
    private func startDownloadingWithoutViewModel(_ translation: Translation) async throws -> SessionTask {
        _ = try await TranslationsDownloader(downloader: downloadManager).download(translation)
        let download = downloadSession.downloads.first { $0.originalRequest?.url == translation.fileURL }
        return try XCTUnwrap(download)
    }

    private func completeDownload(_ download: SessionTask, textVersion: Int) async throws {
        let location = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileNamePrefix!)-download-\(UUID().uuidString).db")
        try FileManager.default.copyItem(at: databaseURL(textVersion: textVersion), to: location)
        await downloadSession.completeDownloadTask(download, location: location, totalBytes: 100, progressLoops: 1)
    }

    /// Makes the server list `translation` at `version` and refreshes the list.
    private func refreshServer(
        _ translation: Translation,
        version: Int,
        in viewModel: TranslationsListViewModel
    ) async throws -> Translation {
        let updated = Translation(
            id: translation.id,
            displayName: translation.displayName,
            translator: translation.translator,
            translatorForeign: translation.translatorForeign,
            fileURL: translation.fileURL,
            fileName: translation.fileName,
            languageCode: translation.languageCode,
            version: version,
            installedVersion: translation.installedVersion
        )
        serverTranslations = serverTranslations.map { $0.id == updated.id ? updated : $0 }
        try serverSession.respondWithTranslations(serverTranslations, baseURL: baseURL)
        await viewModel.refresh()
        XCTAssertNil(viewModel.error)
        return updated
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
            return !self.isDownloading(item)
        }
    }

    /// Waits until the list shows `translation` installed at `version`, which happens after its download ends.
    private func waitUntilInstalled(
        _ translation: Translation,
        version: Int,
        in viewModel: TranslationsListViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let expected = TranslationItem(info: installed(translation, version: version), progress: .notDownloading)
        await waitUntil(file: file, line: line) {
            self.item(translation, in: viewModel) == expected
        }
    }

    private func isDownloading(_ item: TranslationItem) -> Bool {
        if case .downloading = item.progress {
            return true
        }
        return false
    }

    private func item(_ translation: Translation, in viewModel: TranslationsListViewModel) -> TranslationItem? {
        let items = viewModel.selectedTranslations + viewModel.downloadedTranslations + viewModel.availableTranslations
        return items.first { $0.id == translation.id }
    }

    private func installed(_ translation: Translation, version: Int?) -> Translation {
        var translation = translation
        translation.installedVersion = version
        return translation
    }

    private func databaseURL(textVersion: Int) throws -> URL {
        let resource = try XCTUnwrap(Self.databaseResources[textVersion])
        return TestResources.resourceURL(resource)
    }

    private func waitUntil(
        timeout: TimeInterval = 30,
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
