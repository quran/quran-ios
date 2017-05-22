//
//  Logger.swift
//  RapidSave
//
//  Created by Nguyen Van Dung on 5/2/17.
//  Copyright © 2017 Dht. All rights reserved.
//

import Foundation

class Logger {
    class func log(_ msg: String) {
        print(msg)
    }

    class func logFunction(inClass: AnyClass, function: String) {
        Logger.log(NSStringFromClass(inClass) + "." + function)
    }
}
