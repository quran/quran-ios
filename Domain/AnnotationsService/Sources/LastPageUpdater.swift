//
//  LastPageUpdater.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/10/16.
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

import Crashing
import Foundation
import QuranAnnotations
import QuranKit

public class LastPageUpdater {
    private let service: LastPageService
    public private(set) var lastPage: LastPage?

    public init(service: LastPageService) {
        self.service = service
    }

    public func configure(initialPage: Page, lastPage: LastPage?) {
        self.lastPage = lastPage

        if let lastPage {
            updateTo(page: initialPage, lastPage: lastPage)
        } else {
            create(page: initialPage)
        }
    }

    public func updateTo(pages: [Page]) {
        guard let page = pages.min() else {
            return
        }
        // don't update if it's the same page
        guard let lastPage, page != lastPage.page else { return }

        updateTo(page: page, lastPage: lastPage)
    }

    private func updateTo(page: Page, lastPage: LastPage) {
        service.update(page: lastPage, toPage: page)
            .done(on: .main) { self.lastPage = $0 }
            .catch { error in
                crasher.recordError(error, reason: "Failed to update last page")
            }
    }

    private func create(page: Page) {
        service.add(page: page)
            .done(on: .main) { self.lastPage = $0 }
            .catch { error in
                crasher.recordError(error, reason: "Failed to create a last page")
            }
    }
}
