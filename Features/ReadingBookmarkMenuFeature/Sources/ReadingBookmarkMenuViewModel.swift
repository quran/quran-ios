#if QURAN_SYNC
import AnnotationsService
import Combine
import Crashing
import NoorUI
import QuranAnnotations
import QuranKit

@MainActor
final class ReadingBookmarkMenuViewModel: ObservableObject {
    enum Target {
        case pages([Page])
        case ayah(AyahNumber)

        var location: ReadingPositionBookmark.Location? {
            switch self {
            case .pages(let pages):
                pages.min().map(ReadingPositionBookmark.Location.page)
            case .ayah(let ayah):
                .ayah(ayah)
            }
        }

        var quran: Quran? {
            switch self {
            case .pages(let pages):
                pages.first?.quran
            case .ayah(let ayah):
                ayah.quran
            }
        }

        var unavailableSubtitle: MultipartText {
            .text("Reading position unavailable")
        }
    }

    struct Item: Identifiable {
        let slot: ReadingBookmarkSlot
        let subtitle: MultipartText
        let isCurrent: Bool
        let isEnabled: Bool

        var id: ReadingBookmarkSlot { slot }
    }

    // MARK: Lifecycle

    init(service: MobileSyncReadingBookmarkService, target: Target) {
        self.service = service
        self.target = target
        items = Self.makeItems(
            bookmarks: [],
            target: target,
            isLoading: true,
            isMutating: false
        )
    }

    // MARK: Internal

    @Published private(set) var items: [Item]
    @Published var error: Error?

    func start() async {
        guard target.location != nil, let quran = target.quran else {
            isLoading = false
            refreshItems()
            return
        }

        do {
            for try await bookmarks in service.readingBookmarksSequence(quran: quran) {
                self.bookmarks = bookmarks
                isLoading = false
                refreshItems()
            }
        } catch is CancellationError {
        } catch {
            isLoading = false
            refreshItems()
            self.error = error
        }
    }

    func select(_ slot: ReadingBookmarkSlot) async -> Toast? {
        guard !isMutating, let location = target.location else {
            return nil
        }

        isMutating = true
        refreshItems()
        defer {
            isMutating = false
            refreshItems()
        }

        do {
            if let bookmark = bookmark(in: slot), bookmark.location == location {
                try await service.removeReadingBookmark(in: slot)
                bookmarks.removeAll { $0.slot == slot }
                return ReadingBookmarkUndoToast.removed(bookmark) { [service, target] in
                    Task { @MainActor in
                        await Self.undoRemoval(bookmark, service: service, target: target)
                    }
                }
            }

            let previousBookmark = bookmark(in: slot)
            let bookmark = try await service.addReadingBookmark(at: location, slot: slot)
            bookmarks.removeAll { $0.slot == slot }
            bookmarks.append(bookmark)

            if let previousBookmark {
                return ReadingBookmarkUndoToast.moved(
                    from: previousBookmark,
                    to: bookmark
                ) { [service, target] in
                    Task { @MainActor in
                        await Self.undoMove(
                            bookmark,
                            to: previousBookmark,
                            service: service,
                            target: target
                        )
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
    private let target: Target
    private var bookmarks: [ReadingPositionBookmark] = []
    private var isLoading = true
    private var isMutating = false

    private func bookmark(in slot: ReadingBookmarkSlot) -> ReadingPositionBookmark? {
        bookmarks.first { $0.slot == slot }
    }

    private func refreshItems() {
        items = Self.makeItems(
            bookmarks: bookmarks,
            target: target,
            isLoading: isLoading,
            isMutating: isMutating
        )
    }

    private static func makeItems(
        bookmarks: [ReadingPositionBookmark],
        target: Target,
        isLoading: Bool,
        isMutating: Bool
    ) -> [Item] {
        ReadingBookmarkSlot.allCases.map { slot in
            guard let location = target.location else {
                return Item(
                    slot: slot,
                    subtitle: target.unavailableSubtitle,
                    isCurrent: false,
                    isEnabled: false
                )
            }
            guard !isLoading else {
                return Item(
                    slot: slot,
                    subtitle: .text("Loading…"),
                    isCurrent: false,
                    isEnabled: false
                )
            }
            guard let bookmark = bookmarks.first(where: { $0.slot == slot }) else {
                return Item(
                    slot: slot,
                    subtitle: .text("Not placed — tap to set here"),
                    isCurrent: false,
                    isEnabled: !isMutating
                )
            }
            if bookmark.location == location {
                return Item(
                    slot: slot,
                    subtitle: .text("Saved here • Tap to remove"),
                    isCurrent: true,
                    isEnabled: !isMutating
                )
            }
            return Item(
                slot: slot,
                subtitle: "Move here from \(Self.location(of: bookmark))",
                isCurrent: false,
                isEnabled: !isMutating
            )
        }
    }

    private static func location(of bookmark: ReadingPositionBookmark) -> MultipartText {
        switch bookmark.location {
        case .ayah(let ayah):
            "\(ayah: ayah)"
        case .page(let page):
            .text(page.localizedName)
        }
    }

    private static func currentBookmarks(
        service: MobileSyncReadingBookmarkService,
        target: Target
    ) async throws -> [ReadingPositionBookmark] {
        guard let quran = target.quran else {
            return []
        }
        for try await bookmarks in service.readingBookmarksSequence(quran: quran) {
            return bookmarks
        }
        return []
    }

    private static func undoRemoval(
        _ bookmark: ReadingPositionBookmark,
        service: MobileSyncReadingBookmarkService,
        target: Target
    ) async {
        do {
            let bookmarks = try await currentBookmarks(service: service, target: target)
            guard !bookmarks.contains(where: { $0.slot == bookmark.slot }) else {
                return
            }
            try await service.addReadingBookmark(at: bookmark.location, slot: bookmark.slot)
        } catch {
            crasher.recordError(error, reason: "Failed to undo reading bookmark removal")
        }
    }

    private static func undoMove(
        _ movedBookmark: ReadingPositionBookmark,
        to previousBookmark: ReadingPositionBookmark,
        service: MobileSyncReadingBookmarkService,
        target: Target
    ) async {
        do {
            let bookmarks = try await currentBookmarks(service: service, target: target)
            guard bookmarks.first(where: { $0.slot == movedBookmark.slot }) == movedBookmark else {
                return
            }
            try await service.addReadingBookmark(
                at: previousBookmark.location,
                slot: previousBookmark.slot
            )
        } catch {
            crasher.recordError(error, reason: "Failed to undo reading bookmark move")
        }
    }
}
#endif
