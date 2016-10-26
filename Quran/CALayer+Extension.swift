//
//  CALayer+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit


extension CALayer {

    class func withoutAnimation(_ block: () -> Void) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        block()
        CATransaction.commit()
    }
}
