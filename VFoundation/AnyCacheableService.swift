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

private class _AnyCacheableServiceBoxBase<Input: Hashable, Output>: CacheableService {

    func invalidate() { expectedToBeSubclassed() }
    func get(_ input: Input) -> Guarantee<Output> { expectedToBeSubclassed() }
    func getCached(_ input: Input) -> Output? { expectedToBeSubclassed() }
}

private class _AnyCacheableServiceBox<O: CacheableService>: _AnyCacheableServiceBoxBase<O.Input, O.Output> {

    private let ds: O
    init(ds: O) {
        self.ds = ds
    }

    override func invalidate() {
        return ds.invalidate()
    }

    override func get(_ input: O.Input) -> Guarantee<O.Output> {
        return ds.get(input)
    }

    override func getCached(_ input: O.Input) -> O.Output? {
        return ds.getCached(input)
    }
}

public final class AnyCacheableService<Input: Hashable, Output>: CacheableService {

    private let box: _AnyCacheableServiceBoxBase<Input, Output>

    public init<O: CacheableService>(_ ds: O) where O.Input == Input, O.Output == Output {
        box = _AnyCacheableServiceBox(ds: ds)
    }

    public func invalidate() {
        return box.invalidate()
    }

    public func get(_ input: Input) -> Guarantee<Output> {
        return box.get(input)
    }

    public func getCached(_ input: Input) -> Output? {
        return box.getCached(input)
    }
}

extension CacheableService {
    public func asCacheableService() -> AnyCacheableService<Input, Output> {
        return AnyCacheableService(self)
    }
}
