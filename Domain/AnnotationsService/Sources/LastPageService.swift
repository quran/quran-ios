//
//  LastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Combine
import LastPagePersistence
import QuranAnnotations
import QuranKit

public struct LastPageService {
    // MARK: Lifecycle

    public init(persistence: LastPagePersistence, storedPageQuran: Quran = .hafsMadani1405) {
        self.persistence = persistence
        self.storedPageQuran = storedPageQuran
    }

    // MARK: Public

    public func lastPages(quran: Quran) -> AnyPublisher<[LastPage], Never> {
        let mapper = QuranPageMapper(destination: quran)
        return persistence.lastPages()
            .map { lastPages in
                lastPages.compactMap { lastPage in
                    Page(quran: storedPageQuran, pageNumber: lastPage.page)
                        .flatMap(mapper.mapPage)
                        .map {
                            LastPage(page: $0, createdOn: lastPage.createdOn, modifiedOn: lastPage.modifiedOn)
                        }
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: Internal

    let persistence: LastPagePersistence
    let storedPageQuran: Quran

    func add(page: Page) async throws -> LastPage {
        let storedPage = try storedPage(for: page)
        let persistenceModel = try await persistence.add(page: storedPage.pageNumber)
        return try lastPage(quran: page.quran, persistenceModel)
    }

    func update(page: Page, toPage: Page) async throws -> LastPage {
        let currentStoredPage = try storedPage(for: page)
        let storedToPage = try storedPage(for: toPage)
        let persistenceModel = try await persistence.update(
            page: currentStoredPage.pageNumber,
            toPage: storedToPage.pageNumber
        )
        return try lastPage(quran: toPage.quran, persistenceModel)
    }

    // MARK: Private

    private func storedPage(for page: Page) throws -> Page {
        guard let storedPage = QuranPageMapper(destination: storedPageQuran).mapPage(page) else {
            throw PageMappingError.unableToMapPage(
                pageNumber: page.pageNumber,
                source: page.quran,
                destination: storedPageQuran
            )
        }

        return storedPage
    }

    private func lastPage(quran: Quran, _ persistenceModel: LastPagePersistenceModel) throws -> LastPage {
        guard let storedPage = Page(quran: storedPageQuran, pageNumber: persistenceModel.page),
              let page = QuranPageMapper(destination: quran).mapPage(storedPage)
        else {
            throw PageMappingError.unableToMapPage(
                pageNumber: persistenceModel.page,
                source: storedPageQuran,
                destination: quran
            )
        }

        return LastPage(
            page: page,
            createdOn: persistenceModel.createdOn,
            modifiedOn: persistenceModel.modifiedOn
        )
    }
}
