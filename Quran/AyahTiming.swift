//
//  AyahTiming.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct AyahTiming {
    let ayah: AyahNumber
    let time: Int

    var seconds: Double {
        return Double(time) / 1000
    }
}
