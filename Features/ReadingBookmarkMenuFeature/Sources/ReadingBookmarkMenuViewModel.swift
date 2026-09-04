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
        let placement = target.placement
        refreshItems()
        defer {
            isMutating = false
            refreshItems()
        }

        do {
            let previousBookmark = bookmark(in: slot).flatMap(PlacedReadingBookmark.init)
            if let bookmark = previousBookmark, bookmark.placement == placement {
                let clearedBookmark = try await service.clearReadingBookmark(in: slot)
                bookmarks.removeAll { $0.slot == slot }
                bookmarks.append(clearedBookmark)
                return ReadingBookmarkUndoToast.removed(bookmark) {
                    Task { @MainActor in
                        await self.restore(bookmark)
                    }
                }
            }

            let bookmark = try await service.addReadingBookmark(at: placement, slot: slot)
            bookmarks.removeAll { $0.slot == slot }
            bookmarks.append(ReadingBookmark(bookmark))

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
    private let target: Target
    private var bookmarks: [ReadingBookmark] = []
    private var isLoading = true
    private var isMutating = false

    private func bookmark(in slot: ReadingBookmarkSlot) -> ReadingBookmark? {
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
        bookmarks: [ReadingBookmark],
        target: Target,
        isLoading: Bool,
        isMutating: Bool
    ) -> [Item] {
        if isLoading {
            return []
        }
        return ReadingBookmarkSlot.allCases.map { slot in
            let placement = target.placement
            guard let bookmark = bookmarks.first(where: { $0.slot == slot }).flatMap(PlacedReadingBookmark.init) else {
                return Item(
                    slot: slot,
                    subtitle: .text("Not placed yet"),
                    action: .setHere,
                    isCurrent: false,
                    isEnabled: !isMutating
                )
            }
            if bookmark.placement == placement {
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
                subtitle: "at \(Self.locationTitle(bookmark.placement))",
                action: .moveHere,
                isCurrent: false,
                isEnabled: !isMutating
            )
        }
    }

    private static func locationTitle(_ placement: PlacedReadingBookmark.Placement) -> MultipartText {
        switch placement {
        case .ayah(let ayah):
            "\(ayah: ayah, decorationHidden: true)"
        case .page(let page):
            .text(page.localizedName)
        }
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
