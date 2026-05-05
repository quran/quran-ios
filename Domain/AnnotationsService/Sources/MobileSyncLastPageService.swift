//
//  MobileSyncLastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

#if QURAN_SYNC
    import Combine
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
                        let mapped = sessions.compactMap { session -> LastPage? in
                            // Try to build an AyahNumber from the stored session values
                            guard let sourceAyah = AyahNumber(quran: quran, sura: Int(session.sura), ayah: Int(session.ayah)) else {
                                return nil
                            }

                            // If the source ayah already belongs to the target quran, use its page directly.
                            // Otherwise map it to the target quran.
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

                            let createdOn = session.lastUpdated
                            return LastPage(page: page, createdOn: createdOn, modifiedOn: createdOn)
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
                ayah: Int32(firstVerse.ayah)
            )
            return LastPage(page: page, createdOn: session.lastUpdated, modifiedOn: session.lastUpdated)
        }

        public func update(page: Page, toPage: Page) async throws -> LastPage {
            try await add(page: toPage)
        }

        // MARK: Private

        private let syncService: SyncService
    }
#endif
