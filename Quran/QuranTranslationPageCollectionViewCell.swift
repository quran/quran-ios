//
//  QuranTranslationPageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/21/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranTranslationPageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var tableView: UITableView!

    let dataSource = QuranInnerTranslationDataSource()

    var page: QuranPage?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = UIColor.readingBackground()

        tableView.register(cell: QuranSuraTableViewCell.self)
        tableView.register(cell: QuranVerseNumberTableViewCell.self)
        tableView.register(cell: QuranTranslationVerseSeparatorTableViewCell.self)
        tableView.register(cell: QuranArabicTextTableViewCell.self)
        tableView.register(cell: QuranTranslationNameTableViewCell.self)
        tableView.register(cell: QuranTranslationTextTableViewCell.self)

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100

        tableView.ds_useDataSource(dataSource)
    }
}
