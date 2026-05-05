//
//  LastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Combine
import QuranAnnotations
import QuranKit

public protocol LastPageService {
    func lastPages(quran: Quran) -> AnyPublisher<[LastPage], Never>

    func add(page: Page) async throws -> LastPage

    func update(page: Page, toPage: Page) async throws -> LastPage
}
