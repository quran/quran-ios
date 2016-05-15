//
//  DownloadRequest.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol Request: class {

    var progress: NSProgress { get }

    var onCompletion: (Result<()> -> Void)? { get set }

    func resume()
    func suspend()
    func cancel()
}
