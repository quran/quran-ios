//
//  CompositeVerseTextRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/4/17.
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

class CompositeVerseTextRetriever: VerseTextRetriever {

    let arabicText: VerseTextRetriever
    let translation: VerseTextRetriever

    init(arabicText: VerseTextRetriever, translation: VerseTextRetriever) {
        self.arabicText = arabicText
        self.translation = translation
    }

    func getText(for input: VerseTextRetrieverInput) -> Promise<[String]> {
        if input.translationPage == nil {
            return arabicText.getText(for: input)
        } else {
            return translation.getText(for: input)
        }
    }
}
