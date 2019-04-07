//
//  ThemeSettingsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 9/3/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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

struct ThemeSetting {
    let image: UIImage? = nil
    let onSelection: ((UIViewController, UITableViewCell) -> Void)? = nil
}

class ThemeSettingsDataSource: BasicDataSource<Theme, ThemeSelectionTableViewCell> {

    var zeroInset: Bool = true

    var onThemeUpdated: ((Theme) -> Void)?

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: ThemeSelectionTableViewCell,
                                    with item: Theme,
                                    at indexPath: IndexPath) {
        cell.separatorInset = zeroInset ? .zero : UIEdgeInsets(top: 0, left: 55, bottom: 0, right: 0)
        cell.kind = .cell
        cell.darkSelected = item == .dark
        cell.onDarkTapped = { [weak self] in
            self?.updateThemeItem(at: indexPath.item, to: .dark)
        }
        cell.onLightTapped = { [weak self] in
            self?.updateThemeItem(at: indexPath.item, to: .light)
        }
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    private func updateThemeItem(at index: Int, to newTheme: Theme) {
        items[index] = newTheme
        onThemeUpdated?(newTheme)
        ds_reusableViewDelegate?.ds_reloadItems(at: [IndexPath(item: 0, section: 0)], with: .none)
    }
}
