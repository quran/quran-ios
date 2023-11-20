//
//  BundleResourceRequest.swift
//
//
//  Created by Mohamed Afifi on 2023-06-06.
//

import Foundation

public protocol BundleResourceRequest: AnyObject {
    var loadingPriority: Double { get set }
    var tags: Set<String> { get }
    var progress: Progress { get }

    func conditionallyBeginAccessingResources() async -> Bool
    func beginAccessingResources() async throws
    func endAccessingResources()
}

extension NSBundleResourceRequest: BundleResourceRequest {
}
