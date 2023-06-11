//
//  Reciter+Localization.swift
//
//
//  Created by Mohamed Afifi on 2023-06-04.
//

import Localization
import QuranAudio

extension Reciter {
    public var localizedName: String {
        l(nameKey, table: .readers)
    }
}
