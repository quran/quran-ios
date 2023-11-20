//
//  ReadingResourcesService.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import Combine
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
        bundle: SystemBundle = DefaultSystemBundle(),
        fileManager: FileSystem = DefaultFileSystem(),
        preferencesObservingStarted: EventObserver? = nil,
        preferenceLoadingCompleted: EventObserver? = nil,
        resourceRequestFactory: @escaping (Set<String>) -> BundleResourceRequest = NSBundleResourceRequest.init
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.resourceRequestFactory = resourceRequestFactory
        self.preferencesObservingStarted = preferencesObservingStarted
        self.preferenceLoadingCompleted = preferenceLoadingCompleted
    }

    // MARK: Public

    public nonisolated var publisher: AnyPublisher<ResourceStatus, Never> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public func startLoadingResources() async {
        await loadResource(of: preferences.reading)

        readingsTask = Task { [weak self] in
            guard let readings = self?.preferences.$reading.values() else {
                return
            }
            await self?.preferencesObservingStarted?()
            for await reading in readings {
                await self?.loadResourceFromReadingUpdate(reading)
            }
        }
        .asCancellableTask()
    }

    public func retry() async {
        await loadResource(of: preferences.reading)
    }

    // MARK: Internal

    let preferenceLoadingCompleted: EventObserver?
    let preferencesObservingStarted: EventObserver?

    // MARK: Private

    private let preferences = ReadingPreferences.shared

    private var readingTask: CancellableTask?
    private var readingsTask: CancellableTask?

    private nonisolated let subject = CurrentValueSubject<ResourceStatus?, Never>(nil)
    private let bundle: SystemBundle
    private let fileManager: FileSystem
    private let resourceRequestFactory: (Set<String>) -> BundleResourceRequest

    private func loadResourceFromReadingUpdate(_ reading: Reading) {
        readingTask = Task {
            await self.loadResource(of: reading)
            await self.preferenceLoadingCompleted?()
        }
        .asCancellableTask()
    }

    private func loadResource(of reading: Reading) async {
        logger.info("Resources: Start loading reading resources of: \(reading)")
        if fileManager.fileExists(at: reading.successFilePath) {
            logger.info("Resources: Reading \(reading) has been downloaded and saved locally before")
            send(.ready, from: reading)
            return
        }

        let tag = reading.resourcesTag
        let resource = OnDemandResource(request: resourceRequestFactory([tag]))
        defer { resource.endAccessingResources() }
        do {
            try await resource.fetch(onProgressChange: { progress in
                self.send(.downloading(progress: progress), from: reading)
            })

            try copyFiles(reading: reading)
            send(.ready, from: reading)
        } catch {
            send(.error(error as NSError), from: reading)
        }
    }

    private func copyFiles(reading: Reading) throws {
        // Create `resources` directory if needed.
        try? fileManager.createDirectory(at: Reading.resourcesDirectory, withIntermediateDirectories: true)
        // Remove previously downloaded resources.
        removePreviouslyDownloadedResources()
        // Copy new reading to `resources` directory.
        try copyNewlyDownloadedResource(reading: reading)
    }

    private func removePreviouslyDownloadedResources() {
        do {
            let downloadedResources = try fileManager.contentsOfDirectory(at: Reading.resourcesDirectory, includingPropertiesForKeys: nil)
            for resource in downloadedResources {
                try? fileManager.removeItem(at: resource)
            }
        } catch {
            logger.error("Resources: Failed to list files in resources directory. Error: \(error)")
        }
    }

    private func copyNewlyDownloadedResource(reading: Reading) throws {
        do {
            let bundleURL = reading.url(inBundle: bundle)
            try fileManager.copyItem(at: bundleURL, to: reading.directory)
            try fileManager.writeToFile(at: reading.successFilePath, content: "Downloaded")
        } catch {
            logger.error("Resources: \(reading) failed to copy. Error: \(error)")
            throw error
        }
    }

    private nonisolated func send(_ status: ResourceStatus, from reading: Reading) {
        if preferences.reading != reading {
            return
        }
        subject.send(status)
    }
}

extension Reading {
    var resourcesTag: String {
        switch self {
        case .hafs_1405: return "hafs_1405"
        case .hafs_1440: return "hafs_1440"
        case .hafs_1421: return "hafs_1421"
        case .tajweed: return "tajweed"
        }
    }

    func url(inBundle bundle: SystemBundle) -> URL {
        bundle.url(forResource: resourcesTag, withExtension: nil)!
    }

    static var resourcesDirectory: URL {
        FileManager.applicationSupport.appendingPathComponent("ReadingResources", isDirectory: true)
    }

    public var directory: URL {
        Self.resourcesDirectory.appendingPathComponent(resourcesTag, isDirectory: true)
    }

    var successFilePath: URL {
        directory.appendingPathComponent("success-v2.txt")
    }
}
