//
//  DownloadRequest.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/11/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

struct DownloadRequest {
    let method: HTTPMethod
    let url: URL
    let headers: [String: String]?
    let destination: String
    let resumeDestination: String
}
