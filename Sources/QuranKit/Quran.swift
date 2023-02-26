//
//  Quran.swift
//
//
//  Created by Mohamed Afifi on 2021-12-10.
//

import Foundation

public final class Quran: Hashable {
    private let id = UUID()
    let raw: QuranReadingInfoRawData
    public static let hafsMadani1405 = Quran(raw: MadaniQuranReadingInfoRawData())

    init(raw: QuranReadingInfoRawData) {
        self.raw = raw
        lazySuras = { self.surasRange.map { Sura(quran: self, suraNumber: $0)! } }
        lazyPages = { self.pagesRange.map { Page(quran: self, pageNumber: $0)! } }
        lazyJuzs = { (1 ... self.numberOfJuzs).map { Juz(quran: self, juzNumber: $0) } }
        lazyQuarters = { (1 ... self.raw.quarters.count).map { Quarter(quran: self, quarterNumber: $0) } }
        lazyHizbs = { (1 ... self.numberOfHizbs).map { Hizb(quran: self, hizbNumber: $0) } }
        lazyVerses = { self.suras.flatMap(\.verses) }
    }

    public var arabicBesmAllah: String {
        raw.arabicBesmAllah
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Quran, rhs: Quran) -> Bool {
        lhs.id == rhs.id
    }

    @LazyAtomic private var lazySuras: () -> [Sura]
    public var suras: [Sura] {
        lazySuras()
    }

    @LazyAtomic private var lazyPages: () -> [Page]
    public var pages: [Page] {
        lazyPages()
    }

    @LazyAtomic private var lazyJuzs: () -> [Juz]
    public var juzs: [Juz] {
        lazyJuzs()
    }

    @LazyAtomic private var lazyQuarters: () -> [Quarter]
    public var quarters: [Quarter] {
        lazyQuarters()
    }

    @LazyAtomic private var lazyHizbs: () -> [Hizb]
    public var hizbs: [Hizb] {
        lazyHizbs()
    }

    @LazyAtomic private var lazyVerses: () -> [AyahNumber]
    public var verses: [AyahNumber] {
        lazyVerses()
    }
}

extension Quran {
    var pagesRange: ClosedRange<Int> {
        1 ... raw.startSuraOfPage.count
    }
}

extension Quran {
    var surasRange: ClosedRange<Int> {
        1 ... raw.startPageOfSura.count
    }

    public var firstSura: Sura {
        suras.first!
    }
}

extension Quran {
    private static let numberOfHizbsInJuz = 2
    private var numberOfJuzs: Int { numberOfHizbs / Self.numberOfHizbsInJuz }
}

extension Quran {
    private static let numberOfQuartersInHizb = 4
    private var numberOfHizbs: Int { raw.quarters.count / Self.numberOfQuartersInHizb }
}

extension Quran {
    public var firstVerse: AyahNumber {
        verses.first!
    }

    public var lastVerse: AyahNumber {
        verses.last!
    }
}
