//
//  Hizb.swift
//
//
//  Created by Mohamed Afifi on 2021-12-11.
//

public struct Hizb: QuranValueGroup {
    // MARK: Lifecycle

    init(quran: Quran, hizbNumber: Int) {
        storage = QuranValueStorage(quran: quran, value: hizbNumber, keyPath: \.hizbs)
    }

    init(_ storage: QuranValueStorage<Self>) {
        self.storage = storage
    }

    // MARK: Public

    public var hizbNumber: Int { storage.value }
    public var quran: Quran {
        storage.quran
    }

    public var firstVerse: AyahNumber {
        quarter.firstVerse
    }

    public var quarter: Quarter {
        let quarterNumber = (hizbNumber - 1) * (quran.quarters.count / quran.hizbs.count) + 1
        return quran.quarters[quarterNumber - 1]
    }

    public var juz: Juz {
        quarter.juz
    }

    // MARK: Internal

    let storage: QuranValueStorage<Self>
}
