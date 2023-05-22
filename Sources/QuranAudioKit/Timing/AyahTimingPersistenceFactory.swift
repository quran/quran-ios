//
//  AyahTimingPersistenceFactory.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/10/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import Foundation

protocol AyahTimingPersistenceFactory {
    func persistenceForURL(_ url: URL) throws -> AyahTimingPersistence
}

struct DefaultAyahTimingPersistenceFactory: AyahTimingPersistenceFactory {
    func persistenceForURL(_ url: URL) throws -> AyahTimingPersistence {
        try GRDBAyahTimingPersistence(fileURL: url)
    }
}
