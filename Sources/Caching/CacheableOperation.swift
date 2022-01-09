//
//  CacheableOperation.swift
//
//
//  Created by Afifi, Mohamed on 11/11/21.
//

import Foundation
import PromiseKit

public protocol CacheableOperation {
    associatedtype Input
    associatedtype Output
    func perform(_ input: Input) -> Promise<Output>
}
