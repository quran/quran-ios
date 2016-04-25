//
//  AyahNumber.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct AyahNumber: Hashable {
    let sura: Int
    let ayah: Int

    var hashValue: Int {
        return "\(sura):\(ayah)".hashValue
    }
}

func == (lhs: AyahNumber, rhs: AyahNumber) -> Bool {
    return lhs.sura == rhs.sura && lhs.ayah == lhs.ayah
}
