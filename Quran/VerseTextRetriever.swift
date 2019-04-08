//
//  VerseTextRetriever.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import PromiseKit

protocol VerseTextRetriever {
    func getText(for input: QuranShareData) -> Promise<[String]>
}
