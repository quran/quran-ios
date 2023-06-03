//
//  NoteDTO.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Foundation

public struct VerseDTO: Hashable {
    public let ayah: Int
    public let sura: Int

    public init(ayah: Int, sura: Int) {
        self.ayah = ayah
        self.sura = sura
    }
}

public struct NoteDTO: Equatable {
    public var verses: Set<VerseDTO>
    public let modifiedDate: Date
    public let note: String?
    public let color: Int
}
