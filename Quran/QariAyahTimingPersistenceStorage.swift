//
//  QariAyahTimingPersistenceStorage.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol QariAyahTimingPersistenceStorage {

    func getTimingForSura(startAyah: AyahNumber, databaseFileURL: Foundation.URL) -> [AyahNumber: AyahTiming]
    func getOrderedTimingForSura(startAyah: AyahNumber, databaseFileURL: Foundation.URL) -> [AyahTiming]
}
