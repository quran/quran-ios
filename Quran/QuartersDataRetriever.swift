//
//  QuartersDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import PromiseKit

struct QuartersDataRetriever: Interactor {

    func execute(_ input: Void) -> Promise<[(Juz, [Quarter])]> {
        return DispatchQueue.default.promise2 {
            guard let ayahsText = NSArray(contentsOf: Files.quarterPrefixArray) as? [String] else {
                fatalError("Couldn't load `\(Files.quarterPrefixArray)` file")
            }

            let juzs = Juz.getJuzs()

            var juzsGroup: [(Juz, [Quarter])] = []

            let numberOfQuarters = Quran.Quarters.count / juzs.count

            for (juzIndex, juz) in juzs.enumerated() {

                var quarters: [Quarter] = []
                for i in 0..<numberOfQuarters {

                    let order = juzIndex * numberOfQuarters + i
                    let ayah = Quran.Quarters[order]

                    let quarter = Quarter(order: order,
                                          ayah: ayah,
                                          juz: juz,
                                          startPageNumber: ayah.getStartPage(),
                                          ayahText: ayahsText[order])
                    quarters.append(quarter)
                }
                juzsGroup.append((juz, quarters))
            }
            return juzsGroup
        }
    }
}
