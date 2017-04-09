//
//  UIViewController+Extension.swift
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

import UIKit

extension UIViewController {
    func showErrorAlert(error: Error) {
        Crash.recordError(error, reason: "showErrorAlert", fatalErrorOnDebug: false)
        let message = error.getLocalizedDescription()
        let controller = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(controller, animated: true)
    }
}

extension Error {
    fileprivate func getLocalizedDescription() -> String {
        if let error = self as? QuranError {
            return error.localizedDescriptionv2
        }
        return NSLocalizedString("NetworkError_Unknown", comment: "")
    }
}
