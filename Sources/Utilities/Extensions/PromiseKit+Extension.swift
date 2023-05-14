//
//  PromiseKit+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import PromiseKit

/// Wait for all guaratnees in a set to fulfill.
public func when<U, V>(_ pu: Guarantee<U>, _ pv: Guarantee<V>) -> Guarantee<(U, V)> {
    when(pu.asVoid(), pv.asVoid()).map(on: nil) { (pu.value!, pv.value!) }
}

/// Wait for all guaratnees in a set to fulfill.
public func when<U, V, W>(_ pu: Guarantee<U>, _ pv: Guarantee<V>, _ pw: Guarantee<W>) -> Guarantee<(U, V, W)> {
    when(pu.asVoid(), pv.asVoid(), pw.asVoid()).map(on: nil) { (pu.value!, pv.value!, pw.value!) }
}

/// Wait for all guaratnees in a set to fulfill.
public func when<U, V, W, X>(_ pu: Guarantee<U>, _ pv: Guarantee<V>, _ pw: Guarantee<W>, _ px: Guarantee<X>) -> Promise<(U, V, W, X)> {
    when(pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid()).map(on: nil) { (pu.value!, pv.value!, pw.value!, px.value!) }
}

/// Wait for all guaratnees in a set to fulfill.
public func when<T>(_ guarantees: [Guarantee<T>]) -> Guarantee<[T]> {
    when(guarantees: guarantees.map { $0.asVoid() }).map(on: nil) { guarantees.map { $0.value! } }
}

public extension DispatchQueue {
    /**
     Asynchronously executes the provided closure on a dispatch queue.

         DispatchQueue.global().async(.guaratnee) {
            try md5(input)
         }.done { md5 in
            //…
         }

     - Parameter body: The closure that resolves this promise.
     - Returns: A new `Guarantee` resolved by the result of the provided closure.
     */
    @available(macOS 10.10, iOS 8.0, watchOS 2.0, *)
    final func async<T>(
        _: PMKGuaranteeNamespacer,
        group: DispatchGroup? = nil,
        qos: DispatchQoS = .default,
        flags: DispatchWorkItemFlags = [],
        execute body: @Sendable @escaping () -> T
    ) -> Guarantee<T> {
        Guarantee<T> { resolver in
            self.async(group: group, qos: qos, flags: flags) {
                resolver(body())
            }
        }
    }

    func asyncGuarantee<T>(group: DispatchGroup? = nil,
                           qos: DispatchQoS = .default,
                           flags: DispatchWorkItemFlags = [],
                           execute body: @Sendable @escaping () async -> T) -> Guarantee<T>
    {
        Guarantee<T> { resolver in
            async(group: group, qos: qos, flags: flags) {
                Task {
                    resolver(await body())
                }
            }
        }
    }
}

/// used by our extensions to provide unambiguous functions with the same name as the original function
public enum PMKGuaranteeNamespacer {
    case guarantee
}

// TODO: Remove PromiseKit
extension Resolver: @unchecked Sendable { }
