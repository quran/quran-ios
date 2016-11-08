//
//  QuartersDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct QuartersDataRetriever: DataRetriever {
    func retrieve(onCompletion: @escaping ([(Juz, [Quarter])]) -> Void) {

        Queue.background.async {
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

            Queue.main.async {
                onCompletion(juzsGroup)
            }
        }
    }
}
