//
//  PageMappingError.swift
//  Quran
//
//  Created by OpenAI on 2026-04-25.
//

import QuranKit

enum PageMappingError: Error {
    case unableToMapPage(pageNumber: Int, source: Quran, destination: Quran)
}
