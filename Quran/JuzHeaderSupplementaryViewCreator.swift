//
//  JuzHeaderSupplementaryViewCreator.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class JuzHeaderSupplementaryViewCreator: BasicSupplementaryViewCreator<Juz, JuzTableViewHeaderFooterView> {

    private let numberFormatter = NumberFormatter()

    var onJuzHeaderSelected: ((Juz) -> Void)?

    override init() {
        super.init(size: CGSize(width: 0, height: 44))
    }

    override func collectionView(_ collectionView: GeneralCollectionView,
                                 configure view: JuzTableViewHeaderFooterView,
                                 with item: Juz,
                                 at indexPath: IndexPath) {

        view.titleLabel.text = String(format: NSLocalizedString("juz2_description", tableName: "Android", comment: ""), item.juzNumber)
        view.subtitleLabel.text = numberFormatter.string(from: NSNumber(value: item.startPageNumber))

        view.object = item
        view.onTapped = { [weak self, weak view] in
            guard let object = view?.object as? Juz else { return }

            self?.onJuzHeaderSelected?(object)
        }
    }
}
