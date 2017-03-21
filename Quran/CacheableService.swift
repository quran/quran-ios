//
//  CacheableService.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import PromiseKit

// Implementation should use reasonable caching and preloading next pages
protocol CacheableService {

    associatedtype Input: Hashable
    associatedtype Output

    func get(_ input: Input) -> Promise<Output>
}

private class _AnyCacheableServiceBoxBase<Input: Hashable, Output>: CacheableService {

    func get(_ input: Input) -> Promise<Output> { fatalError() }
}

private class _AnyCacheableServiceBox<O: CacheableService>: _AnyCacheableServiceBoxBase<O.Input, O.Output> {

    private let ds: O
    init(ds: O) {
        self.ds = ds
    }

    override func get(_ input: O.Input) -> Promise<O.Output> {
        return ds.get(input)
    }
}

class AnyCacheableService<Input: Hashable, Output>: CacheableService {

    private let box: _AnyCacheableServiceBoxBase<Input, Output>

    init<O: CacheableService>(_ ds: O) where O.Input == Input, O.Output == Output {
        box = _AnyCacheableServiceBox(ds: ds)
    }

    func get(_ input: Input) -> Promise<Output> {
        return box.get(input)
    }
}

extension CacheableService {
    func asCacheableService() -> AnyCacheableService<Input, Output> {
        return AnyCacheableService(self)
    }
}
