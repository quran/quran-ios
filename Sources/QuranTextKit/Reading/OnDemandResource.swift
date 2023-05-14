//
//  OnDemandResource.swift
//
//
//  Created by Mohamed Afifi on 2023-02-19.
//

import Combine
import Foundation
import VLogging

// Inspired by: https://github.com/RxSwiftCommunity/RxOnDemandResources/blob/master/RxOnDemandResources/ODRFetcher.swift

public final class OnDemandResource {
    static var requestInitializer: (Set<String>) -> NSBundleResourceRequest = NSBundleResourceRequest.init
    private let request: NSBundleResourceRequest
    private let subject = CurrentValueSubject<Double?, Error>(nil)
    public var publisher: AnyPublisher<Double, Error> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public init(tags: Set<String>) {
        request = Self.requestInitializer(tags)
        request.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
        fetch()
    }

    private func fetch() {
        logger.info("Fetching resources \(request.tags)")
        request.conditionallyBeginAccessingResources { [weak self] available in
            guard let self else {
                return
            }
            logger.info("Resources \(self.request.tags) availability \(available)")
            guard available else {
                self.kvoSubscribe()
                self.request.beginAccessingResources { [weak self] error in
                    guard let self else {
                        return
                    }
                    self.kvoUnsubscribe()
                    guard let error else {
                        logger.info("Resources \(self.request.tags) downloaded")
                        self.subject.send(completion: .finished)
                        return
                    }
                    logger.error("Resources \(self.request.tags) failed. Error: \(error)")
                    self.subject.send(completion: .failure(error))
                }
                return
            }
            self.subject.send(completion: .finished)
        }
    }

    // MARK: - KVO

    private var progressCancellable: AnyCancellable?

    private func kvoSubscribe() {
        progressCancellable = request.progress.publisher(for: \.fractionCompleted)
            .sink { [weak self] progress in
                self?.subject.send(progress)
            }
    }

    private func kvoUnsubscribe() {
        progressCancellable?.cancel()
        progressCancellable = nil
    }
}
