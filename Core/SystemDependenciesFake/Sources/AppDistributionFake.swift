//
//  AppDistributionFake.swift
//
//
//  Created by Mohamed Afifi on 2026-11-11.
//

import SystemDependencies

public struct AppDistributionFake: AppDistribution {
    // MARK: Lifecycle

    public init(channel: AppDistributionChannel) {
        self.channel = channel
    }

    // MARK: Public

    public let channel: AppDistributionChannel
}
