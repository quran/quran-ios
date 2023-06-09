//
//  WordFramePersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import Foundation
import QuranKit

public protocol WordFramePersistence {
    func wordFrameCollectionForPage(_ page: Page) async throws -> WordFrameCollection
    func suraHeaders(_ page: Page) async throws -> [SuraHeaderLocation]
    func ayahNumbers(_ page: Page) async throws -> [AyahNumberLocation]
}
