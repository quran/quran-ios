//
//  QariTimingRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit

protocol QariTimingRetriever {
    func retrieveTiming(for qari: Qari, startAyah: AyahNumber) -> Promise<[AyahNumber: AyahTiming]>

    func retrieveTiming(for qari: Qari, suras: [Int]) -> Promise<[Int: [AyahTiming]]>
}
