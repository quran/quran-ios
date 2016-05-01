//
//  Quarter.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Quarter: QuranPageReference {
    let order: Int

    let ayah: AyahNumber
    let juz: Juz

    let startPageNumber: Int

    let ayahText: String
}
