//
//  DownloadRequest.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol NetworkRequest {

    var progress: NSProgress { get }

    func resume()
    func suspend()
    func cancel()
}
