//
//  UIViewController+Error.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/27/17.
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

import Crashing
import Localization
import UIKit

extension UIViewController {
    public func showErrorAlert(error: Error) {
        if error.isCancelled {
            return
        }
        if Thread.current.isMainThread {
            _showErrorAlert(error: error)
        } else {
            DispatchQueue.main.async {
                self._showErrorAlert(error: error)
            }
        }
    }

    private func _showErrorAlert(error: Error) {
        crasher.recordError(error, reason: "showErrorAlert")
        let message = error.getErrorDescription()
        let controller = UIAlertController(title: l("error.dialog.title"), message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(controller, animated: true)
    }
}

extension Error {
    func getErrorDescription() -> String {
        let description = (self as? LocalizedError)?.errorDescription
        return description ?? l("error.message.general")
    }
}

extension Error {
    var isCancelled: Bool {
        if self is CancellationError {
            return true
        }

        do {
            throw self
        } catch URLError.cancelled {
            return true
        } catch CocoaError.userCancelled {
            return true
        } catch {
            return false
        }
    }
}
