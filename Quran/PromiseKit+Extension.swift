//
//  PromiseKit+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit

extension Promise {
    func catchToAlertView() -> Promise {
        return self.`catch`(on: .main) { error in
            let message = (error as? CustomStringConvertible)?.description ?? NSLocalizedString("NetworkError_Unknown", comment: "")
            UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
        }
    }
}
