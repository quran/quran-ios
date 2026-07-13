//
//  MobileSyncLastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

#if QURAN_SYNC
import Combine
import Foundation
@preconcurrency import MobileSync
import QuranAnnotations
import QuranKit

public struct MobileSyncLastPageService: LastPageService, @unchecked Sendable {
    // MARK: Lifecycle

    public init(quranDataService: QuranDataService) {
        self.quranDataService = quranDataService
    }

    // MARK: Public

    public func lastPages(quran: Quran) -> AnyPublisher<[LastPage], Never> {
        let subject = CurrentValueSubject<[LastPage], Never>([])
        let task = Task {
            do {
                for try await sessions in quranDataService.readingSessionsSequence() {
                    if Task.isCancelled {
                        break
                    }
                    let mapped = sessions.compactMap { session in
                        lastPage(for: session, quran: quran)
                    }

                    let sorted = mapped.sorted { $0.createdOn > $1.createdOn }
                    subject.send(Array(sorted.prefix(3)))
                }
            } catch {
                // ignore errors
            }
        }
        return subject
            .handleEvents(receiveCancel: { task.cancel() })
            .eraseToAnyPublisher()
    }

    public func add(page: Page) async throws -> LastPage {
        let firstVerse = page.firstVerse
        let session = try await quranDataService.addReadingSession(
            sura: Int32(firstVerse.sura.suraNumber),
            ayah: Int32(firstVerse.ayah),
            timestamp: Date()
        )
        return lastPage(page: page, for: session)
    }

    public func update(lastPage: LastPage, toPage: Page) async throws -> LastPage {
        guard let localId = lastPage.localId else {
            return try await add(page: toPage)
        }

        let firstVerse = toPage.firstVerse
        let updatedSession = try await quranDataService.updateReadingSession(
            id: localId,
            sura: Int32(firstVerse.sura.suraNumber),
            ayah: Int32(firstVerse.ayah),
            timestamp: Date()
        )
        return self.lastPage(page: toPage, for: updatedSession)
    }

    // MARK: Private

    private let quranDataService: QuranDataService

    private func lastPage(for session: ReadingSession, quran: Quran) -> LastPage? {
        guard let sourceAyah = AyahNumber(quran: quran, sura: Int(session.sura), ayah: Int(session.ayah)) else {
            return nil
        }

        let page: Page
        if sourceAyah.quran === quran {
            page = sourceAyah.page
        } else {
            let mapper = QuranPageMapper(destination: quran)
            guard let mappedAyah = mapper.mapAyah(sourceAyah) else {
                return nil
            }
            page = mappedAyah.page
        }

        return lastPage(page: page, for: session)
    }

    private func lastPage(page: Page, for session: ReadingSession) -> LastPage {
        LastPage(
            page: page,
            createdOn: session.lastUpdated,
            modifiedOn: session.lastUpdated,
            localId: session.id
        )
    }
}
#endif
