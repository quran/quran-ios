#if QURAN_SYNC
//
//  BookmarkAyahsViewModel.swift
//

import Analytics
import AnnotationsService
import Combine
import Foundation
import QuranAnnotations
import QuranKit
import VLogging

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
        highlights: [AyahNumber: HighlightColor] = [:],
        analytics: AnalyticsLibrary,
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        ayahHighlightService: MobileSyncAyahHighlightService
    ) {
        self.verses = Self.unique(verses)
        self.analytics = analytics
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.ayahHighlightService = ayahHighlightService
        updateCollections(collections)
        highlightSelection = Self.highlightSelection(for: self.verses, in: highlights)
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

    let verses: [AyahNumber]

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
        async let observeCollections: Void = observeCollections()
        async let observeHighlights: Void = observeHighlights()
        _ = await (observeCollections, observeHighlights)
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
            if let color {
                try await ayahHighlightService.setHighlight(color, for: verses)
                analytics.highlight(verses: verses)
                HighlightPreferences.shared.lastUsedHighlightColor = color
            } else {
                try await ayahHighlightService.removeHighlight(for: verses)
                analytics.unhighlight(verses: verses)
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
            logger.info("Quran Sync: updated bookmark collection membership for \(verses.count) ayah(s)")
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
            logger.error("Quran Sync: failed to create bookmark collection: \(error)")
            self.error = error
        }
    }

    // MARK: Private

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let ayahHighlightService: MobileSyncAyahHighlightService
    private let analytics: AnalyticsLibrary

    private func updateCollections(_ collections: [AyahBookmarkCollection]) {
        let collections = BookmarkCollectionsViewModel.sorted(collections)
        self.collections = collections

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
        in highlights: [AyahNumber: HighlightColor]
    ) -> HighlightSelection {
        let colors = verses.map { highlights[$0] }

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

    private func observeCollections() async {
        do {
            for try await collections in ayahBookmarkCollectionService.collectionsSequence() {
                updateCollections(collections)
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe collections in bookmark editor: \(error)")
            self.error = error
        }
    }

    private func observeHighlights() async {
        do {
            for try await highlights in ayahHighlightService.highlightsSequence() {
                guard !isUpdatingHighlight else { continue }
                highlightSelection = Self.highlightSelection(for: verses, in: highlights)
            }
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Quran Sync: failed to observe highlights in bookmark editor: \(error)")
            self.error = error
        }
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
#endif
