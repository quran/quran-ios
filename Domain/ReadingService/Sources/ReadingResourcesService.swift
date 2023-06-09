//
//  ReadingResourcesService.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import Combine
import Foundation
import SystemDependencies
import Utilities

@ResourcesActor
public final class ReadingResourcesService {
    public enum ResourceStatus: Equatable {
        case downloading(progress: Double)
        case ready
        case error(NSError)
    }

    private let preferences = ReadingPreferences.shared
    private var preferencesCancellable: AnyCancellable?

    private var readingTask: CancellableTask?

    private nonisolated let subject = CurrentValueSubject<ResourceStatus?, Never>(nil)
    public nonisolated var publisher: AnyPublisher<ResourceStatus, Never> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private let resourceRequestFactory: (Set<String>) -> BundleResourceRequest

    public nonisolated init(resourceRequestFactory: @escaping (Set<String>) -> BundleResourceRequest = NSBundleResourceRequest.init) {
        self.resourceRequestFactory = resourceRequestFactory
    }

    func startLoadingResources() async {
        await loadResource(of: preferences.reading)

        readingTask = Task {
            for await reading in preferences.$reading.values() {
                await loadResource(of: reading)
            }
        }.asCancellableTask()
    }

    public func retry() async {
        await loadResource(of: preferences.reading)
    }

    private func loadResource(of reading: Reading) async {
        let tag = reading.resourcesTag
        let resource = OnDemandResource(request: resourceRequestFactory([tag]))
        do {
            try await resource.fetch(onProgressChange: { progress in
                self.send(.downloading(progress: progress), from: reading)
            })
            send(.ready, from: reading)
        } catch {
            send(.error(error as NSError), from: reading)
        }
    }

    private func send(_ status: ResourceStatus, from reading: Reading) {
        if preferences.reading != reading {
            return
        }
        subject.send(status)
    }
}