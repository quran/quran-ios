//
//  NetworkManager.swift
//
//
//  Created by Mohamed Afifi on 2021-12-27.
//

import BatchDownloader
import Foundation
import PromiseKit

protocol NetworkManager {
    func request(_ path: String, parameters: [(String, String)]) -> Promise<Data>
}

extension BatchDownloader.NetworkManager: NetworkManager { }
