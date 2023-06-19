//
//  AudioDownloadsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import BatchDownloader
import Localization
import QuranAudio
import ReciterService
import UIKit
import UIx

@MainActor
class AudioDownloadsDataSource {
    struct Actions {
        let cancelDownloading: (AudioDownloadItem) -> Void
        let startDownloading: (AudioDownloadItem) -> Void
    }

    // MARK: Lifecycle

    init(tableView: UITableView, actions: Actions) {
        self.actions = actions
        self.tableView = tableView
        ds = ActionableTableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, reciter in
            let cell = tableView.dequeueReusableCell(withIdentifier: AudioDownloadTableViewCell.reuseId, for: indexPath)
            self?.configure(cell, reciter: reciter)
            return cell
        }
    }

    // MARK: Internal

    var ds: ActionableTableViewDiffableDataSource<DefaultSection, Reciter>! // swiftlint:disable:this implicitly_unwrapped_optional

    var downloads: [Reciter: AudioDownloadItem] = [:] {
        didSet {
            let reciters = downloads.values.sorted().map(\.reciter)
            update(reciters, oldDownloads: oldValue, newDownloads: downloads)
        }
    }

    // MARK: Private

    private let actions: Actions

    private weak var tableView: UITableView?

    private func update(_ reciters: [Reciter], oldDownloads: [Reciter: AudioDownloadItem], newDownloads: [Reciter: AudioDownloadItem]) {
        if oldDownloads == newDownloads {
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<DefaultSection, Reciter>()
        snapshot.appendSections(.default)
        snapshot.appendItems(reciters)

        let recitersToReload = reciters.filter { oldDownloads[$0] != newDownloads[$0] }

        // animate if there are position changes
        if !snapshot.hasSameItems(ds.snapshot()) {
            snapshot.reloadItems(recitersToReload)
            ds.apply(snapshot, animatingDifferences: !oldDownloads.isEmpty)
        } else {
            // update visible cells
            reloadVisibleReciters(Set(recitersToReload))
        }
    }

    private func reloadVisibleReciters(_ reciters: Set<Reciter>) {
        guard let tableView else {
            return
        }
        let visibleIndexPaths = tableView.indexPathsForVisibleRows ?? []
        for indexPath in visibleIndexPaths {
            if let reciter = ds.itemIdentifier(for: indexPath) {
                if reciters.contains(reciter) {
                    let cell = tableView.cellForRow(at: indexPath)
                    configure(cell, reciter: reciter)
                }
            }
        }
    }

    private func configure(_ cell: UITableViewCell?, reciter: Reciter) {
        guard let cell = cell as? AudioDownloadTableViewCell else {
            return
        }

        guard let item = downloads[reciter] else {
            return
        }
        cell.configure(with: item)
        cell.downloadButton.state = item.downloadState
        cell.onShouldStartDownload = { [weak self] in
            self?.actions.startDownloading(item)
        }
        cell.onShouldCancelDownload = { [weak self] in
            self?.actions.cancelDownloading(item)
        }
    }
}

private extension AudioDownloadTableViewCell {
    private static let formatter: MeasurementFormatter = {
        let units: [UnitInformationStorage] = [.bytes, .kilobytes, .megabytes, .gigabytes, .terabytes, .petabytes, .zettabytes, .yottabytes]
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .naturalScale
        formatter.locale = formatter.locale.fixedLocaleNumbers()
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }()

    func configure(with download: AudioDownloadItem) {
        photoImageView.isHidden = true
        firstLabel.text = download.name
        secondLabel.text = formattedSize(download.size)
    }

    private func formattedSize(_ size: AudioDownloadItem.Size?) -> String {
        guard let downloadSize = size else {
            return " "
        }

        let suraCount = downloadSize.downloadedSuraCount
        let size = Double(downloadSize.downloadedSizeInBytes)
        let filesDownloaded = lFormat("files_downloaded", table: .android, suraCount)
        let measurement = Measurement<UnitInformationStorage>(value: size, unit: .bytes)
        if suraCount == 0 {
            return filesDownloaded
        } else {
            return "\(Self.formatter.string(from: measurement)) - \(filesDownloaded)"
        }
    }
}
