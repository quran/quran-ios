//
//  CoreDataPublisher.swift
//
//
//  Created by Mohamed Afifi on 2023-02-26.
//

import Combine
import CoreData
import Crashing

// Inspired by: https://gist.github.com/darrarski/28d2f5a28ef2c5669d199069c30d3d52

public final class CoreDataPublisher<Result>: Publisher where Result: NSFetchRequestResult {
    public init(request: NSFetchRequest<Result>, context: NSManagedObjectContext) {
        self.request = request
        self.context = context
    }

    public convenience init(request: NSFetchRequest<Result>, stack: CoreDataStack) {
        self.init(request: request, context: stack.viewContext)
    }

    let request: NSFetchRequest<Result>
    let context: NSManagedObjectContext

    // MARK: - Publisher

    public typealias Output = [Result]
    public typealias Failure = Never

    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        subscriber.receive(subscription: FetchedResultsSubscription(
            subscriber: subscriber,
            request: request,
            context: context
        ))
    }
}

final class FetchedResultsSubscription<SubscriberType, ResultType>: NSObject, Subscription, NSFetchedResultsControllerDelegate
    where
    SubscriberType: Subscriber,
    SubscriberType.Input == [ResultType],
    SubscriberType.Failure == Never,
    ResultType: NSFetchRequestResult
{
    init(subscriber: SubscriberType,
         request: NSFetchRequest<ResultType>,
         context: NSManagedObjectContext)
    {
        self.subscriber = subscriber
        self.request = request
        self.context = context
    }

    private(set) var subscriber: SubscriberType?
    private(set) var request: NSFetchRequest<ResultType>?
    private(set) var context: NSManagedObjectContext?
    private(set) var controller: NSFetchedResultsController<ResultType>?

    // MARK: - Subscription

    func request(_ demand: Subscribers.Demand) {
        guard demand > 0,
              let subscriber,
              let request,
              let context else { return }

        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller?.delegate = self

        do {
            try controller?.performFetch()
            if let fetchedObjects = controller?.fetchedObjects {
                _ = subscriber.receive(fetchedObjects)
            }
        } catch {
            crasher.recordError(error, reason: "Error retrieving core data entities. Request: \(request)")
        }
    }

    // MARK: - Cancellable

    func cancel() {
        subscriber = nil
        controller = nil
        request = nil
        context = nil
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        guard let subscriber,
              controller == self.controller else { return }

        if let fetchedObjects = self.controller?.fetchedObjects {
            _ = subscriber.receive(fetchedObjects)
        }
    }
}
