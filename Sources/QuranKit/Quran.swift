//
//  Quran.swift
//
//
//  Created by Mohamed Afifi on 2021-12-10.
//

import Foundation

public struct Quran: Hashable {
    private let id = UUID()
    let raw: QuranReadingInfoRawData
    public static let madani = Quran(raw: MadaniQuranReadingInfoRawData())

    public var arabicBesmAllah: String {
        raw.arabicBesmAllah
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Quran {
    var pagesRange: ClosedRange<Int> {
        1 ... raw.startSuraOfPage.count
    }

    public var pages: [Page] {
        pagesRange.map { Page(quran: self, pageNumber: $0)! }
    }
}

extension Quran {
    var surasRange: ClosedRange<Int> {
        1 ... raw.startPageOfSura.count
    }

    public var firstSura: Sura {
        suras.first!
    }

    public var suras: [Sura] {
        surasRange.map { Sura(quran: self, suraNumber: $0)! }
    }
}

extension Quran {
    private static let numberOfHizbsInJuz = 2
    private var numberOfJuzs: Int { numberOfHizbs / Self.numberOfHizbsInJuz }
    public var juzs: [Juz] {
        (1 ... numberOfJuzs).map { Juz(quran: self, juzNumber: $0) }
    }
}

extension Quran {
    public var quarters: [Quarter] {
        (1 ... raw.quarters.count).map { Quarter(quran: self, quarterNumber: $0) }
    }
}

extension Quran {
    private static let numberOfQuartersInHizb = 4
    private var numberOfHizbs: Int { raw.quarters.count / Self.numberOfQuartersInHizb }
    public var hizbs: [Hizb] {
        (1 ... numberOfHizbs).map { Hizb(quran: self, hizbNumber: $0) }
    }
}

extension Quran {
    public var firstVerse: AyahNumber {
        verses.first!
    }

    public var lastVerse: AyahNumber {
        verses.last!
    }

    public var verses: [AyahNumber] {
        suras.flatMap(\.verses)
    }
}
