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

import PromiseKit

// TODO: REVIEW ME

extension Promise {

    public func cauterize(tag: StaticString?) {
        `catch` { error in
            let message: String
            if let tag = tag {
                message = "PromiseKit: [\(tag)] unhandled error: \(error)"
            } else {
                message = "PromiseKit: unhandled error: \(error)"
            }
            Crash.recordError(error, reason: message, fatalErrorOnDebug: false)
        }
    }

    public func cauterize(function: StaticString = #function) {
        return cauterize(tag: function)
    }

    @available(*, deprecated, message: "Use cauterize instead or handle the error")
    public func suppress() {
        return cauterize(tag: "Suppress")
    }
}

extension URLSession {
    public func getTasks() -> Guarantee<([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])> {
        return Guarantee { getTasksWithCompletionHandler($0) }
    }
}

extension OperationQueue {

    public func async<T>(_ namespace: PMKNamespacer, execute body: @escaping () throws -> T) -> Promise<T> {
        return Promise(resolver: { resolver in
            addOperation {
                do {
                    resolver.fulfill(try body())
                } catch {
                    resolver.reject(error)
                }
            }
        })
    }

    public func async<T>(_ namespace: PMKNamespacer, execute body: @escaping () -> T) -> Guarantee<T> {
        return Guarantee { resolver in
            addOperation { resolver(body()) }
        }
    }
}

extension DispatchGroup {
    public final func notify(on q: DispatchQueue = .global()) -> Guarantee<Void> {
        return Guarantee { resolve in
            self.notify(queue: q) { resolve(()) }
        }
    }
}

extension Guarantee where T: Collection {
    public func parallelMap<U>(on q: DispatchQueue = .global(), execute body: @escaping (T.Iterator.Element) -> U) -> Guarantee<[U]> {
        return then(on: q) { collection in
            Guarantee<[U]> { resolver in
                resolver(collection.parallelMap(body))
            }
        }
    }
}

public protocol OptionalConvertible {
    associatedtype Wrapped
    func asOptional() -> Wrapped?
}

extension Optional: OptionalConvertible {
    public func asOptional() -> Wrapped? { return self }
}

extension Guarantee where T: OptionalConvertible {
    public func `do`(on q: DispatchQueue = .global(), execute body: @escaping (T.Wrapped) -> Void) -> Promise<T> {
        return map(on: q) { value -> T in
            if let wrapped = value.asOptional() {
                body(wrapped)
            }
            return value
        }
    }
}

extension Guarantee {
    @available(*, deprecated, message: "It should not be needed")
    public func asPromise() -> Promise<T> {
        return Promise(self)
    }
}
// swiftlint:disable force_unwrapping
/// Wait for all guaratnees in a set to fulfill.
public func when<U, V>(_ pu: Guarantee<U>, _ pv: Guarantee<V>) -> Guarantee<(U, V)> {
    return when(pu.asVoid(), pv.asVoid()).map(on: nil) { (pu.value!, pv.value!) }
}

/// Wait for all guaratnees in a set to fulfill.
public func when<U, V, W>(_ pu: Guarantee<U>, _ pv: Guarantee<V>, _ pw: Guarantee<W>) -> Guarantee<(U, V, W)> {
    return when(pu.asVoid(), pv.asVoid(), pw.asVoid()).map(on: nil) { (pu.value!, pv.value!, pw.value!) }
}

/// Wait for all guaratnees in a set to fulfill.
public func when<U, V, W, X>(_ pu: Guarantee<U>, _ pv: Guarantee<V>, _ pw: Guarantee<W>, _ px: Guarantee<X>) -> Promise<(U, V, W, X)> {
    return when(pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid()).map(on: nil) { (pu.value!, pv.value!, pw.value!, px.value!) }
}
// swiftlint:enable force_unwrapping
