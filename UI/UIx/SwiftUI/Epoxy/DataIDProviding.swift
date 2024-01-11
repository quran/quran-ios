// From: https://github.com/airbnb/epoxy-ios/blob/ecee1ace58d58e3cc918a2dea28095de713b1112

// Created by eric_horacek on 12/1/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

// MARK: - DefaultDataID

/// The default data ID when none is provided.
public enum DefaultDataID: Hashable, CustomDebugStringConvertible {
    case noneProvided

    // MARK: Public

    public var debugDescription: String {
        "DefaultDataID.noneProvided"
    }
}
