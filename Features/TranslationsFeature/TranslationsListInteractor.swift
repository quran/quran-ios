//
//  TranslationsListInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Analytics
import BatchDownloader
import Combine
import Crashing
import NoorUI
import QuranText
import TranslationService
import Utilities
import VLogging

@MainActor
protocol TranslationsListPresentable: AnyObject {
    var translations: [TranslationInfo.ID: TranslationItem] { get set }

    func showErrorAlert(error: Error)
    func showActivityIndicator()
    func hideActivityIndicator()
}

// MARK: - Interactor

@MainActor
final class TranslationsListInteractor {
    // MARK: Lifecycle

    nonisolated init(
        analytics: AnalyticsLibrary,
        translationsRepository: TranslationsRepository,
        localTranslationsRetriever: LocalTranslationsRetriever,
        deleter: TranslationDeleter,
        downloader: TranslationsDownloader
    ) {
        self.analytics = analytics
        self.translationsRepository = translationsRepository
        self.localTranslationsRetriever = localTranslationsRetriever
        self.deleter = deleter
        self.downloader = downloader
    }

    // MARK: Internal

    weak var presenter: TranslationsListPresentable?

    // MARK: - Start

    func start() async {
        selectedTranslationsPreferences.$selectedTranslations.sink { [weak self] _ in
            Task {
                await self?.dataChanged()
            }
        }
        .store(in: &cancellables)
        let responses = await downloader.runningTranslationDownloads()
        await observe(Set(responses))

        // get new data
        presenter?.showActivityIndicator()
        do {
            try await loadLocalTranslations()
            try await loadFromServer()
        } catch {
            presenter?.showErrorAlert(error: error)
        }
        presenter?.hideActivityIndicator()
    }

    func userRequestedRefresh() async {
        logger.info("Translations: userRequestedRefresh")
        presenter?.showActivityIndicator()
        do {
            try await loadFromServer()
        } catch {
            presenter?.showErrorAlert(error: error)
        }
        presenter?.hideActivityIndicator()
    }

    // MARK: - Actions

    func selectTranslation(_ translationId: TranslationInfo.ID) async {
        selectedTranslationsPreferences.toggleSelection(translationId)
        let selectionText = selectedTranslationsPreferences.isSelected(translationId) ? "selected" : "not selected"
        logger.info("Translations: translation \(translationId) \(selectionText)")
    }

    func startDownloading(_ id: TranslationInfo.ID) async {
        guard let translation = translations.first(where: { $0.id == id }) else {
            return
        }

        analytics.downloading(translation: translation)
        do {
            let response = try await downloader.download(translation)
            await observe([response])
        } catch {
            crasher.recordError(error, reason: "Failed to start the translation download")
            showError(error)
        }
    }

    func cancelDownloading(_ translationId: TranslationInfo.ID) async {
        logger.info("Translations: cancel downloading \(translationId)")
        if let translation = translations.first(where: { $0.id == translationId }) {
            let download = await runningDownload(of: translation)
            await download?.cancel()
        }
    }

    func deleteTranslation(_ id: TranslationInfo.ID) async {
        guard let translation = translations.first(where: { $0.id == id }) else {
            return
        }
        analytics.deleting(translation: translation)
        await cancelDownloading(id)

        do {
            let updatedTranslation = try await deleter.deleteTranslation(translation)
            // replace existing translation
            if let index = translations.firstIndex(of: translation) {
                translations[index] = updatedTranslation
            }
        } catch {
            presenter?.showErrorAlert(error: error)
        }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let translationsRepository: TranslationsRepository
    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let deleter: TranslationDeleter
    private let downloader: TranslationsDownloader
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared

    private var cancellables = Set<AnyCancellable>()
    private var cancellableTasks = Set<CancellableTask>()

    private var translations: [Translation] = [] {
        didSet {
            Task {
                await self.dataChanged()
            }
        }
    }

    private var runningDownloads: Set<DownloadBatchResponse> = [] {
        didSet {
            Task {
                await self.dataChanged()
            }
        }
    }

    private func loadFromServer() async throws {
        try await translationsRepository.downloadAndSyncTranslations()
        try await loadLocalTranslations()
    }

    private func syncLocally() async {
        do {
            try await loadLocalTranslations()
        } catch {
            presenter?.showErrorAlert(error: error)
        }
    }

    // MARK: - Updates

    private func downloadState(_ translation: Translation, response: DownloadBatchResponse?) async -> DownloadState {
        if let response = await runningDownload(of: translation) {
            let progress = await Float(response.currentProgress.progress)
            if translation.isDownloaded {
                return progress < 0.001 ? .pendingUpgrading : .downloadingUpgrade(progress: progress)
            } else {
                return progress < 0.001 ? .pendingDownloading : .downloading(progress: progress)
            }
        } else {
            if translation.isDownloaded {
                return translation.needsUpgrade ? .needsUpgrade : .downloaded
            } else {
                return .notDownloaded
            }
        }
    }

    private func translationUI(_ translation: Translation) async -> TranslationItem {
        let response = await runningDownload(of: translation)
        return await TranslationItem(
            info: TranslationInfo(
                id: translation.id,
                displayName: translation.displayName,
                languageCode: translation.languageCode,
                translator: translation.translatorForeign ?? translation.translator
            ),
            isDownloaded: translation.isDownloaded,
            downloadState: downloadState(translation, response: response),
            isSelected: selectedTranslationsPreferences.isSelected(translation.id)
        )
    }

    private func loadLocalTranslations() async throws {
        let translations = try await localTranslationsRetriever.getLocalTranslations()
        self.translations = translations
    }

    private func dataChanged() async {
        presenter?.translations = await Dictionary(uniqueKeysWithValues: translations.asyncMap { await ($0.id, translationUI($0)) })
    }

    private func progressUpdated(of batch: DownloadBatchResponse) async {
        await dataChanged()
    }

    private func showError(_ error: Error) {
        presenter?.showErrorAlert(error: error)
    }

    // MARK: - Download observers

    private func observe(_ downloads: Set<DownloadBatchResponse>) async {
        runningDownloads.formUnion(downloads)

        for download in downloads {
            cancellableTasks.insert(
                Task { [weak self] in
                    for await _ in await download.progress {
                        await self?.progressUpdated(of: download)
                    }
                }.asCancellableTask()
            )
            cancellableTasks.insert(
                Task { [weak self] in
                    do {
                        try await download.completion()
                        await self?.syncLocally()
                    } catch {
                        self?.showError(error)
                    }
                    self?.runningDownloads.remove(download)
                }.asCancellableTask()
            )
        }
    }

    private func runningDownload(of translation: Translation) async -> DownloadBatchResponse? {
        await runningDownloads.firstMatches(translation)
    }

    private func translation(of batch: DownloadBatchResponse) async -> Translation? {
        await translations.firstMatches(batch)
    }
}

private extension AnalyticsLibrary {
    func downloading(translation: Translation) {
        logEvent("TranslationsDownloadingId", value: translation.id.description)
        logEvent("TranslationsDownloadingName", value: translation.displayName)
        logEvent("TranslationsDownloadingLanguage", value: translation.languageCode)
    }

    func deleting(translation: Translation) {
        logEvent("TranslationsDeletionId", value: translation.id.description)
        logEvent("TranslationsDeletionName", value: translation.displayName)
        logEvent("TranslationsDeletionLanguage", value: translation.languageCode)
    }
}
