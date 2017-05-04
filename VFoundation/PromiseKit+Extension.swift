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

    public func suppress() {
        return cauterize(tag: "Suppress")
    }
}

extension URLSession {
    public func getTasks() -> Promise<([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])> {
        return wrap(getTasksWithCompletionHandler)
    }
}

extension OperationQueue {

    public func promise<T>(execute body: @escaping () throws -> T) -> Promise<T> {
        return Promise(resolvers: { (fulfill, reject) in
            addOperation {
                do {
                    fulfill(try body())
                } catch {
                    reject(error)
                }
            }
        })
    }

    public func promise2<T>(execute body: @escaping () throws -> T) -> Promise<T> {

        // if the same operation queue, then execute it immediately
        if self == OperationQueue.current {
            do {
                return Promise(value: try body())
            } catch {
                return Promise(error: error)
            }
        }

        return Promise(resolvers: { (fulfill, reject) in
            addOperation {
                do {
                    fulfill(try body())
                } catch {
                    reject(error)
                }
            }
        })
    }
}

extension DispatchQueue {
    public final func promise2<T>(execute body: @escaping () throws -> T) -> Promise<T> {
        return Promise(resolvers: { (fulfill, reject) in
            if self === zalgo || self === waldo && !Thread.isMainThread {
                fulfill(try body())
            } else {
                async {
                    do {
                        fulfill(try body())
                    } catch {
                        reject(error)
                    }
                }
            }
        })
    }
}

extension DispatchGroup {
    public final func notify(on q: DispatchQueue = .default) -> Promise<Void> {
        return Promise(resolvers: { (fulfill, _) in
            self.notify(queue: q, execute: fulfill)
        })
    }
}

extension Promise where T: Sequence {
    public func parallelMap<U>(on q: DispatchQueue = .default, execute body: @escaping (T.Iterator.Element) throws -> U) -> Promise<[U]> {
        return then(on: zalgo) { sequence -> Promise<[U]> in

            var promises: [Promise<U>] = []
            for item in sequence {
                promises.append(q.promise2 {
                    try body(item)
                })
            }
            return when(fulfilled: promises)
        }
    }

    public func map<U>(on q: DispatchQueue = .default, execute body: @escaping (T.Iterator.Element) throws -> U) -> Promise<[U]> {
        return then(on: q) { sequence -> [U] in
            var array: [U] = []
            for item in sequence {
                array.append(try body(item))
            }
            return array
        }
    }

    public func map<U>(on q: DispatchQueue = .default, execute body: @escaping (T.Iterator.Element) throws -> Promise<U>) -> Promise<[U]> {
        return then(on: q) { sequence -> Promise<[U]> in
            var array: [Promise<U>] = []
            for item in sequence {
                array.append(try body(item))
            }
            return when(fulfilled: array)

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

extension ImplicitlyUnwrappedOptional: OptionalConvertible {
    public func asOptional() -> Wrapped? { return self }
}

extension Promise where T: OptionalConvertible {
    public func `do`(on q: DispatchQueue = .default, execute body: @escaping (T.Wrapped) throws -> Void) -> Promise<T> {
        return then(on: q) { value -> T in
            if let wrapped = value.asOptional() {
                try body(wrapped)
            }
            return value
        }
    }
}
