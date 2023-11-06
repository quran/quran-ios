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
        resourceRequestFactory: @escaping (Set<String>) -> BundleResourceRequest = NSBundleResourceRequest.init
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.resourceRequestFactory = resourceRequestFactory
    }

    // MARK: Public

    public nonisolated var publisher: AnyPublisher<ResourceStatus, Never> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public func startLoadingResources() async {
        await loadResource(of: preferences.reading)

        readingsTask = Task {
            for await reading in preferences.$reading.values() {
                readingTask = Task {
                    await loadResource(of: reading)
                }
                .asCancellableTask()
            }
        }
        .asCancellableTask()
    }

    public func retry() async {
        await loadResource(of: preferences.reading)
    }

    // MARK: Private

    private let preferences = ReadingPreferences.shared

    private var readingTask: CancellableTask?
    private var readingsTask: CancellableTask?

    private nonisolated let subject = CurrentValueSubject<ResourceStatus?, Never>(nil)
    private let bundle: SystemBundle
    private let fileManager: FileSystem
    private let resourceRequestFactory: (Set<String>) -> BundleResourceRequest

    private func loadResource(of reading: Reading) async {
        if fileManager.fileExists(at: reading.directory) {
            send(.ready, from: reading)
            return
        }

        let tag = reading.resourcesTag
        let resource = OnDemandResource(request: resourceRequestFactory([tag]))
        do {
            try await resource.fetch(onProgressChange: { progress in
                self.send(.downloading(progress: progress), from: reading)
            })

            copyFiles(reading: reading)
            send(.ready, from: reading)
        } catch {
            send(.error(error as NSError), from: reading)
        }
    }

    private func copyFiles(reading: Reading) {
        if preferences.reading != reading {
            return
        }
        if reading.directory.isReachable {
            return
        }

        try? fileManager.createDirectory(at: Reading.resourcesDirectory, withIntermediateDirectories: true)

        removePreviouslyDownloadedResources()

        copyNewlyDownloadedResource(reading: reading)
    }

    private func removePreviouslyDownloadedResources() {
        do {
            let downloadedResources = try fileManager.contentsOfDirectory(at: Reading.resourcesDirectory, includingPropertiesForKeys: nil)
            for resource in downloadedResources {
                try? fileManager.removeItem(at: resource)
            }
        } catch {
            logger.error("Resources failed to list files. Error: \(error)")
        }
    }

    private func copyNewlyDownloadedResource(reading: Reading) {
        do {
            let bundleURL = reading.url(inBundle: bundle)
            try fileManager.copyItem(at: bundleURL, to: reading.directory)
        } catch {
            logger.error("Resources \(reading.resourcesTag) failed to copy. Error: \(error)")
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
}
