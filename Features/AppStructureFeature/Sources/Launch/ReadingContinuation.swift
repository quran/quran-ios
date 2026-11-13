import AnnotationsService
import QuranAnnotations
import QuranKit

/// Resolves one snapshot, without waiting for the long-lived history observation to end.
@MainActor
struct ReadingContinuation {
    let page: Page
    let lastPage: LastPage?

    static func resolve(quran: Quran, service: any LastPageService) async throws -> Self {
        var history = service.lastPages(quran: quran).makeAsyncIterator()
        let lastPage = try await history.next()?.first
        try Task.checkCancellation()
        return Self(page: lastPage?.page ?? quran.firstVerse.page, lastPage: lastPage)
    }
}
