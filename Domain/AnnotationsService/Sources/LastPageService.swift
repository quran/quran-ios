//
//  LastPageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import QuranAnnotations
import QuranKit
import Utilities

@MainActor
public protocol LastPageService {
    func lastPages(quran: Quran) -> AnyAsyncSequence<[LastPage]>

    func add(page: Page) async throws -> LastPage

    func update(lastPage: LastPage, toPage: Page) async throws -> LastPage
}
