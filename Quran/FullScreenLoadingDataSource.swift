//
//  FullScreenLoadingDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/17.
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
import GenericDataSources

class FullScreenLoadingTableViewCell: UITableViewCell {

    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        activityIndicator.hidesWhenStopped = true

        contentView.addAutoLayoutSubview(activityIndicator)
        contentView.addParentCenterXConstraint(activityIndicator)
        contentView.addParentTopConstraint(activityIndicator, value: 50)
    }
}

class FullScreenLoadingDataSource: BasicDataSource<(), FullScreenLoadingTableViewCell> {

    override init() {
        super.init()
        items = [Void()]
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: FullScreenLoadingTableViewCell,
                                    with item: (), at indexPath: IndexPath) {
        cell.activityIndicator.startAnimating()
        cell.separatorInset = UIEdgeInsets(top: 0, left: collectionView.ds_scrollView.bounds.width, bottom: 0, right: 0)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let scrollView = collectionView.ds_scrollView
        return CGSize(width: scrollView.bounds.width - (scrollView.contentInset.left + scrollView.contentInset.right),
                      height: scrollView.bounds.height - (scrollView.contentInset.top + scrollView.contentInset.bottom))
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
