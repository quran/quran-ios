//
//  Quran.swift
//
//
//  Created by Mohamed Afifi on 2021-12-10.
//

import Foundation

public final class Quran: Hashable, @unchecked Sendable {
    // MARK: Lifecycle

    init(raw: QuranReadingInfoRawData) {
        self.raw = raw
        lazySuras = { self.surasRange.map { Sura(quran: self, suraNumber: $0)! } }
        lazyPages = { self.pagesRange.map { Page(quran: self, pageNumber: $0)! } }
        lazyJuzs = { (1 ... self.numberOfJuzs).map { Juz(quran: self, juzNumber: $0) } }
        lazyQuarters = { (1 ... self.raw.quarters.count).map { Quarter(quran: self, quarterNumber: $0) } }
        lazyHizbs = { (1 ... self.numberOfHizbs).map { Hizb(quran: self, hizbNumber: $0) } }
        lazyVerses = { self.suras.flatMap(\.verses) }
    }

    // MARK: Public

    public static let hafsMadani1405 = Quran(raw: Madani1405QuranReadingInfoRawData())
    public static let hafsMadani1440 = Quran(raw: Madani1440QuranReadingInfoRawData())

    public var arabicBesmAllah: String {
        raw.arabicBesmAllah
    }

    public var suras: [Sura] {
        lazySuras()
    }

    public var pages: [Page] {
        lazyPages()
    }

    public var juzs: [Juz] {
        lazyJuzs()
    }

    public var quarters: [Quarter] {
        lazyQuarters()
    }

    public var hizbs: [Hizb] {
        lazyHizbs()
    }

    public var verses: [AyahNumber] {
        lazyVerses()
    }

    public static func == (lhs: Quran, rhs: Quran) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: Internal

    let raw: QuranReadingInfoRawData

    // MARK: Private

    private let id = UUID()
    @LazyAtomic private var lazySuras: () -> [Sura]
    @LazyAtomic private var lazyPages: () -> [Page]
    @LazyAtomic private var lazyJuzs: () -> [Juz]
    @LazyAtomic private var lazyQuarters: () -> [Quarter]
    @LazyAtomic private var lazyHizbs: () -> [Hizb]
    @LazyAtomic private var lazyVerses: () -> [AyahNumber]
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
