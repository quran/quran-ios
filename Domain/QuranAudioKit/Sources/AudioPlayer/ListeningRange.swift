import QuranKit

/// Counts the remaining portion of the starting page as the first page.
public struct ListeningRange: Equatable, Sendable {
    // MARK: Lifecycle

    public init(from start: AyahNumber, pageCount: Int) throws {
        guard pageCount > 0 else { throw Error.invalidPageCount }
        self.start = start
        let startPage = start.page.pageNumber
        // Clamp before adding so even Int.max is a safe request.
        let additionalPages = min(pageCount - 1, start.quran.numberOfPages - startPage)
        end = Page(quran: start.quran, pageNumber: startPage + additionalPages)!.lastVerse
    }

    // MARK: Public

    public enum Error: Swift.Error, Equatable {
        case invalidPageCount
    }

    public let start: AyahNumber
    public let end: AyahNumber
}
