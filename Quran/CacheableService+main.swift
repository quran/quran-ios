//
//  CacheableService+main.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

extension CacheableService {
    func getOnMainThread(_ input: Input, function: StaticString = #function, _ body: @escaping (Output?) -> Void) {
        precondition(Thread.current.isMainThread, "Execute \(#function) only on main thread.")
        if let result = getCached(input) {
            body(result)
            return
        }

        // we will reload
        body(nil)

        // load remotely
        self.get(input)
            .then(on: .main, execute: body)
            .cauterize(tag: function)
    }
}
