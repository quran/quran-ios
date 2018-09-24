//
//  CollectionResponse.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/17.
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

open class CollectionResponse: Response {
    public let responses: [Response]
    public let progress: QProgress

    private let completionLock = NSLock()

    public init(responses: [Response]) {
        self.responses = responses
        self.progress = QProgress(totalUnitCount: Double(responses.count))
        createParentProgress()
    }

    open func cancel() {
        responses.forEach { $0.cancel() }
    }

    private var completions: [(Result<()>) -> Void] = []

    open var result: Result<()>? {
        didSet {
            if let result = result {
                for completion in completions {
                    completion(result)
                }
            }
        }
    }

    open func addCompletion(_ completion: @escaping (Result<()>) -> Void) {
        completions.append(completion)
        if let result = result {
            completion(result)
        }
    }

    private func createParentProgress() {
        responses.forEach { progress.add(child: $0.progress, withPendingUnitCount: 1) }

        var completed = 0
        let total = responses.count
        for download in responses {
            download.addCompletion { [weak self] result in
                guard let `self` = self else {
                    return
                }

                let allCompleted: Bool = self.completionLock.synchronized {
                    completed += 1
                    return completed == total
                }

                // if error occurred, stop downloads
                if let error = result.error {
                    self.cancel() // cancel other downloads
                    self.result = .failure(error)
                } else {
                    if allCompleted {
                        self.result = .success(())
                    }
                }
            }
        }
    }
}
