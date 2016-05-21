//
//  QariAyahTimingPersistenceStorage.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol QariAyahTimingPersistenceStorage {

    func getTimingForSura(startAyah startAyah: AyahNumber, databaseFileURL: NSURL) -> [AyahNumber: AyahTiming]
}
