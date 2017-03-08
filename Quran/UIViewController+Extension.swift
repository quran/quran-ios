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
        let message = (error as? CustomStringConvertible)?.description ?? NSLocalizedString("NetworkError_Unknown", comment: "")
        let controller = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(controller, animated: true)
    }
}
