//
//  QariTimingRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol QariTimingRetriever {
    func retrieveTimingForQari(qari: Qari, startAyah: AyahNumber, onCompletion: [AyahNumber: AyahTiming] -> Void)

    func retrieveTimingForQari(qari: Qari, suras: [Int], onCompletion: [Int: [AyahTiming]] -> Void)
}
