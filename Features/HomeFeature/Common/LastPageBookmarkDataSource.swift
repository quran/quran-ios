//
//  LastPageBookmarkDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
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

import AnnotationsService
import Combine
import Crashing
import Foundation
import GenericDataSources
import NoorUI
import QuranAnnotations
import QuranKit
import ReadingService
import UIKit
import UIx

class LastPageBookmarkDataSource: EquatableDataSource<LastPage, HostingTableViewCell<LastPageCell>> {
    // MARK: Lifecycle

    init(service: LastPageService) {
        self.service = service
        super.init()

        // Observe persistence changes
        loadLastPages()
    }

    // MARK: Internal

    weak var controller: UIViewController?

    override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: HostingTableViewCell<LastPageCell>,
        with item: LastPage,
        at indexPath: IndexPath
    ) {
        guard let controller else {
            return
        }

        let ayah = item.page.firstVerse
        let bookmarkCell = LastPageCell(
            page: item.page.pageNumber,
            localizedSura: ayah.sura.localizedName(),
            arabicSuraName: ayah.sura.arabicSuraName,
            createdSince: item.createdOn.timeAgo()
        )
        cell.set(rootView: bookmarkCell, parentController: controller)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        false
    }

    // MARK: Private

    private let service: LastPageService
    private let readingPreferences = ReadingPreferences.shared

    private var cancellables: Set<AnyCancellable> = []

    private func loadLastPages() {
        readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [weak self] reading in self?.service.lastPages(quran: reading.quran) ?? Empty().eraseToAnyPublisher() }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.items = $0 }
            .store(in: &cancellables)
    }
}
