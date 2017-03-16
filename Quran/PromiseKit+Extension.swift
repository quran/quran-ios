//
//  PromiseKit+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit
import UIKit

extension Promise {

    @discardableResult
    func catchToAlertView(viewController: UIViewController?) -> Promise {
        return self.`catch`(on: .main) { [weak viewController] error in
            viewController?.showErrorAlert(error: error)
        }
    }
}

extension Promise {

    public func cauterize(tag: String? = nil) {
        `catch` { error in
            if let tag = tag {
                print("PromiseKit: [\(tag)] unhandled error:", error)
            } else {
                print("PromiseKit: unhandled error:", error)
            }
        }
    }
}
