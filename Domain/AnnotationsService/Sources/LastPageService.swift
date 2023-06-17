//
//  LastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Combine
import Foundation
import LastPagePersistence
import PromiseKit
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

    func add(page: Page) -> Promise<LastPage> {
        persistence.add(page: page.pageNumber)
            .map { LastPage(quran: page.quran, $0) }
    }

    func update(page: LastPage, toPage: Page) -> Promise<LastPage> {
        persistence.update(page: page.page.pageNumber, toPage: toPage.pageNumber)
            .map { LastPage(quran: toPage.quran, $0) }
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
