//
//  WordFramePersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import QuranGeometry
import QuranKit

public protocol WordFramePersistence {
    func wordFrameCollectionForPage(_ page: Page) async throws -> [WordFrame]
    func suraHeaders(_ page: Page) async throws -> [SuraHeaderLocation]
    func ayahNumbers(_ page: Page) async throws -> [AyahNumberLocation]
}
