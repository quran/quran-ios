//
//  MobileSyncLastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

#if QURAN_SYNC
@preconcurrency import MobileSync
import QuranAnnotations
import QuranKit

public struct MobileSyncLastPageService: LastPageService {
    // MARK: Lifecycle

    public init(quranDataService: QuranDataService) {
        self.quranDataService = quranDataService
    }

    // MARK: Public

    public func lastPages(quran: Quran) -> LastPagesSequence {
        let sequence = quranDataService.readingSessionsSequence()
            .map { sessions in
                let mapped = sessions.compactMap { session in
                    lastPage(for: session, quran: quran)
                }
                let sorted = mapped.sorted {
                    if $0.modifiedOn == $1.modifiedOn {
                        return $0.id < $1.id
                    }
                    return $0.modifiedOn > $1.modifiedOn
                }
                return Array(sorted.prefix(3))
            }
        return LastPagesSequence(sequence)
    }

    public func add(page: Page) async throws -> LastPage {
        let firstVerse = page.firstVerse
        let session = try await quranDataService.addReadingSession(
            sura: Int32(firstVerse.sura.suraNumber),
            ayah: Int32(firstVerse.ayah)
        )
        return lastPage(page: page, for: session)
    }

    public func update(lastPage: LastPage, toPage: Page) async throws -> LastPage {
        let firstVerse = toPage.firstVerse
        let updatedSession = try await quranDataService.updateReadingSession(
            id: lastPage.id,
            sura: Int32(firstVerse.sura.suraNumber),
            ayah: Int32(firstVerse.ayah)
        )
        return self.lastPage(page: toPage, for: updatedSession)
    }

    // MARK: Private

    private let quranDataService: QuranDataService

    private nonisolated func lastPage(for session: ReadingSession, quran: Quran) -> LastPage? {
        guard let ayah = AyahNumber(quran: quran, sura: Int(session.sura), ayah: Int(session.ayah)) else {
            return nil
        }
        return lastPage(page: ayah.page, for: session)
    }

    private nonisolated func lastPage(page: Page, for session: ReadingSession) -> LastPage {
        LastPage(
            id: session.id,
            page: page,
            modifiedOn: session.lastUpdated
        )
    }
}
#endif
