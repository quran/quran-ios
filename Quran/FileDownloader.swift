//
//  FileDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol FileDownloader {

    var startRequestsImmediately: Bool { get set }

    func downloadOrResume(
        remoteBaseURL: NSURL,
        localBaseDirectory: NSURL,
        fileName: String,
        fileExtension: String,
        completionHandler: Result<(), NetworkError> -> Void) -> NetworkRequest
}
