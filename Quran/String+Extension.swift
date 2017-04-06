//
//  String+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/25/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import UIKit

extension String {

    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    var stringByDeletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
    var stringByDeletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    var pathComponents: [String] {
        return (self as NSString).pathComponents
    }
}
