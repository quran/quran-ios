//
//  QuranReadingInfoRawData.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/22/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

protocol QuranReadingInfoRawData: Sendable {
    var arabicBesmAllah: String { get }

    var numberOfPages: Int { get }
    var pagesToSkip: Int { get }
    var startPageOfSura: [Int] { get }
    var startSuraOfPage: [Int] { get }
    var startAyahOfPage: [Int] { get }
    var numberOfAyahsInSura: [Int] { get }
    var isMakkiSura: [Bool] { get }
    var quarters: [(sura: Int, ayah: Int)] { get }
}

extension QuranReadingInfoRawData {
    var numberOfPages: Int {
        startSuraOfPage.count
    }

    var pagesToSkip: Int {
        0
    }
}
