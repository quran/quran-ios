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

import Foundation

class LastPageUpdater {
    private let persistence: LastPagesPersistence
    private (set) var lastPage: LastPage?

    init(persistence: LastPagesPersistence) {
        self.persistence = persistence
    }

    func configure(initialPage: Int, lastPage: LastPage?) {
        self.lastPage = lastPage

        if lastPage == nil {
            create(page: initialPage)
        } else {
            forceUpdateTo(page: initialPage)
        }
    }

    func updateTo(page: Int) {
        // don't update if it's the same page
        guard let lastPage = lastPage, page != lastPage.page else { return }

        Analytics.shared.showing(quranPage: page)
        forceUpdateTo(page: page)
    }

    private func forceUpdateTo(page: Int) {
        guard let lastPage = lastPage else { return }
        DispatchQueue.global()
            .promise { try self.persistence.update(page: lastPage, toPage: page) }
            .then (on: .main) { self.lastPage = $0 }
            .cauterize(tag: "LastPagesPersistence.update(page:toPage:)")
    }

    private func create(page: Int) {
        DispatchQueue.global()
            .promise { try self.persistence.add(page: page) }
            .then (on: .main) { self.lastPage = $0 }
            .cauterize(tag: "LastPagesPersistence.update(page:toPage:)")
    }
}
