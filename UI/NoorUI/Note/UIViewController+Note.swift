//
//  UIViewController+Note.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/24/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import UIKit

extension UIViewController {
    public func confirmNoteDelete(delete: @escaping () -> Void, cancel: @escaping () -> Void) {
        let alert = UIAlertController(
            title: l("notes.delete.alert.title"),
            message: l("notes.delete.alert.body"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: lAndroid("cancel"), style: .cancel) { _ in cancel() })
        alert.addAction(UIAlertAction(title: l("button.delete"), style: .destructive) { _ in delete() })
        present(alert, animated: true)
    }

    public func addCloudSyncInfo() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .symbol("link.icloud.fill"),
            style: .plain,
            target: self,
            action: #selector(presentCloudSyncInfo)
        )
    }

    @objc
    private func presentCloudSyncInfo() {
        let alert = UIAlertController(
            title: l("notes.icloud.alert.title"),
            message: l("notes.icloud.alert.body"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: lAndroid("dialog_ok"), style: .default, handler: nil))
        present(alert, animated: true)
    }
}
