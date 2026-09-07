#if QURAN_SYNC
import AnnotationsService
import Combine
import Crashing
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI

@MainActor
final class ReadingBookmarkMenuViewModel: ObservableObject {
    struct Item: Identifiable {
        let slot: ReadingBookmarkSlot
        let name: String?
        let placement: ReadingBookmark.Placement

        var id: ReadingBookmarkSlot { slot }
    }

    enum Target {
        case pages(Page, [Page])
        case ayah(AyahNumber)

        var placement: PlacedReadingBookmark.Placement {
            switch self {
            case .pages(let page, _):
                .page(page)
            case .ayah(let ayah):
                .ayah(ayah)
            }
        }

        var quran: Quran {
            switch self {
            case .pages(let page, _):
                page.quran
            case .ayah(let ayah):
                ayah.quran
            }
        }
    }

    // MARK: Lifecycle

    init(service: MobileSyncReadingBookmarkService, target: Target) {
        self.service = service
        self.target = target
    }

    // MARK: Internal

    let target: Target
    @Published var error: Error?
    @Published var draftNames: [ReadingBookmarkSlot: String] = [:]
    @Published private(set) var editMode: EditMode = .inactive

    var items: [Item] {
        if isLoading {
            return []
        }
        return ReadingBookmarkSlot.allCases.map { slot in
            let bookmark = bookmark(in: slot)
            return Item(
                slot: slot,
                name: bookmark?.name,
                placement: bookmark?.placement ?? .unplaced
            )
        }
    }

    var editModeBinding: Binding<EditMode> {
        Binding(
            get: { self.editMode },
            set: { mode in
                if mode.isEditing {
                    self.beginEditing()
                } else {
                    Task { @MainActor in
                        await self.finishEditing()
                    }
                }
            }
        )
    }

    func beginEditing() {
        draftNames = [:]
        editMode = .active
    }

    func finishEditing() async {
        if await saveNames(in: ReadingBookmarkSlot.allCases) {
            editMode = .inactive
        }
    }

    func saveNames(in slots: [ReadingBookmarkSlot]) async -> Bool {
        guard !isLoading, !isMutating else { return false }
        isMutating = true
        defer {
            isMutating = false
        }

        do {
            for slot in slots {
                guard let draft = draftNames[slot] else { continue }
                let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                if name != (bookmark(in: slot)?.name ?? "") {
                    let renamed = try await service.renameReadingBookmark(
                        in: slot,
                        name: name.isEmpty ? nil : name,
                        quran: target.quran
                    )
                    storedBookmarks.removeAll { $0.slot == slot }
                    storedBookmarks.append(renamed)
                }
                draftNames.removeValue(forKey: slot)
            }
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.error = error
            return false
        }
    }

    func start() async {
        do {
            for try await bookmarks in service.readingBookmarksSequence(quran: target.quran) {
                storedBookmarks = bookmarks
                isLoading = false
            }
        } catch is CancellationError {
        } catch {
            isLoading = false
            self.error = error
        }
    }

    func select(_ slot: ReadingBookmarkSlot) async -> Toast? {
        guard !isMutating else {
            return nil
        }

        isMutating = true
        let placement = target.placement
        defer {
            isMutating = false
        }

        do {
            let previousBookmark = bookmark(in: slot).flatMap(PlacedReadingBookmark.init)
            if let bookmark = previousBookmark, bookmark.placement == placement {
                let clearedBookmark = try await service.clearReadingBookmark(in: slot)
                storedBookmarks.removeAll { $0.slot == slot }
                storedBookmarks.append(clearedBookmark)
                return ReadingBookmarkUndoToast.removed(bookmark) {
                    Task { @MainActor in
                        await self.restore(bookmark)
                    }
                }
            }

            let bookmark = try await service.addReadingBookmark(at: placement, slot: slot)
            storedBookmarks.removeAll { $0.slot == slot }
            storedBookmarks.append(ReadingBookmark(bookmark))

            if let previousBookmark {
                return ReadingBookmarkUndoToast.moved(
                    from: previousBookmark,
                    to: bookmark
                ) {
                    Task { @MainActor in
                        await self.restore(previousBookmark)
                    }
                }
            }
            return ReadingBookmarkUndoToast.saved(bookmark)
        } catch is CancellationError {
            return nil
        } catch {
            self.error = error
            return nil
        }
    }

    // MARK: Private

    private let service: MobileSyncReadingBookmarkService
    @Published private var storedBookmarks: [ReadingBookmark] = []
    @Published private var isLoading = true
    @Published private(set) var isMutating = false

    private func bookmark(in slot: ReadingBookmarkSlot) -> ReadingBookmark? {
        storedBookmarks.first { $0.slot == slot }
    }

    private func restore(_ bookmark: PlacedReadingBookmark) async {
        do {
            try await service.addReadingBookmark(at: bookmark.placement, slot: bookmark.slot)
        } catch {
            crasher.recordError(error, reason: "Failed to restore reading bookmark")
        }
    }
}
#endif
