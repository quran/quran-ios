//
//  OnDemandResource.swift
//
//
//  Created by Mohamed Afifi on 2023-02-19.
//

import Combine
import Foundation
import SystemDependencies
import VLogging

struct OnDemandResource {
    // MARK: Lifecycle

    public init(request: BundleResourceRequest) {
        self.request = request
        request.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
    }

    // MARK: Internal

    func fetch(onProgressChange: @Sendable @escaping (Double) -> Void) async throws {
        logger.info("Fetching resources \(request.tags)")
        let available = await request.conditionallyBeginAccessingResources()
        logger.info("Resources \(request.tags) availability \(available)")
        if available {
            return
        }
        let cancellable = request.progress
            .publisher(for: \.fractionCompleted)
            .sink(receiveValue: onProgressChange)
        defer {
            cancellable.cancel()
        }
        do {
            try await request.beginAccessingResources()
            logger.info("Resources \(request.tags) downloaded")
        } catch {
            logger.error("Resources \(request.tags) failed. Error: \(error)")
            throw error
        }
    }

    // MARK: Private

    private let request: BundleResourceRequest
}
