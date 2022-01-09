//
//  AnyCacheableService.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/25/17.
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

public struct AnyCacheableService<Input: Hashable, Output>: CacheableService {
    private let _invalidate: () -> Void
    private let _get: (Input) -> Promise<Output>
    private let _getCached: (Input) -> Output?

    public init<O: CacheableService>(_ cs: O) where O.Input == Input, O.Output == Output {
        _invalidate = cs.invalidate
        _get = cs.get
        _getCached = cs.getCached
    }

    public func invalidate() {
        _invalidate()
    }

    public func get(_ input: Input) -> Promise<Output> {
        _get(input)
    }

    public func getCached(_ input: Input) -> Output? {
        _getCached(input)
    }
}
