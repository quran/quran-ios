//
//  BookmarkAyahsViewModel.swift
//

import AnnotationsService
import Combine
import Foundation
import Localization
import QuranAnnotations
import QuranKit
import ReadingService
import VLogging

#if QURAN_SYNC
@MainActor
final class BookmarkAyahsViewModel: ObservableObject {
    enum HighlightSelection: Equatable {
        case none
        case mixed(Set<HighlightColor>)
        case color(HighlightColor)
    }

    enum CollectionSelection: Equatable {
        case unselected
        case mixed
        case selected
    }

    // MARK: Lifecycle

    init(
        verses: [AyahNumber],
        collections: [AyahBookmarkCollection],
        ayahBookmarkCollectionService: AyahBookmarkCollectionService
    ) {
        self.verses = Self.unique(verses)
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        updateCollections(collections)
    }

    // MARK: Internal

    @Published private(set) var collections: [AyahBookmarkCollection] = []
    @Published private(set) var collectionSelections: [String: CollectionSelection] = [:]
    @Published private(set) var highlightSelection: HighlightSelection = .none
    @Published private(set) var isUpdatingHighlight = false
    @Published private(set) var updatingCollectionIDs: Set<String> = []
    @Published var error: Error?
    @Published var isPresentingAddCollection = false
    @Published var newCollectionName = ""

    var title: String {
        lFormat("bookmarks.editor.title", verses.count)
    }

    var displayedCollections: [AyahBookmarkCollection] {
        BookmarkCollectionsViewModel.displayedCollections(from: collections)
    }

    var selectedHighlightColor: HighlightColor? {
        guard case .color(let color) = highlightSelection else {
            return nil
        }
        return color
    }

    var partiallySelectedHighlightColors: Set<HighlightColor> {
        guard case .mixed(let colors) = highlightSelection else {
            return []
        }
        return colors
    }

    func start() async {
        do {
            for try await collections in ayahBookmarkCollectionService.collectionsSequence() {
                updateCollections(collections)
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            self.error = error
        }
    }

    func selectHighlight(_ color: HighlightColor?) async {
        let selection = color.map(HighlightSelection.color) ?? .none
        guard selection != highlightSelection, !isUpdatingHighlight else {
            return
        }

        let previousSelection = highlightSelection
        highlightSelection = selection
        isUpdatingHighlight = true
        defer { isUpdatingHighlight = false }

        do {
            try await ayahBookmarkCollectionService.setHighlight(color, for: verses)
            if let color {
                HighlightPreferences.shared.lastUsedHighlightColor = color
            }
        } catch is CancellationError {
            highlightSelection = previousSelection
        } catch {
            logger.error("Bookmarks: failed to update highlight: \(error)")
            highlightSelection = previousSelection
            self.error = error
        }
    }

    func collectionSelection(for collection: AyahBookmarkCollection) -> CollectionSelection {
        collectionSelections[collection.collection.id] ?? .unselected
    }

    func toggleCollection(_ collection: AyahBookmarkCollection) async {
        let id = collection.collection.id
        guard !updatingCollectionIDs.contains(id) else {
            return
        }

        let previousSelection = collectionSelection(for: collection)
        let selection: CollectionSelection = switch previousSelection {
        case .selected:
            .unselected
        case .mixed, .unselected:
            .selected
        }
        collectionSelections[id] = selection
        updatingCollectionIDs.insert(id)
        defer { updatingCollectionIDs.remove(id) }

        do {
            switch selection {
            case .mixed:
                return
            case .selected:
                try await ayahBookmarkCollectionService.addAyahs(verses, toCollectionWithID: id)
            case .unselected:
                try await ayahBookmarkCollectionService.removeAyahs(verses, fromCollectionWithID: id)
            }
        } catch is CancellationError {
            collectionSelections[id] = previousSelection
        } catch {
            logger.error("Bookmarks: failed to update collection: \(error)")
            collectionSelections[id] = previousSelection
            self.error = error
        }
    }

    func isUpdatingCollection(_ collection: AyahBookmarkCollection) -> Bool {
        updatingCollectionIDs.contains(collection.collection.id)
    }

    func presentAddCollection() {
        newCollectionName = ""
        isPresentingAddCollection = true
    }

    func createPendingCollection() async {
        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }

        do {
            try await ayahBookmarkCollectionService.createCollection(named: name)
            newCollectionName = ""
            isPresentingAddCollection = false
        } catch {
            self.error = error
        }
    }

    // MARK: Private

    private let verses: [AyahNumber]
    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService

    private func updateCollections(_ collections: [AyahBookmarkCollection]) {
        let collections = BookmarkCollectionsViewModel.sorted(collections)
        self.collections = collections

        if !isUpdatingHighlight {
            highlightSelection = Self.highlightSelection(for: verses, in: collections)
        }

        let displayedCollections = BookmarkCollectionsViewModel.displayedCollections(from: collections)
        let displayedCollectionIDs = Set(displayedCollections.map(\.collection.id))
        collectionSelections = collectionSelections.filter { displayedCollectionIDs.contains($0.key) }

        for collection in displayedCollections {
            let id = collection.collection.id
            if !updatingCollectionIDs.contains(id) {
                collectionSelections[id] = Self.collectionSelection(for: verses, in: collection)
            }
        }
    }

    private static func highlightSelection(
        for verses: [AyahNumber],
        in collections: [AyahBookmarkCollection]
    ) -> HighlightSelection {
        let coloredCollections = collections.filter { $0.kind.highlightColor != nil }
        let colors = verses.map { ayah in
            coloredCollections.first { collection in
                collection.bookmarks.contains { $0.ayah == ayah }
            }?.kind.highlightColor
        }

        guard let firstColor = colors.first else {
            return .none
        }
        guard colors.dropFirst().allSatisfy({ $0 == firstColor }) else {
            return .mixed(Set(colors.compactMap { $0 }))
        }
        if let firstColor {
            return .color(firstColor)
        }
        return .none
    }

    private static func collectionSelection(
        for verses: [AyahNumber],
        in collection: AyahBookmarkCollection
    ) -> CollectionSelection {
        let selectedVerses = Set(verses)
        let bookmarkedVerses = Set(collection.bookmarks.map(\.ayah))
        let intersectionCount = selectedVerses.intersection(bookmarkedVerses).count

        if intersectionCount == 0 {
            return .unselected
        }
        if intersectionCount == selectedVerses.count {
            return .selected
        }
        return .mixed
    }

    private static func unique(_ verses: [AyahNumber]) -> [AyahNumber] {
        var seen = Set<AyahNumber>()
        return verses.filter { seen.insert($0).inserted }
    }
}
#else
@MainActor
final class BookmarkAyahsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        verses: [AyahNumber],
        notes: [QuranAnnotations.Note],
        noteService: NoteService
    ) {
        self.verses = verses
        self.noteService = noteService
        selectedHighlightColor = noteService.color(from: notes)
    }

    // MARK: Internal

    @Published private(set) var isUpdatingHighlight = false
    @Published var error: Error?
    @Published private(set) var selectedHighlightColor: HighlightColor

    var title: String {
        lFormat("bookmarks.editor.title", verses.count)
    }

    func selectHighlight(_ color: HighlightColor?) async {
        guard let color, color != selectedHighlightColor, !isUpdatingHighlight else {
            return
        }

        let previousColor = selectedHighlightColor
        selectedHighlightColor = color
        isUpdatingHighlight = true
        defer { isUpdatingHighlight = false }

        do {
            _ = try await noteService.updateHighlight(
                verses: verses,
                color: color,
                quran: ReadingPreferences.shared.reading.quran
            )
        } catch is CancellationError {
            selectedHighlightColor = previousColor
        } catch {
            logger.error("Bookmarks: failed to update highlight: \(error)")
            selectedHighlightColor = previousColor
            self.error = error
        }
    }

    // MARK: Private

    private let verses: [AyahNumber]
    private let noteService: NoteService
}
#endif
