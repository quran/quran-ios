//
//  Utilities.swift
//
//
//  Created by Mohamed Afifi on 2021-12-31.
//

import Foundation
import PromiseKit

extension NetworkSession {
    func tasks() -> Guarantee<([NetworkSessionDataTask], [NetworkSessionUploadTask], [NetworkSessionDownloadTask])> {
        Guarantee { resolver in
            getTasksWithCompletionHandler { resolver(($0, $1, $2)) }
        }
    }
}
