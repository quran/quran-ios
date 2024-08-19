//
//  AudioDownloadItem.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/4/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import Foundation
import Localization
import QuranAudio

struct AudioDownloadItem: Hashable, Comparable, Identifiable {
    enum DownloadingProgress: Hashable {
        case notDownloading
        case downloading(Double)
    }

    // MARK: Internal

    let reciter: Reciter
    let size: AudioDownloadedSize?
    let progress: DownloadingProgress

    var id: Int { reciter.id }

    static func < (lhs: Self, rhs: Self) -> Bool {
        guard let lhsSize = lhs.size, let rhsSize = rhs.size else {
            return lhs.reciter.localizedName < rhs.reciter.localizedName
        }
        if lhsSize.downloadedSizeInBytes != rhsSize.downloadedSizeInBytes {
            return lhsSize.downloadedSizeInBytes > rhsSize.downloadedSizeInBytes
        }
        return lhs.reciter.localizedName < rhs.reciter.localizedName
    }
}

extension AudioDownloadItem {
    var isDownloaded: Bool {
        size?.downloadedSuraCount == size?.surasCount
    }

    var canDelete: Bool {
        guard let size else {
            return false
        }
        return size.downloadedSizeInBytes != 0
    }
}

extension AudioDownloadedSize? {
    private static let formatter: MeasurementFormatter = {
        let units: [UnitInformationStorage] = [.bytes, .kilobytes, .megabytes, .gigabytes, .terabytes, .petabytes, .zettabytes, .yottabytes]
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .naturalScale
        formatter.locale = formatter.locale.fixedLocaleNumbers()
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }()

    func formattedString() -> String {
        guard let self else {
            return " "
        }
        let suraCount = self.downloadedSuraCount
        let size = Double(self.downloadedSizeInBytes)
        let filesDownloaded = lFormat("audio_manager_files_downloaded", table: .android, suraCount)
        let measurement = Measurement<UnitInformationStorage>(value: size, unit: .bytes)
        if suraCount == 0 {
            return filesDownloaded
        } else {
            return "\(Self.formatter.string(from: measurement)) - \(filesDownloaded)"
        }
    }
}
