//
//  Cast.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

func cast<T>(object: Any) -> T {
    guard let value = object as? T else {
        fatalError("Couldn't cast object of type '\(object.dynamicType)' to '\(T.self)' where object value is '\(object)'")
    }
    return value
}
