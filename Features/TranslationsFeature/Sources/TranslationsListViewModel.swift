//
//  TranslationsListViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-04.
//

import Analytics
import BatchDownloader
import Combine
import Crashing
import Foundation
import NoorUI
import QuranText
import SwiftUI
import TranslationService
import UIx
import Utilities
import VLogging

@MainActor
final class TranslationsListViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
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

        let downloadsObserver = DownloadsObserver(
            extractKey: { [weak self] in self?.translations.firstMatches($0)?.id },
            showError: { [weak self] error in self?.error = error }
        )
        self.downloadsObserver = downloadsObserver

        selectedTranslationsPreferences.$selectedTranslationIds
            .prepend(selectedTranslationsPreferences.selectedTranslationIds)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.selectedTranslationIds = $0 }
            .store(in: &cancellables)
    }

    // MARK: Internal

    @Published var editMode: EditMode = .inactive
    @Published var error: Error? = nil
    @Published var loading = true

    var selectedTranslations: [TranslationItem] {
        selectedTranslationIds
            .filter { !pendingDeletionIDs.contains($0) }
            .map { id in translations.first { $0.id == id } }
            .compactMap { $0.map(translationItem) }
    }

    var downloadedTranslations: [TranslationItem] {
        translations
            .filter {
                $0.isDownloaded &&
                    !selectedTranslationIds.contains($0.id) &&
                    !pendingDeletionIDs.contains($0.id)
            }
            .sorted()
            .map(translationItem)
    }

    var availableTranslations: [TranslationItem] {
        translations
            .filter { !$0.isDownloaded && !pendingDeletionIDs.contains($0.id) }
            .map(translationItem)
    }

    func start() async {
        async let downloads: () = observeRunningDownloads()
        async let progress: () = observeProgressChanges()
        async let translations: () = loadTranslations()
        _ = await [downloads, progress, translations]
    }

    func refresh() async {
        logger.info("Translations: userRequestedRefresh")
        do {
            try await loadFromServer()
        } catch {
            self.error = error
        }
    }

    func moveSelectedTranslations(at indexSet: IndexSet, to destination: Int) {
        selectedTranslationsPreferences.selectedTranslationIds.move(fromOffsets: indexSet, toOffset: destination)
    }

    func selectTranslation(_ translation: TranslationItem) async {
        selectedTranslationsPreferences.select(translation.id)
        logger.info("Translations: translation \(translation.id) selected")
    }

    func deselectTranslation(_ translation: TranslationItem) async {
        selectedTranslationsPreferences.deselect(translation.id)
        logger.info("Translations: translation \(translation.id) deselected")
    }

    func startDownloading(_ item: TranslationItem) async {
        let translation = item.info
        logger.info("Translations: start downloading translation \(translation.id)")
        analytics.downloading(translation: translation)
        downloadStarted(translation)
        progress[translation.id] = 0

        do {
            let response = try await downloader.download(translation)
            await downloadsObserver?.observe([response])
        } catch {
            progress.removeValue(forKey: translation.id)
            newDownloadIDs.remove(translation.id)
            crasher.recordError(error, reason: "Failed to start the translation download")
            self.error = error
        }
    }

    func cancelDownloading(_ item: TranslationItem) async {
        let translation = item.info
        logger.info("Translations: cancel downloading \(translation.id)")
        let download = downloadsObserver?.runningDownloads.firstMatches(translation)
        await download?.cancel()
    }

    func deleteTranslation(_ item: TranslationItem) -> AsyncAction? {
        guard pendingDeletionIDs.insert(item.id).inserted else {
            return nil
        }
        guard let index = translations.firstIndex(of: item.info) else {
            pendingDeletionIDs.remove(item.id)
            return nil
        }

        logger.info("Translations: deleting translation \(item.id)")
        analytics.deleting(translation: item.info)
        let translation = translations.remove(at: index)

        return { [weak self] in
            guard let self else { return }
            await cancelDownloading(item)

            do {
                let updatedTranslation = try await deleter.deleteTranslation(item.info)
                restoreTranslation(updatedTranslation, at: index)
            } catch {
                restoreTranslation(translation, at: index)
                crasher.recordError(error, reason: "Failed to delete translation \(item.id)")
                self.error = error
            }
            pendingDeletionIDs.remove(item.id)
        }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let translationsRepository: TranslationsRepository
    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let deleter: TranslationDeleter
    private let downloader: TranslationsDownloader
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    private var downloadsObserver: DownloadsObserver<Translation.ID>?
    private var cancellables = Set<AnyCancellable>()
    private var pendingDeletionIDs: Set<Translation.ID> = []
    /// Downloads of translations that weren't downloaded when the download started.
    private var newDownloadIDs: Set<Translation.ID> = []

    @Published private var translations: [Translation] = []
    @Published private var selectedTranslationIds: [Translation.ID] = []
    @Published private var progress: [Translation.ID: Double] = [:]

    private func restoreTranslation(_ translation: Translation, at index: Int) {
        translations.removeAll { $0.id == translation.id }
        translations.insert(translation, at: min(index, translations.endIndex))
    }

    private func translationItem(_ translation: Translation) -> TranslationItem {
        let itemProgress: TranslationItem.DownloadingProgress = if let progress = progress[translation.id] {
            .downloading(progress)
        } else if translation.needsUpgrade {
            .needsUpgrade
        } else {
            .notDownloading
        }
        return TranslationItem(info: translation, progress: itemProgress)
    }

    private func loadTranslations() async {
        do {
            try await loadLocalTranslations()
            try await loadFromServer()
        } catch {
            self.error = error
        }
        withAnimation(NoorAnimation.standard) {
            loading = false
        }
    }

    private func loadLocalTranslations() async throws {
        let translations = try await localTranslationsRetriever.getLocalTranslations()
        self.translations = translations
    }

    private func loadFromServer() async throws {
        try await translationsRepository.downloadAndSyncTranslations()
        try await loadLocalTranslations()
    }

    private func observeRunningDownloads() async {
        let responses = await downloader.runningTranslationDownloads()
        await downloadsObserver?.observe(Set(responses))
    }

    private func observeProgressChanges() async {
        guard let downloadsObserver else {
            return
        }
        for await newValue in downloadsObserver.progressPublisher.values() {
            let oldValue = progress

            let newKeys = Set(newValue.keys)
            let oldKeys = Set(oldValue.keys)
            // Downloads not started by `startDownloading`, such as ones already running when the list opened.
            for id in newKeys.subtracting(oldKeys) {
                if let translation = translations.first(where: { $0.id == id }) {
                    downloadStarted(translation)
                }
            }
            // Downloads that ended, whether they completed, failed, or were cancelled.
            let endedDownloads = oldKeys.subtracting(newKeys)
            if !endedDownloads.isEmpty {
                let endedNewDownloads = newDownloadIDs.intersection(endedDownloads)
                newDownloadIDs.subtract(endedDownloads)
                do {
                    try await loadLocalTranslations()
                    selectNewlyInstalledTranslations(endedNewDownloads)
                } catch {
                    crasher.recordError(error, reason: "Failed to reload local translations")
                    self.error = error
                }
            }

            progress = newValue
        }
    }

    private func downloadStarted(_ translation: Translation) {
        if translation.isDownloaded {
            newDownloadIDs.remove(translation.id)
        } else {
            newDownloadIDs.insert(translation.id)
        }
    }

    /// Selects the translations that ended new downloads installed.
    ///
    /// A failed or cancelled download leaves its translation not downloaded, and an upgrade
    /// isn't a new download, so neither changes the selection.
    private func selectNewlyInstalledTranslations(_ endedNewDownloads: Set<Translation.ID>) {
        let installed = translations.filter { endedNewDownloads.contains($0.id) && $0.isDownloaded }
        for translation in installed {
            selectedTranslationsPreferences.select(translation.id)
        }
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
