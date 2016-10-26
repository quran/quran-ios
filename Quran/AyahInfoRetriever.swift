//
//  AyahInfoRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

// Implementation should use reasonable caching and preloading next pages
protocol AyahInfoRetriever {
    func retrieveAyahsAtPage(_ page: Int, onCompletion: @escaping (Result<[AyahNumber: [AyahInfo]]>) -> Void)
}
