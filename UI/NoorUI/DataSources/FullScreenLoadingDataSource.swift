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
import UIKit

public class FullScreenLoadingTableViewCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    // MARK: Internal

    let activityIndicator = UIActivityIndicatorView()

    // MARK: Private

    private func setUp() {
        backgroundColor = .systemBackground
        activityIndicator.hidesWhenStopped = true

        contentView.addAutoLayoutSubview(activityIndicator)
        activityIndicator.vc
            .centerX()
            .top(by: 50)
    }
}

public class FullScreenLoadingDataSource: BasicDataSource<Void, FullScreenLoadingTableViewCell> {
    // MARK: Lifecycle

    override public init() {
        super.init()
        items = [()]
    }

    // MARK: Public

    override public func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: FullScreenLoadingTableViewCell,
        with item: (),
        at indexPath: IndexPath
    ) {
        cell.activityIndicator.startAnimating()
        cell.separatorInset = UIEdgeInsets(top: 0, left: collectionView.ds_scrollView.bounds.width, bottom: 0, right: 0)
    }

    override public func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let scrollView = collectionView.ds_scrollView
        return CGSize(
            width: scrollView.bounds.width - (scrollView.contentInset.left + scrollView.contentInset.right),
            height: scrollView.bounds.height - (scrollView.contentInset.top + scrollView.contentInset.bottom)
        )
    }

    override public func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        false
    }
}
