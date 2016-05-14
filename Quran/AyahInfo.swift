//
//  AyahInfo.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct AyahInfo {
    let pageNumber: Int
    let ayah: AyahNumber
    let position: Int
    let minX: Int
    let maxX: Int
    let minY: Int
    let maxY: Int
    var rect: Rect {
        get {
            return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }
}
