//
//  SettingsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
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
import MessageUI
import UIKit

protocol SettingsPresentableListener: class {
    func viewWillAppear()
    func onThemeUpdated(to newTheme: Theme)
    func onTranslationsTapped()
    func onAudioDownloadsTapped()
    func onShareAppTapped()
    func onReviewAppTapped()
    func onContactUsTapped()
}

class SettingsViewController: BaseTableBasedViewController, SettingsPresentable, SettingsViewControllable {

    weak var listener: SettingsPresentableListener?

    private let dataSource = CompositeDataSource(sectionType: .single)
    private lazy var themeDataSource: ThemeSettingsDataSource = createThemeDataSource()
    private lazy var shareAppDataSource = createSelectableSettingsDataSource { $0?.onShareAppTapped() }

    override var screen: Analytics.Screen { return .settings }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listener?.viewWillAppear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("menu_settings")

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        tableView.ds_register(cellClass: SettingTableViewCell.self)
        tableView.ds_register(cellClass: EmptyTableViewCell.self)
        tableView.ds_register(cellNib: ThemeSelectionTableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        let translationsDataSource = createSelectableSettingsDataSource { $0?.onTranslationsTapped() }
        translationsDataSource.items = [Setting(name: lAndroid("prefs_translations"), image: #imageLiteral(resourceName: "globe-25"), zeroInset: false)]

        let audioDownloadsDataSource = createSelectableSettingsDataSource { $0?.onAudioDownloadsTapped() }
        audioDownloadsDataSource.items = [Setting(name: lAndroid("audio_manager"), image: #imageLiteral(resourceName: "download-25"), zeroInset: true)]

        shareAppDataSource.items = [Setting(name: l("share_app"), image: #imageLiteral(resourceName: "share"), zeroInset: false)]

        let reviewAppDataSource = createSelectableSettingsDataSource { $0?.onReviewAppTapped() }
        reviewAppDataSource.items = [Setting(name: l("write_review"), image: #imageLiteral(resourceName: "star_border"), zeroInset: false)]

        let contactUsDataSource = createSelectableSettingsDataSource { $0?.onContactUsTapped() }
        contactUsDataSource.items = [Setting(name: l("contact_us"), image: #imageLiteral(resourceName: "email-outline"), zeroInset: true)]

        dataSource.add(createEmptyDataSource())
        dataSource.add(themeDataSource)
        dataSource.add(createEmptyDataSource())
        dataSource.add(translationsDataSource)
        dataSource.add(audioDownloadsDataSource)
        dataSource.add(createEmptyDataSource())
        dataSource.add(shareAppDataSource)
        dataSource.add(reviewAppDataSource)
        dataSource.add(contactUsDataSource)
    }

    private func createSelectableSettingsDataSource(onSelection: @escaping (SettingsPresentableListener?) -> Void) -> SettingsDataSource {
        let selection = BlockSelectionHandler<Setting, SettingTableViewCell>()
        selection.didSelectBlock = { [weak self] ds, collectionView, indexPath in
            onSelection(self?.listener)
            collectionView.ds_deselectItem(at: indexPath, animated: true)
        }

        let itemDS = SettingsDataSource()
        itemDS.itemHeight = 51
        itemDS.setSelectionHandler(selection)
        return itemDS
    }

    private func createEmptyDataSource() -> EmptyDataSource {
        let itemDS = EmptyDataSource()
        itemDS.itemHeight = 35
        itemDS.items = [()]
        return itemDS
    }

    private func createThemeDataSource() -> ThemeSettingsDataSource {
        let itemDS = ThemeSettingsDataSource()
        itemDS.onThemeUpdated = { [weak self] newTheme in
            self?.listener?.onThemeUpdated(to: newTheme)
        }
        itemDS.itemHeight = 44
        return itemDS
    }

    func setTheme(_ theme: Theme) {
        themeDataSource.items = [theme]
        tableView?.reloadData()
    }

    func presentShareApp() {
        let url = unwrap(URL(string: "https://itunes.apple.com/app/id1118663303"))
        let appName = "Quran - by Quran.com - قرآن"

        let view: UIView = cast(shareAppDataSource.ds_reusableViewDelegate?.ds_cellForItem(at: IndexPath(item: 0, section: 0)))
        ShareController.share(textLines: [appName, url], sourceView: view, sourceRect: view.bounds, sourceViewController: self, handler: nil)
    }

    func presentContactUs() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.navigationBar.tintColor = .white
            mail.mailComposeDelegate = self
            mail.setToRecipients(["ios@quran.com"])
            mail.setSubject("Feedback about Quran for iOS App")
            present(mail, animated: true, completion: nil)
        } else {
            let controller = UIAlertController(title: nil, message: "iPhone is not configured to send emails", preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(controller, animated: true)
        }
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
