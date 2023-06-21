//
//  SurasInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Combine
import FeaturesSupport
import Foundation
import QuranAnnotations
import QuranKit
import ReadingService

@MainActor
protocol SurasPresentable: AnyObject {
    func setSuras(_ surasDictionary: [Juz: [Sura]], juzs: [Juz])
}

final class SurasInteractor: QuranNavigator {
    // MARK: Lifecycle

    init() {
    }

    // MARK: Internal

    weak var quranNavigator: QuranNavigator?
    weak var presenter: SurasPresentable?

    func start() {
        cancellable = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                self?.update(with: reading.quran)
            }
    }

    func navigateTo(page: Page, lastPage: LastPage?, highlightingSearchAyah: AyahNumber?) {
        quranNavigator?.navigateTo(page: page, lastPage: lastPage, highlightingSearchAyah: highlightingSearchAyah)
    }

    // MARK: Private

    private let readingPreferences = ReadingPreferences.shared
    private var cancellable: AnyCancellable?

    private func update(with quran: Quran) {
        let suras = quran.suras
        let surasDictionary = Dictionary(grouping: suras, by: { $0.page.startJuz })
        presenter?.setSuras(surasDictionary, juzs: surasDictionary.keys.sorted())
    }
}
