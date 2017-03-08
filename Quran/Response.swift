//
//  Response.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol Response: class {

    var progress: Foundation.Progress { get }

    var onCompletion: ((Result<()>) -> Void)? { get set }
    var result: Result<()>? { get set }

    func resume()
    func suspend()
    func cancel()
}
