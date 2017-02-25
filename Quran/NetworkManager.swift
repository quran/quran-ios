//
//  NetworkManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

protocol NetworkManager {
    associatedtype Target

    func execute(_ service: BackendServices) -> NetworkResponse<Target>
}

struct AnyNetworkManager<Target>: NetworkManager {
    let executeClosure: (BackendServices) -> NetworkResponse<Target>
    init<NetworkManagerType: NetworkManager>(_ networkManager: NetworkManagerType) where NetworkManagerType.Target == Target {
        executeClosure = networkManager.execute
    }

    func execute(_ service: BackendServices) -> NetworkResponse<Target> {
        return executeClosure(service)
    }
}
