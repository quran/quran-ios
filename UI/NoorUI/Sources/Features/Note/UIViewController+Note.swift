//
//  UIViewController+Note.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/24/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import QuranAnnotations
import UIKit
import UIx

extension UIViewController {
    public func confirmNoteDelete(delete: @escaping AsyncAction, cancel: @escaping () -> Void) {
        let alert = UIAlertController(
            title: l("notes.delete.alert.title"),
            message: l("notes.delete.alert.body"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: lAndroid("cancel"), style: .cancel) { _ in cancel() })
        alert.addAction(UIAlertAction(title: l("button.delete"), style: .destructive) { _ in
            Task {
                await delete()
            }
        })
        present(alert, animated: true)
    }

    public func confirmSyncedNoteDelete(delete: @escaping AsyncAction, cancel: @escaping () -> Void) {
        let alert = UIAlertController(
            title: l("notes.delete-note.alert.title"),
            message: l("notes.delete-note.alert.body"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: lAndroid("cancel"), style: .cancel) { _ in cancel() })
        alert.addAction(UIAlertAction(title: l("button.delete"), style: .destructive) { _ in
            Task {
                await delete()
            }
        })
        present(alert, animated: true)
    }

    public func showNoteMinimumLengthAlert(minimumLength: Int) {
        showNoteLengthAlert(
            title: l("notes.minimum-length.alert.title"),
            message: lFormat("notes.minimum-length.alert.body", minimumLength)
        )
    }

    public func showNoteLengthLimitAlert(_ error: TextLengthLimitError) {
        let title = switch error.bound {
        case .tooShort: l("notes.minimum-length.alert.title")
        case .tooLong: l("notes.maximum-length.alert.title")
        }
        showNoteLengthAlert(title: title, message: error.localizedMessage)
    }

    public func addCloudSyncInfo() {
        navigationItem.leftBarButtonItem = NavigationBarButton.secondary(
            systemName: "link.icloud",
            accessibilityLabel: l("notes.icloud.alert.title"),
            glassSymbolScale: .medium
        ) { [weak self] in
            self?.presentCloudSyncInfo()
        }
    }

    private func showNoteLengthAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: lAndroid("dialog_ok"), style: .default, handler: nil))
        present(alert, animated: true)
    }

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
