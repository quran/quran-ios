//
//  ReadingResourcesService.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import Combine
import Foundation

public class ReadingResourcesService {
    public enum ResourceStatus: Equatable {
        case downloading(progress: Double)
        case ready
        case error(NSError)
    }

    public static let shared = ReadingResourcesService()

    private let preferences = ReadingPreferences.shared
    private var preferencesCancellable: AnyCancellable?

    private var resource: OnDemandResource?

    private var resourceCancellable: AnyCancellable?
    private let subject = CurrentValueSubject<ResourceStatus?, Error>(nil)
    public var publisher: AnyPublisher<ResourceStatus, Error> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    init() {
        loadResource(of: preferences.reading)

        preferencesCancellable = preferences.$reading.sink { [weak self] reading in
            self?.loadResource(of: reading)
        }
    }

    public func retry() {
        loadResource(of: preferences.reading)
    }

    private func loadResource(of reading: Reading) {
        let tag = reading.resourcesTag
        resource = OnDemandResource(tags: [tag])
        resourceCancellable = resource?.publisher.sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished: self?.send(.ready, from: reading)
            case .failure(let error): self?.send(.error(error as NSError), from: reading)
            }
        }, receiveValue: { [weak self] progress in
            self?.send(.downloading(progress: progress), from: reading)
        })
    }

    private func send(_ status: ResourceStatus, from reading: Reading) {
        if preferences.reading != reading {
            return
        }
        subject.send(status)
    }
}
