//
//  Downloadable.swift
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

enum DownloadState {
    case notDownloaded
    case downloaded
    case needsUpgrade

    case pendingDownloading
    case downloading(progress: Float)

    case pendingUpgrading
    case downloadingUpgrade(progress: Float)

    func isUpgrade() -> Bool {
        switch self {
        case .needsUpgrade, .pendingUpgrading, .downloadingUpgrade:
            return true
        case .notDownloaded, .downloaded, .pendingDownloading, .downloading:
            return false
        }
    }

    var progress: Float {
        switch self {
        case .downloading(progress: let progress): return progress
        case .downloadingUpgrade(progress: let progress): return progress
        default: return 0
        }
    }
}

protocol Downloadable {

    var response: Response? { get set }
    var isDownloaded: Bool { get }
    var needsUpgrade: Bool { get }
}

extension Downloadable {

    var state: DownloadState {
        if let response = response {
            let progress = Float(response.progress.progress).normalized
            if isDownloaded {
                return progress == 0 ? .pendingUpgrading : .downloadingUpgrade(progress: progress)
            } else {
                return progress == 0 ? .pendingDownloading : .downloading(progress: progress)
            }
        }

        if isDownloaded {
            return needsUpgrade ? .needsUpgrade : .downloaded
        } else {
            return .notDownloaded
        }
    }
}

extension Float {

    var normalized: Float {
        if abs(self) < 0.001 {
            return 0
        } else {
            return self
        }
    }
}
