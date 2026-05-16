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

        public init(syncService: SyncService) {
            self.syncService = syncService
        }

        // MARK: Public

        public func lastPages(quran: Quran) -> AnyPublisher<[LastPage], Never> {
            let subject = CurrentValueSubject<[LastPage], Never>([])
            let task = Task {
                do {
                    for try await sessions in syncService.readingSessionsSequence() {
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
            let session = try await syncService.addReadingSession(
                sura: Int32(firstVerse.sura.suraNumber),
                ayah: Int32(firstVerse.ayah),
                timestamp: Date()
            )
            updateState.setActive(localId: session.localId, page: page)
            return LastPage(page: page, createdOn: session.lastUpdated, modifiedOn: session.lastUpdated)
        }

        public func update(page: Page, toPage: Page) async throws -> LastPage {
            let sessions = try await readingSessions()
            guard let session = readingSessionToUpdate(from: sessions, page: page) else {
                return try await add(page: toPage)
            }

            if let targetSession = readingSession(for: toPage, in: sessions), targetSession.localId != session.localId {
                updateState.setActive(localId: session.localId, page: toPage)
                return LastPage(page: toPage, createdOn: session.lastUpdated, modifiedOn: session.lastUpdated)
            }

            let firstVerse = toPage.firstVerse
            let updatedSession = try await syncService.updateReadingSession(
                localId: session.localId,
                sura: Int32(firstVerse.sura.suraNumber),
                ayah: Int32(firstVerse.ayah),
                timestamp: Date()
            )
            updateState.setActive(localId: updatedSession.localId, page: toPage)
            return LastPage(page: toPage, createdOn: updatedSession.lastUpdated, modifiedOn: updatedSession.lastUpdated)
        }

        // MARK: Private

        private let syncService: SyncService
        private let updateState = ReadingSessionUpdateState()

        private func readingSessions() async throws -> [ReadingSession] {
            var iterator = syncService.readingSessionsSequence().makeAsyncIterator()
            return try await iterator.next() ?? []
        }

        private func readingSessionToUpdate(from sessions: [ReadingSession], page: Page) -> ReadingSession? {
            if let activeLocalId = updateState.activeLocalId(for: page),
               let activeSession = sessions.first(where: { $0.localId == activeLocalId })
            {
                return activeSession
            }
            return readingSession(for: page, in: sessions)
        }

        private func readingSession(for page: Page, in sessions: [ReadingSession]) -> ReadingSession? {
            sessions.first { session in
                lastPage(for: session, quran: page.quran)?.page == page
            }
        }

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

            return LastPage(page: page, createdOn: session.lastUpdated, modifiedOn: session.lastUpdated)
        }
    }

    private final class ReadingSessionUpdateState: @unchecked Sendable {
        func activeLocalId(for page: Page) -> String? {
            lock.withLock {
                activePage == page ? activeLocalId : nil
            }
        }

        func setActive(localId: String, page: Page) {
            lock.withLock {
                activeLocalId = localId
                activePage = page
            }
        }

        private let lock = NSLock()
        private var activeLocalId: String?
        private var activePage: Page?
    }
#endif
