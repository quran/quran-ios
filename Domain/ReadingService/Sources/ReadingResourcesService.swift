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
    // MARK: Lifecycle

    /// - Parameters:
    ///   - removeOtherReadings: Whether loading a reading deletes other readings' downloaded resources.
    ///     Integration tests pass `false` to retain resources while checking multiple mushafs.
    ///   - bundledReadings: The readings the app bundles. Defaults to the readings found in the main bundle.
    public init(
        fileManager: FileSystem = DefaultFileSystem(),
        zipper: Zipper = DefaultZipper(),
        scheduler: AnySchedulerOf<DispatchQueue> = .main,
        throttleInterval: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.1),
        preferencesObservingStarted: EventObserver? = nil,
        preferenceLoadingCompleted: EventObserver? = nil,
        downloader: DownloadManager,
        remoteResources: ReadingRemoteResources?,
        removeOtherReadings: Bool = true,
        bundledReadings: Set<Reading>? = nil
    ) {
        self.bundledReadings = bundledReadings ?? Set(Reading.allReadings.filter {
            Bundle.main.url(forResource: $0.localPath, withExtension: nil) != nil
        })
        self.zipper = zipper
        self.fileManager = fileManager
        self.preferencesObservingStarted = preferencesObservingStarted
        self.preferenceLoadingCompleted = preferenceLoadingCompleted
        self.remoteResources = remoteResources
        self.removeOtherReadings = removeOtherReadings
        self.downloader = ReadingResourceDownloader(downloader: downloader, remoteResources: remoteResources)
        self.scheduler = scheduler
        self.throttleInterval = throttleInterval
    }

    // MARK: Public

    public enum ResourceStatus: Equatable {
        case downloading(progress: Double)
        case ready
        case error(NSError)
    }

    public nonisolated var publisher: AnyPublisher<ResourceStatus, Never> {
        let base = subject.compactMap { $0 }
        guard throttleInterval > .zero else {
            return base.eraseToAnyPublisher()
        }
        // It helps slow down download progress a little, otherwise the UI may keep rendering progress after the download completes.
        return base
            .throttle(for: throttleInterval, scheduler: scheduler, latest: true)
            .eraseToAnyPublisher()
    }

    public func startLoadingResources() {
        let initialReading = preferences.reading
        readingsTask = Task { [weak self] in
            guard let readings = self?.preferences.$reading.prepend(initialReading).values() else {
                return
            }
            await self?.preferencesObservingStarted?()
            for await reading in readings {
                guard !Task.isCancelled else { return }
                await self?.loadResourceInAsyncTask(reading)
            }
        }
        .asCancellableTask()
    }

    /// Stops observing preferences and cancels this service's current loading task.
    /// Integration tests stop the hosted app's loader before using their own loader with cleanup disabled,
    /// preventing the app's loader from deleting resources as tests switch readings.
    public func stopLoadingResources() {
        readingsTask = nil
        readingTask = nil
    }

    public func retry() async {
        loadResourceInAsyncTask(preferences.reading)
    }

    /// The readings this app can load: the ones it downloads and the ones it bundles.
    public func availableReadings() -> Set<Reading> {
        Set(Reading.allReadings.filter(isAvailable))
    }

    // MARK: Internal

    let preferenceLoadingCompleted: EventObserver?
    let preferencesObservingStarted: EventObserver?

    // MARK: Private

    private nonisolated let preferences = ReadingPreferences.shared

    private var readingTask: CancellableTask?
    private var readingsTask: CancellableTask?

    private nonisolated let subject = CurrentValueSubject<ResourceStatus?, Never>(nil)
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let throttleInterval: DispatchQueue.SchedulerTimeType.Stride
    private let zipper: Zipper
    private let fileManager: FileSystem
    private let downloader: ReadingResourceDownloader
    private let remoteResources: ReadingRemoteResources?
    private let removeOtherReadings: Bool
    private let bundledReadings: Set<Reading>

    private func isAvailable(_ reading: Reading) -> Bool {
        remoteResources?.resource(for: reading) != nil || bundledReadings.contains(reading)
    }

    private func loadResourceInAsyncTask(_ reading: Reading) {
        readingTask = Task {
            guard !Task.isCancelled else { return }
            let status = await self.loadResource(of: reading)
            self.send(status, from: reading)
            await self.preferenceLoadingCompleted?()
        }
        .asCancellableTask()
    }

    private func loadResource(of reading: Reading) async -> ResourceStatus {
        if removeOtherReadings {
            removePreviouslyDownloadedResources(exclude: reading)
        }
        await downloader.cancelDownload(exclude: reading)

        logger.info("Resources: Start loading reading resources of: \(reading)")
        guard let remoteResource = remoteResources?.resource(for: reading) else {
            if !bundledReadings.contains(reading), let bundledReading = Reading.allReadings.first(where: bundledReadings.contains) {
                // A reading this app can't load, like one picked in a build without remote resources.
                // Switching back loads the bundled reading instead of rendering pages without resources.
                logger.error("Resources: Reading \(reading) is neither downloadable nor bundled. Switching to \(bundledReading)")
                // Change the preference on the main actor, like the UI does: its observers update
                // view models, and doing that from this actor's thread deadlocks with the main thread.
                await MainActor.run { preferences.reading = bundledReading }
                return .ready
            }
            logger.info("Resources: Reading \(reading) is bundled with the app.")
            return .ready
        }

        if remoteResource.hasSuccessFile(fileSystem: fileManager) {
            logger.info("Resources: Reading \(reading) has been downloaded and saved locally before")
            return .ready
        }

        if recoverDownloadedResourceIfNeeded(remoteResource) {
            logger.info("Resources: Reading \(reading) has extracted resources and a previous success marker. Regenerated success marker.")
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
            // The downloader and the unzip step record their own failures.
            if error.isCancelled {
                logger.info("Resources: Loading reading \(reading) was cancelled")
            } else {
                logger.error("Resources: Failed to load reading \(reading). Error: \(error)")
            }
            return .error(error as NSError)
        }
    }

    private func recoverDownloadedResourceIfNeeded(_ remoteResource: RemoteResource) -> Bool {
        guard remoteResource.canRecoverSuccessFile(fileSystem: fileManager) else {
            return false
        }

        do {
            try fileManager.writeToFile(at: remoteResource.successFilePath.url, content: "Downloaded")
        } catch {
            crasher.recordError(
                error,
                reason: "Cannot write recovered success marker for '\(remoteResource.successFilePath.url)'"
            )
        }
        return true
    }

    private func unzipFileIfNeeded(_ remoteResource: RemoteResource) throws {
        let zipFile = remoteResource.zipFile.url
        let destination = remoteResource.downloadDestination
            .appendingPathComponent(zipFile.lastPathComponent.stringByDeletingPathExtension, isDirectory: false).url

        // Delete the zip either we were able to download it or not.
        defer { try? fileManager.removeItem(at: zipFile) }

        do {
            try zipper.unzipFile(zipFile, destination: destination, overwrite: true)

            // Write a success file to make it easy to verify if file is downloaded and unzipped successfully.
            try fileManager.writeToFile(at: remoteResource.successFilePath.url, content: "Downloaded")
        } catch {
            crasher.recordError(error, reason: "Cannot unzip file '\(zipFile)' to '\(destination)'")
            try? fileManager.removeItem(at: destination)
            throw error
        }
    }

    private func removePreviouslyDownloadedResources(exclude reading: Reading) {
        let readings = Reading.allReadings.filter { $0 != reading }
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
