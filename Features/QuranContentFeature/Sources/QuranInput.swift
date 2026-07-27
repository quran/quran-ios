//
//  QuranInput.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/2/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QuranAnnotations
import QuranKit

public struct QuranInput {
    // MARK: Lifecycle

    public init(initialAyah: AyahNumber, lastPage: LastPage?) {
        self.initialAyah = initialAyah
        self.lastPage = lastPage
    }

    // MARK: Public

    public let initialAyah: AyahNumber
    public let lastPage: LastPage?
}
