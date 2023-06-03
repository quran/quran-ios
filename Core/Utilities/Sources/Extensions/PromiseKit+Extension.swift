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
public func when<T>(_ guarantees: [Guarantee<T>]) -> Guarantee<[T]> {
    when(guarantees: guarantees.map { $0.asVoid() }).map(on: nil) { guarantees.map { $0.value! } }
}

public extension DispatchQueue {
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

    func asyncPromise<T>(group: DispatchGroup? = nil,
                         qos: DispatchQoS = .default,
                         flags: DispatchWorkItemFlags = [],
                         execute body: @Sendable @escaping () async throws -> T) -> Promise<T>
    {
        Promise<T> { resolver in
            async(group: group, qos: qos, flags: flags) {
                Task {
                    do {
                        resolver.fulfill(try await body())
                    } catch {
                        resolver.reject(error)
                    }
                }
            }
        }
    }
}

// TODO: Remove PromiseKit
extension Resolver: @unchecked Sendable { }
