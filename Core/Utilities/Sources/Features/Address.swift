//
//  Address.swift
//
//
//  Created by Mohamed Afifi on 2023-05-27.
//

import Foundation

public func address(of o: some AnyObject) -> String {
    let add = unsafeBitCast(o, to: Int.self)
    return NSString(format: "%p", add) as String
}

public func nameAndAddress(of o: some AnyObject) -> String {
    "<\(type(of: o)): \(address(of: o))>"
}
