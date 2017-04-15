//
//  MoyaNetworkManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
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

import Foundation
import Moya
import SwiftyJSON
import PromiseKit

class MoyaNetworkManager<Target>: NetworkManager {
    private let provider: MoyaProvider<BackendServices>
    private let parser: AnyParser<JSON, Target>

    init(provider: MoyaProvider<BackendServices>, parser: AnyParser<JSON, Target>) {
        self.provider = provider
        self.parser = parser
    }

    func execute(_ service: BackendServices) -> Promise<Target> {

        return Promise { fulfil, reject in
            provider.request(service) { [weak self] result in
                guard let `self` = self else { return }
                do {
                    switch result {
                    case var .success(moyaResponse):
                        // only accept 2xx statuses
                        moyaResponse = try moyaResponse.filterSuccessfulStatusCodes()

                        // convert response to the object
                        let data = moyaResponse.data
                        let json = JSON(data: data) // convert network data to json
                        let object: Target = try self.parser.parse(json) // convert json to object

                        // notify the response
                        fulfil(object)

                    case let .failure(error):
                        throw error
                    }
                } catch {
                    let finalError: Swift.Error
                    if let error = error as? MoyaError {
                        switch error {
                        case .underlying(let underlyingError):
                            finalError = NetworkError(error: underlyingError)
                        default:
                            finalError = NetworkError.unknown(error)
                        }
                    } else {
                        finalError = error
                    }
                    reject(finalError)
                }
            }
        }
    }
}
