#if QURAN_SYNC
import Combine
import NoorUI
import QuranAnnotations
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
    @Published private(set) var isRemovingAllAyahs = false
    @Published var error: Error?
    @Published var isPresentingDeleteConfirmation = false
    @Published var nameAlert: CollectionNameAlert = .hidden
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
        logger.info("Bookmarks: select ayah set entry at \(ayah.nonLocalizedDescription)")
        navigateToAyah(ayah)
    }

    func removeAyah(_ ayah: AyahNumber) async {
        do {
            try await dataSource.removeAyahs([ayah])
        } catch {
            self.error = error
        }
    }

    /// Removes every ayah but keeps the collection, then leaves Edit mode.
    func removeAllAyahs() async {
        guard !isRemovingAllAyahs else {
            return
        }
        logger.info("Bookmarks: remove all ayah set entries")
        isRemovingAllAyahs = true
        defer { isRemovingAllAyahs = false }
        do {
            try await dataSource.removeAllAyahs()
            editMode = .inactive
        } catch {
            self.error = error
        }
    }

    func presentRename() {
        guard content.canRename else {
            return
        }
        pendingName = content.title
        nameAlert = .editing
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
        // The field starts with the displayed name, which is localized for Old Page Bookmarks: writing it back
        // unchanged would turn that collection into a user collection.
        guard name != content.title else {
            nameAlert = .hidden
            return
        }

        do {
            try await dataSource.rename(to: name)
            nameAlert = .hidden
        } catch {
            if let nameError = CollectionNameError(error) {
                logger.info("Bookmarks: collection name rejected. \(nameError.logDescription)")
                nameAlert = .rejected(nameError)
            } else {
                self.error = error
            }
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
