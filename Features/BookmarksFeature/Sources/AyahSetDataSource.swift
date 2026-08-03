#if QURAN_SYNC
import AnnotationsService
import QuranAnnotations
import QuranKit
import Utilities

struct AyahSetContent {
    let title: String
    let ayahs: [AyahNumber]
    let canRename: Bool
    let canDelete: Bool
}

@MainActor
protocol AyahSetDataSource {
    var initialContent: AyahSetContent { get }

    func contentSequence() -> AnyAsyncSequence<AyahSetContent>
    func removeAyah(_ ayah: AyahNumber) async throws
}

@MainActor
protocol ManageableAyahSetDataSource: AyahSetDataSource {
    func rename(to name: String) async throws
    func delete() async throws
}

struct BookmarkCollectionAyahSetDataSource: ManageableAyahSetDataSource {
    init(collection: AyahBookmarkCollection, service: AyahBookmarkCollectionService) {
        collectionID = collection.collection.id
        initialContent = Self.content(collection)
        self.service = service
    }

    let initialContent: AyahSetContent

    func contentSequence() -> AnyAsyncSequence<AyahSetContent> {
        let collectionID = collectionID
        let initialContent = initialContent
        return .init(
            service.collectionsSequence()
                .map { collections in
                    guard let collection = collections.first(where: { $0.collection.id == collectionID }) else {
                        return initialContent
                    }
                    return Self.content(collection)
                }
        )
    }

    func removeAyah(_ ayah: AyahNumber) async throws {
        try await service.removeAyahs([ayah], fromCollectionWithID: collectionID)
    }

    func rename(to name: String) async throws {
        try await service.renameCollection(id: collectionID, to: name)
    }

    func delete() async throws {
        try await service.removeCollection(id: collectionID)
    }

    private let collectionID: String
    private let service: AyahBookmarkCollectionService

    private nonisolated static func content(_ collection: AyahBookmarkCollection) -> AyahSetContent {
        AyahSetContent(
            title: collection.displayName,
            ayahs: collection.bookmarks.map(\.ayah),
            canRename: collection.kind.canRename,
            canDelete: collection.kind.canDelete
        )
    }
}

struct HighlightAyahSetDataSource: AyahSetDataSource {
    init(
        color: HighlightColor,
        initialAyahs: [AyahNumber],
        service: MobileSyncAyahHighlightService
    ) {
        self.color = color
        initialContent = Self.content(color: color, ayahs: initialAyahs)
        self.service = service
    }

    let initialContent: AyahSetContent

    func contentSequence() -> AnyAsyncSequence<AyahSetContent> {
        let color = color
        return .init(
            service.highlightsSequence()
                .map { highlights in
                    let ayahs = highlights
                        .filter { $0.value == color }
                        .map(\.key)
                    return Self.content(color: color, ayahs: ayahs)
                }
        )
    }

    func removeAyah(_ ayah: AyahNumber) async throws {
        try await service.removeHighlight(for: [ayah])
    }

    private let color: HighlightColor
    private let service: MobileSyncAyahHighlightService

    private nonisolated static func content(color: HighlightColor, ayahs: [AyahNumber]) -> AyahSetContent {
        AyahSetContent(
            title: color.localizedName,
            ayahs: ayahs.sorted(),
            canRename: false,
            canDelete: false
        )
    }
}
#endif
