#if QURAN_SYNC
import Combine
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import SwiftUI
import VLogging

@MainActor
final class AyahSetViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        dataSource: any AyahSetDataSource,
        quranTextDataService: QuranTextDataService,
        navigateToAyah: @escaping (AyahNumber) -> Void,
        dataSourceDeleted: @escaping () -> Void
    ) {
        self.dataSource = dataSource
        content = dataSource.initialContent
        self.quranTextDataService = quranTextDataService
        reading = ReadingPreferences.shared.reading
        self.navigateToAyah = navigateToAyah
        self.dataSourceDeleted = dataSourceDeleted
        readingPreferences.$reading
            .assign(to: &$reading)
    }

    // MARK: Internal

    @Published private(set) var content: AyahSetContent
    @Published private(set) var ayahTexts: [AyahNumber: QuranText] = [:]
    @Published private(set) var reading: Reading
    @Published var editMode: EditMode = .inactive
    @Published var error: Error?
    @Published var isPresentingDeleteConfirmation = false
    @Published var isPresentingRename = false
    @Published var pendingName = ""

    func start() async {
        do {
            try await loadAyahTexts(for: content.ayahs)
            for try await content in dataSource.contentSequence() {
                self.content = content
                try await loadAyahTexts(for: content.ayahs)
            }
        } catch is CancellationError {
            return
        } catch {
            self.error = error
        }
    }

    func navigateTo(_ ayah: AyahNumber) {
        logger.info("Bookmarks: select ayah set entry at \(ayah)")
        navigateToAyah(ayah)
    }

    func removeAyah(_ ayah: AyahNumber) async {
        do {
            try await dataSource.removeAyah(ayah)
        } catch {
            self.error = error
        }
    }

    func presentRename() {
        guard content.canRename else {
            return
        }
        pendingName = content.title
        isPresentingRename = true
    }

    func renamePending() async {
        guard content.canRename,
              let dataSource = dataSource as? any ManageableAyahSetDataSource
        else {
            return
        }
        let name = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }

        do {
            try await dataSource.rename(to: name)
        } catch {
            self.error = error
        }
    }

    func requestDelete() async {
        guard content.canDelete else {
            return
        }
        guard !content.ayahs.isEmpty else {
            await deleteDataSource()
            return
        }
        isPresentingDeleteConfirmation = true
    }

    func deleteDataSource() async {
        guard content.canDelete,
              let dataSource = dataSource as? any ManageableAyahSetDataSource
        else {
            return
        }
        do {
            try await dataSource.delete()
            dataSourceDeleted()
        } catch {
            self.error = error
        }
    }

    // MARK: Private

    private let dataSource: any AyahSetDataSource
    private let quranTextDataService: QuranTextDataService
    private let readingPreferences = ReadingPreferences.shared
    private let navigateToAyah: (AyahNumber) -> Void
    private let dataSourceDeleted: () -> Void

    private func loadAyahTexts(for ayahs: [AyahNumber]) async throws {
        guard !ayahs.isEmpty else {
            ayahTexts = [:]
            return
        }
        guard Set(ayahTexts.keys) != Set(ayahs) else {
            return
        }
        ayahTexts = try await quranTextDataService
            .textForVerses(ayahs, translations: [])
            .mapValues(\.arabicText)
    }
}
#endif
