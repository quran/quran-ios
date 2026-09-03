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
        case pages(Page, [Page])
        case ayah(AyahNumber)

        var location: ReadingPositionBookmark.Location {
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

    struct Item: Identifiable {
        enum Action: Equatable {
            case remove
            case moveHere
            case setHere
        }

        let slot: ReadingBookmarkSlot
        let subtitle: MultipartText
        let action: Action
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
        do {
            for try await bookmarks in service.readingBookmarksSequence(quran: target.quran) {
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
        guard !isMutating else {
            return nil
        }

        isMutating = true
        let location = target.location
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
        if isLoading {
            return []
        }
        return ReadingBookmarkSlot.allCases.map { slot in
            let location = target.location
            guard let bookmark = bookmarks.first(where: { $0.slot == slot }) else {
                return Item(
                    slot: slot,
                    subtitle: .text("Not placed yet"),
                    action: .setHere,
                    isCurrent: false,
                    isEnabled: !isMutating
                )
            }
            if bookmark.location == location {
                return Item(
                    slot: slot,
                    subtitle: .text("Saved here"),
                    action: .remove,
                    isCurrent: true,
                    isEnabled: !isMutating
                )
            }
            return Item(
                slot: slot,
                subtitle: "at \(Self.location(of: bookmark))",
                action: .moveHere,
                isCurrent: false,
                isEnabled: !isMutating
            )
        }
    }

    private static func location(of bookmark: ReadingPositionBookmark) -> MultipartText {
        switch bookmark.location {
        case .ayah(let ayah):
            "\(ayah: ayah, decorationHidden: true)"
        case .page(let page):
            .text(page.localizedName)
        }
    }

    // TODO: Fix
    private static func currentBookmarks(
        service: MobileSyncReadingBookmarkService,
        target: Target
    ) async throws -> [ReadingPositionBookmark] {
        for try await bookmarks in service.readingBookmarksSequence(quran: target.quran) {
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
