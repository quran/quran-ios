//
//  BundleResourceRequestFake.swift
//
//
//  Created by Mohamed Afifi on 2023-06-06.
//

import Foundation
import SystemDependencies

public final class BundleResourceRequestFake: BundleResourceRequest {
    public var progress = Progress()
    public var loadingPriority: Double = 0
    public let tags: Set<String>
    public init(tags: Set<String>) {
        self.tags = tags
        progress.totalUnitCount = 100
    }

    public static var resourceAvailable = true
    public func conditionallyBeginAccessingResources() async -> Bool {
        Self.resourceAvailable
    }

    public static var downloadResult: Result<Void, Error> = .success(())
    public func beginAccessingResources() async throws {
        switch Self.downloadResult {
        case .success:
            progress.completedUnitCount = progress.totalUnitCount
        case .failure(let error):
            throw error
        }
    }
}
