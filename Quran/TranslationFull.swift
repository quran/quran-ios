//
//  TranslationFull.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/1/17.
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

extension Translation {
    enum State {
        case notDownloaded
        case downloaded
        case needsUpgrade

        case pendingDownloading
        case downloading(progress: Float)

        case pendingUpgrading
        case downloadingUpgrade(progress: Float)

        fileprivate func isUpgrade() -> Bool {
            switch self {
            case .needsUpgrade, .pendingUpgrading, .downloadingUpgrade:
                return true
            case .notDownloaded, .downloaded, .pendingDownloading, .downloading:
                return false
            }
        }
    }
}

struct TranslationFull: Equatable, Comparable {
    let translation: Translation
    var downloadResponse: DownloadNetworkResponse?

    static func == (lhs: TranslationFull, rhs: TranslationFull) -> Bool {
        return lhs.translation == rhs.translation
    }

    static func < (lhs: TranslationFull, rhs: TranslationFull) -> Bool {
        let lUpgrading = lhs.state.isUpgrade()
        let rUpgrading = rhs.state.isUpgrade()
        if lUpgrading != rUpgrading {
            return lUpgrading
        }

        return lhs.translation.displayName < rhs.translation.displayName
    }
}

extension TranslationFull {

    var state: Translation.State {
        if let response = downloadResponse {
            let progress = Float(response.progress.fractionCompleted).normalized
            if translation.installedVersion != nil {
                return progress == 0 ? .pendingUpgrading : .downloadingUpgrade(progress: progress)
            } else {
                return progress == 0 ? .pendingDownloading : .downloading(progress: progress)
            }
        }

        if let installedVersion = translation.installedVersion {
            return installedVersion == translation.version ? .downloaded : .needsUpgrade
        } else {
            return .notDownloaded
        }
    }

    var downloaded: Bool {
        return translation.installedVersion != nil
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
