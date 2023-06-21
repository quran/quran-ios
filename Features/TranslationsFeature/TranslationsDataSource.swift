//
//  TranslationsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
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
import Localization
import NoorUI
import UIKit
import UIx

@MainActor
class TranslationsDataSource {
    struct Actions {
        let cancelDownloading: (TranslationInfo.ID) -> Void
        let startDownloading: (TranslationInfo.ID) -> Void
    }

    // MARK: Lifecycle

    init(tableView: UITableView, actions: Actions) {
        self.actions = actions
        self.tableView = tableView
        ds = TranslationsDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, id in
            let cell = tableView.dequeueReusableCell(withIdentifier: TranslationTableViewCell.reuseId, for: indexPath)
            self?.configure(cell, id: id)
            return cell
        }
    }

    // MARK: Public

    public enum Section {
        case downloaded
        case available
    }

    // MARK: Internal

    class TranslationsDiffableDataSource: ActionableTableViewDiffableDataSource<Section, TranslationInfo.ID> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: TranslationInfo.ID) -> String? {
            let headers = [
                lAndroid("downloaded_translations"),
                lAndroid("available_translations"),
            ]
            return headers[section]
        }
    }

    var ds: TranslationsDiffableDataSource! // swiftlint:disable:this implicitly_unwrapped_optional

    var translations: [TranslationInfo.ID: TranslationItem] = [:] {
        didSet {
            let ids = translations.values.map(\.info.id)
            updateSnapshot(ids, oldTranslations: oldValue, newTranslations: translations)
        }
    }

    // MARK: Private

    private let actions: Actions

    private weak var tableView: UITableView?

    private func configure(_ cell: UITableViewCell?, id: TranslationInfo.ID) {
        guard let cell = cell as? TranslationTableViewCell else {
            return
        }

        guard let translation = translations[id] else {
            return
        }
        cell.checkbox.isHidden = !translation.isDownloaded
        cell.setSelection(translation.isSelected)
        cell.downloadButton.state = translation.downloadState
        cell.onShouldStartDownload = { [weak self] in
            self?.actions.startDownloading(id)
        }
        cell.onShouldCancelDownload = { [weak self] in
            self?.actions.cancelDownloading(id)
        }

        // show iPhone icon if the translation language is the same as device language
        // Always hide the icon
        cell.iPhoneIcon.isHidden = true // Locale.current.languageCode != translation.languageCode
        cell.firstLabel.text = translation.displayName
        cell.languageLabel.text = Locale(identifier: translation.languageCode).localizedString(forLanguageCode: translation.languageCode)

        if let translatorName = translation.translator, !translatorName.isEmpty {
            cell.secondLabel.attributedText = attributedTranslatorNameString(translatorName, translation: translation)
        } else {
            cell.secondLabel.attributedText = NSAttributedString()
        }
    }

    private func attributedTranslatorNameString(_ translatorName: String, translation: TranslationItem) -> NSAttributedString {
        let translator = l("translatorLabel: ")

        let lightFont = UIFont.systemFont(ofSize: 15, weight: .light)
        let regularFont = translation.info.preferredTranslatorNameFont(ofSize: .medium)

        let lightAttributes: [NSAttributedString.Key: Any] = [.font: lightFont, .foregroundColor: UIColor.secondaryLabel]
        let regularAttributes: [NSAttributedString.Key: Any] = [.font: regularFont, .foregroundColor: UIColor.label]

        let fullTranslatorText = NSMutableAttributedString(string: translator, attributes: lightAttributes)
        let translatorText = NSAttributedString(string: translatorName, attributes: regularAttributes)
        fullTranslatorText.append(translatorText)
        return fullTranslatorText
    }

    private func updateSnapshot(
        _ ids: [TranslationInfo.ID],
        oldTranslations: [TranslationInfo.ID: TranslationItem],
        newTranslations: [TranslationInfo.ID: TranslationItem]
    ) {
        if oldTranslations == newTranslations {
            return
        }

        let sortedTranslations = newTranslations.values.sorted(by: isBefore)
        let downloadedTranslations = sortedTranslations.filter(\.isDownloaded).map(\.id)
        let availableTranslations = sortedTranslations.filter { !$0.isDownloaded }.map(\.id)

        var snapshot = NSDiffableDataSourceSnapshot<Section, TranslationInfo.ID>()
        snapshot.appendSections(.downloaded)
        snapshot.appendItems(downloadedTranslations)

        snapshot.appendSections(.available)
        snapshot.appendItems(availableTranslations)

        let translationsToReload = ids.filter { oldTranslations[$0] != newTranslations[$0] }

        // animate if there are position changes
        if !snapshot.hasSameItems(ds.snapshot()) {
            snapshot.reloadItems(translationsToReload)
            ds.apply(snapshot, animatingDifferences: !oldTranslations.isEmpty)
        } else {
            // update visible cells
            reloadVisibleTranslations(Set(translationsToReload))
        }
    }

    private func reloadVisibleTranslations(_ translations: Set<TranslationInfo.ID>) {
        guard let tableView else {
            return
        }
        let visibleIndexPaths = tableView.indexPathsForVisibleRows ?? []
        for indexPath in visibleIndexPaths {
            if let id = ds.itemIdentifier(for: indexPath) {
                if translations.contains(id) {
                    let cell = tableView.cellForRow(at: indexPath)
                    configure(cell, id: id)
                }
            }
        }
    }

    private func isBefore(lhs: TranslationItem, rhs: TranslationItem) -> Bool {
        // items that should be upgraded should be at the top
        let lUpgrading = lhs.downloadState.isUpgrade()
        let rUpgrading = rhs.downloadState.isUpgrade()
        if lUpgrading != rUpgrading {
            return lUpgrading
        }

        // items with device language should be at the top
        let lIsDeviceLanguage = Locale.current.languageCode == lhs.languageCode
        let rIsDeviceLanguage = Locale.current.languageCode == rhs.languageCode
        if lIsDeviceLanguage != rIsDeviceLanguage {
            return lIsDeviceLanguage
        }

        if lhs.displayName == rhs.displayName {
            if let lhsTranslator = lhs.translator {
                if let rhsTranslator = rhs.translator {
                    return lhsTranslator.localizedStandardCompare(rhsTranslator) == .orderedAscending
                } else {
                    return true
                }
            } else {
                return false
            }
        }

        return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
    }
}
