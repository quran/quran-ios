//
//  _Utilities.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 10/23/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

extension NSObjectProtocol {
    func cast<T, U>(_ value: T, file: StaticString = #file, line: UInt = #line) -> U {
        return cast(value, message: "Couldn't cast object '\(value)' to '\(U.self)'", file: file, line: line)
    }

    func cast<T, U>(_ value: T, message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) -> U {
        guard let castedValue = value as? U else {
            fatalError("[\(type(of: self))]: \(message()); file: \(file); line: \(line);")
        }
        return castedValue
    }

    func optionalCast<T, U>(_ value: T?, file: StaticString = #file, line: UInt = #line) -> U? {
        return optionalCast(value, message: "Couldn't cast object '\(String(describing: value))' to '\(U.self)'", file: file, line: line)
    }

    func optionalCast<T, U>(_ value: T?, message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) -> U? {
        guard let unwrappedValue = value else {
            return nil
        }
        guard let castedValue = unwrappedValue as? U else {
            fatalError("[\(type(of: self))]: \(message()); file: \(file); line: \(line);")
        }
        return castedValue
    }

    func subclassHasDifferentImplmentation(type typeOf: AnyClass, selector: Selector) -> Bool {

        let subclassImp = method_getImplementation(class_getInstanceMethod(type(of: self), selector)!)
        let superImp = method_getImplementation(class_getInstanceMethod(typeOf, selector)!)
        return subclassImp != superImp
    }
}

func describe(_ object: AnyObject, properties: [(String, Any?)]) -> String {
    let address = String(format: "%p", unsafeBitCast(object, to: Int.self))
    let typeOf: AnyObject.Type = type(of: object)
    let propertiesDescription = properties.filter { $1 != nil }.map { "\($0)=\($1!))" }.joined(separator: " ;")
    return "<\(typeOf): \(address); \(propertiesDescription)>"
}

func isSelector(_ selector: Selector, belongsToProtocol aProtocol: Protocol) -> Bool {
    return isSelector(selector, belongsToProtocol: aProtocol, isRequired: true, isInstance: true) ||
        isSelector(selector, belongsToProtocol: aProtocol, isRequired: false, isInstance: true)
}

func isSelector(_ selector: Selector, belongsToProtocol aProtocol: Protocol, isRequired: Bool, isInstance: Bool) -> Bool {
    let method = protocol_getMethodDescription(aProtocol, selector, isRequired, isInstance)
    return method.types != nil
}

#if swift(>=4.2)
let headerKind = UICollectionView.elementKindSectionHeader
let footerKind = UICollectionView.elementKindSectionFooter
#else
let headerKind = UICollectionElementKindSectionHeader
let footerKind = UICollectionElementKindSectionFooter
#endif
