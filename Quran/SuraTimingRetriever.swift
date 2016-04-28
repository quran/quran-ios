//
//  SuraTimingRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol SuraTimingRetriever {
    func retrieveSuraTiming(sura: Int, onCompletion: Result<[SuraTiming], PersistenceError> -> Void)
}
