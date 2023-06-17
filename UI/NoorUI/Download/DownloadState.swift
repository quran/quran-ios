//
//  DownloadState.swift
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
import Foundation

public enum DownloadState: Hashable, Sendable {
    case notDownloaded
    case downloaded
    case needsUpgrade

    case pendingDownloading
    case downloading(progress: Float)

    case pendingUpgrading
    case downloadingUpgrade(progress: Float)

    // MARK: Public

    public func isUpgrade() -> Bool {
        switch self {
        case .needsUpgrade, .pendingUpgrading, .downloadingUpgrade:
            return true
        case .notDownloaded, .downloaded, .pendingDownloading, .downloading:
            return false
        }
    }

    // MARK: Internal

    var progress: Float {
        switch self {
        case .downloading(progress: let progress): return progress
        case .downloadingUpgrade(progress: let progress): return progress
        default: return 0
        }
    }
}
