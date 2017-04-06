//
//  CompositeVerseTextRetrieval.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/4/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit

class CompositeVerseTextRetrieval: Interactor {

    let image      : AnyInteractor<QuranShareData, String>
    let translation: AnyInteractor<QuranShareData, String>

    init(image      : AnyInteractor<QuranShareData, String>,
         translation: AnyInteractor<QuranShareData, String>) {
        self.image = image
        self.translation = translation
    }

    func execute(_ input: QuranShareData) -> Promise<String> {
        if input.cell is QuranImagePageCollectionViewCell {
            return image.execute(input)
        } else if input.cell is QuranTranslationCollectionPageCollectionViewCell {
            return translation.execute(input)
        }
        fatalError("Unsupported quran cell type.")
    }
}
