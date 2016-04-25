//
//  SurasDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol SurasDataRetriever {
    func retrieveSuras(onCompletion onCompletion: [(Juz, [Sura])] -> Void)
}
