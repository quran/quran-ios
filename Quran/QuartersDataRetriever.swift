//
//  QuartersDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol QuartersDataRetriever {
    func retrieveSuras(onCompletion onCompletion: [(Juz, [Quarter])] -> Void)
}
