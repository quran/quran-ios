//
//  Qari.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

enum AudioType {
    case Gapless(databaseName: String)
    case Gapped
}

struct Qari: Hashable {
    let id: Int
    let name: String
    let path: String
    let audioURL: NSURL
    let audioType: AudioType
    let imageName: String?

    var hashValue: Int {
        return id.hashValue
    }
}

func == (lhs: Qari, rhs: Qari) -> Bool {
    return lhs.id == rhs.id
}
