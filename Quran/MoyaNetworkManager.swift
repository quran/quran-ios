//
//  MoyaNetworkManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON

class MoyaNetworkManager<Target>: NetworkManager {
    private let provider: MoyaProvider<BackendServices>
    private let parser: AnyParser<JSON, Target>

    init(provider: MoyaProvider<BackendServices>, parser: AnyParser<JSON, Target>) {
        self.provider = provider
        self.parser = parser
    }

    func execute(_ service: BackendServices) -> NetworkResponse<Target> {
        let outerProgress = Foundation.Progress(totalUnitCount: 100)

        var response: NetworkResponse<Target>! = nil

        let cancellable = provider.request(.translations, queue: nil, progress: { (progress: ProgressResponse) in
            outerProgress.completedUnitCount = Int64(progress.progress * 100)
        }, completion: { [weak self] result in
            guard let `self` = self else { return }
            do {
                switch result {
                case let .success(moyaResponse):
                    // only accept 2xx statuses
                    _ = try moyaResponse.filterSuccessfulStatusCodes()

                    // convert response to the object
                    let data = moyaResponse.data
                    let json = JSON(data: data) // convert network data to json
                    let object: Target = try self.parser.parse(json) // convert json to object

                    // notify the response
                    response?.result = .success(object)

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
                        finalError = NetworkError.unknown
                    }
                } else {
                    finalError = error
                }
                response?.result = .failure(finalError)
            }
        })

        response = NetworkResponse<Target>(cancellable: cancellable, progress: outerProgress)
        return response
    }
}
