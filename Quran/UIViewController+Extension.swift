//
//  UIViewController+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/27/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
        if let error = self as? CustomStringConvertible {
            return error.description
        }
        return NSLocalizedString("NetworkError_Unknown", comment: "")
    }
}
