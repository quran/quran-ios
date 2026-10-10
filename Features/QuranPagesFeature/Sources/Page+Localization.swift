//
//  Page+Localization.swift
//
//
//  Created by Mohamed Afifi on 2023-06-19.
//

import Caching
import NoorUI
import QuranKit
import QuranTextKit

extension Page {
    public func suraNames() -> MultipartText {
        "\(suras: suras)"
    }
}

extension Page: @retroactive Pageable { }
