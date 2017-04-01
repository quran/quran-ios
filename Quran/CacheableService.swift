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

    func invalidate()
    func get(_ input: Input) -> Promise<Output>
    func getCached(_ input: Input) -> Output?
}
