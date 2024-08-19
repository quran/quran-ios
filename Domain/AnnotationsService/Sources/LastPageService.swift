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

    public init(persistence: LastPagePersistence) {
        self.persistence = persistence
    }

    // MARK: Public

    public func lastPages(quran: Quran) -> AnyPublisher<[LastPage], Never> {
        persistence.lastPages()
            .map { lastPages in lastPages.map { LastPage(quran: quran, $0) } }
            .eraseToAnyPublisher()
    }

    // MARK: Internal

    let persistence: LastPagePersistence

    func add(page: Page) async throws -> LastPage {
        let persistenceModel = try await persistence.add(page: page.pageNumber)
        return LastPage(quran: page.quran, persistenceModel)
    }

    func update(page: Page, toPage: Page) async throws -> LastPage {
        let persistenceModel = try await persistence.update(
            page: page.pageNumber,
            toPage: toPage.pageNumber
        )
        return LastPage(quran: toPage.quran, persistenceModel)
    }
}

private extension LastPage {
    init(quran: Quran, _ other: LastPagePersistenceModel) {
        self.init(
            page: Page(quran: quran, pageNumber: Int(other.page))!,
            createdOn: other.createdOn,
            modifiedOn: other.modifiedOn
        )
    }
}
