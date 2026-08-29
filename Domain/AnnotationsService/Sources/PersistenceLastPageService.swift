//
//  PersistenceLastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

#if !QURAN_SYNC
import Combine
import Foundation
import LastPagePersistence
import QuranAnnotations
import QuranKit
import Utilities

public struct PersistenceLastPageService: LastPageService {
    // MARK: Lifecycle

    public init(persistence: LastPagePersistence) {
        self.persistence = persistence
    }

    // MARK: Public

    public func lastPages(quran: Quran) -> AnyAsyncSequence<[LastPage]> {
        let mapper = QuranPageMapper(destination: quran)
        let sequence = persistence.lastPages()
            .map { lastPages in
                let mappedLastPages = lastPages.compactMap { lastPage -> MappedLastPage? in
                    guard let presentationPage = mapper.mapPage(lastPage.page) else {
                        return nil
                    }
                    return MappedLastPage(
                        presentationPage: presentationPage,
                        storedPage: lastPage.page,
                        createdOn: lastPage.createdOn,
                        modifiedOn: lastPage.modifiedOn
                    )
                }
                return Dictionary(grouping: mappedLastPages, by: \.presentationPage)
                    .values
                    .compactMap { groupedLastPages -> LastPage? in
                        guard let newestLastPage = groupedLastPages.max(by: {
                            $0.modifiedOn < $1.modifiedOn
                        }) else {
                            return nil
                        }
                        return LastPage(
                            page: newestLastPage.presentationPage,
                            storedPages: Set(groupedLastPages.map(\.storedPage)),
                            createdOn: newestLastPage.createdOn,
                            modifiedOn: newestLastPage.modifiedOn
                        )
                    }
                    .sorted { $0.modifiedOn > $1.modifiedOn }
            }
            .values()
        return .init(sequence)
    }

    public func add(page: Page) async throws -> LastPage {
        let persistenceModel = try await persistence.add(at: page)
        return LastPage(
            page: page,
            storedPages: [persistenceModel.page],
            createdOn: persistenceModel.createdOn,
            modifiedOn: persistenceModel.modifiedOn
        )
    }

    public func update(lastPage currentLastPage: LastPage, toPage: Page) async throws -> LastPage {
        let persistenceModel = try await persistence.update(
            pages: currentLastPage.storedPages,
            to: toPage
        )
        return LastPage(
            page: toPage,
            storedPages: [persistenceModel.page],
            createdOn: persistenceModel.createdOn,
            modifiedOn: persistenceModel.modifiedOn
        )
    }

    // MARK: Internal

    let persistence: LastPagePersistence
}

private struct MappedLastPage {
    let presentationPage: Page
    let storedPage: Page
    let createdOn: Date
    let modifiedOn: Date
}
#endif
