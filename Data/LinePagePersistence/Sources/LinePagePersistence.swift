//
//  LinePagePersistence.swift
//
//
//  Created by Mohamed Afifi on 2026-03-28.
//

import QuranKit

public protocol LinePagePersistence {
    func highlightSpans(_ page: Page) async throws -> [LinePageHighlightSpan]
    func ayahMarkers(_ page: Page) async throws -> [LinePageAyahMarker]
    func suraHeaders(_ page: Page) async throws -> [LinePageSuraHeader]
}
