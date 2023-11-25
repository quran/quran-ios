//
//  ReadingResourcesService.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import BatchDownloader
import Combine
import CombineSchedulers
import Crashing
import Foundation
import QuranKit
import SystemDependencies
import Utilities
import VLogging

public actor ReadingResourcesService {
    public enum ResourceStatus: Equatable {
        case downloading(progress: Double)
        case ready
        case error(NSError)
    }

    // MARK: Lifecycle

    public init(
        fileManager: FileSystem = DefaultFileSystem(),
        zipper: Zipper = DefaultZipper(),
        scheduler: AnySchedulerOf<DispatchQueue> = .main,
        preferencesObservingStarted: EventObserver? = nil,
        preferenceLoadingCompleted: EventObserver? = nil,
        downloader: DownloadManager,
        remoteResources: ReadingRemoteResources?
    ) {
        self.zipper = zipper
        self.fileManager = fileManager
        self.preferencesObservingStarted = preferencesObservingStarted
        self.preferenceLoadingCompleted = preferenceLoadingCompleted
        self.remoteResources = remoteResources
        self.downloader = ReadingResourceDownloader(downloader: downloader, remoteResources: remoteResources)
        self.scheduler = scheduler
    }

    // MARK: Public

    public nonisolated var publisher: AnyPublisher<ResourceStatus, Never> {
        subject
            // It helps slow down download progress a little, otherwise the UI may keep rendering progress after the download completes.
            .throttle(for: .seconds(0.1), scheduler: scheduler, latest: true)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public func startLoadingResources() async {
        let initialReading = preferences.reading
        readingsTask = Task { [weak self] in
            guard let readings = self?.preferences.$reading.prepend(initialReading).values() else {
                return
            }
            await self?.preferencesObservingStarted?()
            for await reading in readings {
                await self?.loadResourceInAsyncTask(reading)
            }
        }
        .asCancellableTask()
    }

    public func retry() async {
        loadResourceInAsyncTask(preferences.reading)
    }

    // MARK: Internal

    let preferenceLoadingCompleted: EventObserver?
    let preferencesObservingStarted: EventObserver?

    // MARK: Private

    private let preferences = ReadingPreferences.shared

    private var readingTask: CancellableTask?
    private var readingsTask: CancellableTask?

    private nonisolated let subject = CurrentValueSubject<ResourceStatus?, Never>(nil)
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let zipper: Zipper
    private let fileManager: FileSystem
    private let downloader: ReadingResourceDownloader
    private let remoteResources: ReadingRemoteResources?

    private func loadResourceInAsyncTask(_ reading: Reading) {
        readingTask = Task {
            let status = await self.loadResource(of: reading)
            self.send(status, from: reading)
            await self.preferenceLoadingCompleted?()
        }
        .asCancellableTask()
    }

    private func loadResource(of reading: Reading) async -> ResourceStatus {
        removePreviouslyDownloadedResources(exclude: reading)
        await downloader.cancelDownload(exclude: reading)

        logger.info("Resources: Start loading reading resources of: \(reading)")
        guard let remoteResource = remoteResources?.resource(for: reading) else {
            logger.info("Resources: Reading \(reading) is bundled with the app.")
            return .ready
        }

        if fileManager.fileExists(at: remoteResource.successFilePath) {
            logger.info("Resources: Reading \(reading) has been downloaded and saved locally before")
            return .ready
        }

        removeDownloadedResource(for: reading)

        do {
            // start the download
            try await downloader.download(reading) { progress in
                self.send(.downloading(progress: progress), from: reading)
            }

            // Unzip file after download completes.
            try unzipFileIfNeeded(remoteResource)

            return .ready
        } catch {
            if !(error is CancellationError) {
                crasher.recordError(error, reason: "Failed to download \(reading). Error: \(error)")
            }
            return .error(error as NSError)
        }
    }

    private func unzipFileIfNeeded(_ remoteResource: RemoteResource) throws {
        let zipFile = remoteResource.zipFile.url
        let destination = remoteResource.downloadDestination
            .appendingPathComponent(zipFile.lastPathComponent.stringByDeletingPathExtension, isDirectory: false).url

        // Delete the zip either we were able to download it or not.
        defer { try? fileManager.removeItem(at: zipFile) }

        do {
            try zipper.unzipFile(zipFile, destination: destination, overwrite: true, password: nil)

            // Write a success file to make it easy to verify if file is downloaded and unzipped successfully.
            try fileManager.writeToFile(at: remoteResource.successFilePath.url, content: "Downloaded")
        } catch {
            crasher.recordError(error, reason: "Cannot unzip file '\(zipFile)' to '\(destination)'")
            throw error
        }
    }

    private func removePreviouslyDownloadedResources(exclude reading: Reading) {
        let readings = Reading.sortedReadings.filter { $0 != reading }
        for reading in readings {
            removeDownloadedResource(for: reading)
        }
    }

    private func removeDownloadedResource(for reading: Reading) {
        guard let resource = remoteResources?.resource(for: reading) else {
            return
        }
        try? fileManager.removeItem(at: resource.downloadDestination)
    }

    private nonisolated func send(_ status: ResourceStatus, from reading: Reading) {
        if preferences.reading != reading {
            return
        }
        subject.send(status)
    }
}
