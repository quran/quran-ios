//
//  ImageVerseTextRetrieval.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/4/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit

class ImageVerseTextRetrieval: Interactor {

    private let arabicAyahPersistence: AyahTextPersistence

    init(arabicAyahPersistence: AyahTextPersistence) {
        self.arabicAyahPersistence = arabicAyahPersistence
    }

    func execute(_ input: QuranShareData) -> Promise<String> {
        return DispatchQueue.global().promise {
            try self.arabicAyahPersistence.getAyahTextForNumber(input.ayah)
        }
    }
}
