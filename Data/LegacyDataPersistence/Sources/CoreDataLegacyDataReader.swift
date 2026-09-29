#if QURAN_SYNC
//
//  CoreDataLegacyDataReader.swift
//
//
//  Created by Mohamed Afifi on 2026-09-24.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import Foundation
@preconcurrency import MobileSync
import QuranAnnotations
import QuranKit

/// Reads the legacy Core Data store as one MobileSync import.
///
/// The reader never saves. It bypasses the note publisher and uniquifiers and reads every record from
/// one query generation. Records that cannot be mapped yet, such as a note whose verses have not arrived,
/// are left out, so a later read imports them. Repeated reads of the same store produce the same import.
///
/// `CoreDataStack` is not `Sendable`, but the reader only loads the store through its lock and uses a new
/// background context per read, touched only inside `perform`.
public struct CoreDataLegacyDataReader: @unchecked Sendable {
    // MARK: Lifecycle

    public init(stack: CoreDataStack) {
        self.stack = stack
    }

    // MARK: Public

    /// Reads every page bookmark, last page, and note.
    ///
    /// Throws when the store cannot be opened or fetched; a failure is never reported as an empty import.
    public func importData() async throws -> PersistenceImportData {
        let context = try stack.openBackgroundContext()
        return try await context.perform { context in
            // Pin the generation so all fetches observe the same store state.
            try context.setQueryGenerationFrom(.current)
            defer { context.reset() }

            let bookmarks = try fetchPageBookmarks(context).compactMap(collectionBookmark)
            let notes = try fetchNotes(context).map(noteComponents)
            return PersistenceImportData(
                collections: oldPageBookmarksCollection(for: bookmarks),
                collectionBookmarks: bookmarks,
                readingSessions: try fetchLastPages(context).compactMap(readingSession),
                notes: notes.compactMap(\.note),
                highlights: notes.flatMap(\.highlights),
                // Legacy data has no reading-bookmark slots.
                readingBookmarks: []
            )
        }
    }

    /// Emits whenever the store changes, including CloudKit arrivals.
    ///
    /// The subscription is active when this method returns, even before the store loads.
    public func changes() -> AsyncStream<Void> {
        stack.changes()
    }

    // MARK: Private

    private let stack: CoreDataStack
}

// MARK: - Fetching

private func fetchPageBookmarks(_ context: NSManagedObjectContext) throws -> [MO_PageBookmark] {
    let request = MO_PageBookmark.fetchRequest()
    request.sortDescriptors = sortDescriptors(Schema.PageBookmark.modifiedOn, Schema.PageBookmark.createdOn)
    return try context.fetch(request)
}

private func fetchLastPages(_ context: NSManagedObjectContext) throws -> [MO_LastPage] {
    let request = MO_LastPage.fetchRequest()
    request.sortDescriptors = sortDescriptors(Schema.LastPage.modifiedOn, Schema.LastPage.createdOn)
    return try context.fetch(request)
}

private func fetchNotes(_ context: NSManagedObjectContext) throws -> [MO_Note] {
    let request = MO_Note.fetchRequest()
    request.sortDescriptors = sortDescriptors(Schema.Note.modifiedOn, Schema.Note.createdOn)
    request.relationshipKeyPathsForPrefetching = [Schema.Note.verses.rawValue]
    return try context.fetch(request)
}

/// Order keeps repeated reads stable when dates differ; the importer does not depend on it.
private func sortDescriptors<Key: CoreDataKey>(_ keys: Key...) -> [NSSortDescriptor] {
    keys.map { NSSortDescriptor(key: $0, ascending: true) }
}

// MARK: - Mapping

private func collectionBookmark(_ bookmark: MO_PageBookmark) -> ImportCollectionAyahBookmark? {
    guard let verse = firstVerse(page: bookmark.int(Schema.PageBookmark.page), mushafID: bookmark.int(Schema.PageBookmark.mushafID)) else {
        return nil
    }
    let dates = SourceDates(created: bookmark.date(Schema.PageBookmark.createdOn), modified: bookmark.date(Schema.PageBookmark.modifiedOn))
    return ImportCollectionAyahBookmark(
        collectionName: AyahBookmarkCollection.oldPageBookmarksName,
        sura: Int32(verse.sura.suraNumber),
        ayah: Int32(verse.ayah),
        lastUpdated: dates.lastUpdated,
        createdAt: dates.createdAt
    )
}

/// Emits the destination collection only when it receives a membership.
private func oldPageBookmarksCollection(for bookmarks: [ImportCollectionAyahBookmark]) -> [ImportCollection] {
    guard let createdAt = bookmarks.compactMap(\.createdAt).min(),
          let lastUpdated = bookmarks.map(\.lastUpdated).max()
    else {
        return []
    }
    return [ImportCollection(
        name: AyahBookmarkCollection.oldPageBookmarksName,
        lastUpdated: lastUpdated,
        createdAt: createdAt
    )]
}

private func readingSession(_ lastPage: MO_LastPage) -> ImportReadingSession? {
    let createdOn = lastPage.date(Schema.LastPage.createdOn)
    // A last page without dates is left out so it cannot import as a 1970 visit.
    guard let lastUpdated = lastPage.date(Schema.LastPage.modifiedOn) ?? createdOn,
          let verse = firstVerse(page: lastPage.int(Schema.LastPage.page), mushafID: lastPage.int(Schema.LastPage.mushafID))
    else {
        return nil
    }
    return ImportReadingSession(
        sura: Int32(verse.sura.suraNumber),
        ayah: Int32(verse.ayah),
        lastUpdated: lastUpdated,
        createdAt: createdOn ?? lastUpdated
    )
}

private func noteComponents(_ note: MO_Note) -> (note: ImportNote?, highlights: [ImportAyahHighlight]) {
    let verseObjects = note.verses as? Set<MO_Verse> ?? []
    // A note without verses may still receive them, so nothing is imported yet.
    guard !verseObjects.isEmpty else {
        return (nil, [])
    }
    let resolved = verseObjects.map(verse(of:))
    let verses = Set(resolved.compactMap { $0 }).sorted()
    let dates = SourceDates(created: note.date(Schema.Note.createdOn), modified: note.date(Schema.Note.modifiedOn))

    var importNote: ImportNote?
    // An invalid verse would narrow the range, so the text waits until every verse is valid.
    if let body = note.value(forKey: Schema.Note.note.rawValue) as? String,
       !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
       !resolved.contains(nil), let start = verses.first, let end = verses.last
    {
        importNote = ImportNote(
            body: body,
            startSura: Int32(start.sura.suraNumber),
            startAyah: Int32(start.ayah),
            endSura: Int32(end.sura.suraNumber),
            endAyah: Int32(end.ayah),
            lastUpdated: dates.lastUpdated,
            createdAt: dates.createdAt
        )
    }

    let color = highlightColor(note.int(Schema.Note.color))
    let highlights = verses.map { verse in
        ImportAyahHighlight(
            sura: Int32(verse.sura.suraNumber),
            ayah: Int32(verse.ayah),
            color: color,
            lastUpdated: dates.lastUpdated,
            createdAt: dates.createdAt
        )
    }
    return (importNote, highlights)
}

/// Unknown mushafs use the original Madani page layout.
private func firstVerse(page: Int?, mushafID: Int?) -> AyahNumber? {
    guard let page else {
        return nil
    }
    let mushaf = mushafID.flatMap(Int16.init(exactly:)).flatMap(QuranPageMushaf.init(rawValue:)) ?? .madani1405
    return Page(quran: mushaf.quran, pageNumber: page)?.firstVerse
}

/// Notes store verses without a mushaf; every Hafs layout shares the same verses.
private func verse(of verse: MO_Verse) -> AyahNumber? {
    guard let sura = verse.int(Schema.Verse.sura), let ayah = verse.int(Schema.Verse.ayah) else {
        return nil
    }
    return AyahNumber(quran: .hafsMadani1405, sura: sura, ayah: ayah)
}

/// Unknown colors are pink, like the notes list.
private func highlightColor(_ rawValue: Int?) -> AyahHighlightColor {
    switch HighlightColor(rawValue: rawValue ?? HighlightColor.pink.rawValue) ?? .pink {
    case .pink: .pink
    case .green: .green
    case .blue: .blue
    case .yellow: .yellow
    case .purple: .purple
    }
}

/// Stable dates for a source record.
///
/// Modification falls back to creation and then to the Unix epoch; creation falls back to modification.
private struct SourceDates {
    // MARK: Lifecycle

    init(created: Date?, modified: Date?) {
        lastUpdated = modified ?? created ?? Date(timeIntervalSince1970: 0)
        createdAt = created ?? lastUpdated
    }

    // MARK: Internal

    let lastUpdated: Date
    let createdAt: Date
}

private extension NSManagedObject {
    /// Reads a scalar attribute without converting a missing value to zero.
    func int(_ key: some CoreDataKey) -> Int? {
        (value(forKey: key.rawValue) as? NSNumber)?.intValue
    }

    func date(_ key: some CoreDataKey) -> Date? {
        value(forKey: key.rawValue) as? Date
    }
}
#endif
