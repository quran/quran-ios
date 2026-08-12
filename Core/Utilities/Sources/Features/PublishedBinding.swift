//
//  PublishedBinding.swift
//
//
//  Created by QuranEngine on 2026-08-12.
//

import Combine

/// An observable projection of a publisher-backed source of truth.
///
/// Writes are forwarded to the source. The projected value changes only after
/// `updates` emits the source's accepted value.
@MainActor
@propertyWrapper
public final class PublishedBinding<Value: Equatable> {
    // MARK: Lifecycle

    public init<Updates: Publisher>(
        wrappedValue: Value,
        updates: Updates,
        set: @escaping (Value) -> Void
    ) where Updates.Output == Value, Updates.Failure == Never {
        value = wrappedValue
        subject = CurrentValueSubject(wrappedValue)
        setValue = set
        cancellable = updates.sink { [weak self] value in
            self?.receive(value)
        }
    }

    // MARK: Public

    public var wrappedValue: Value {
        get { value }
        set { updateSource(to: newValue) }
    }

    public var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }

    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance enclosingInstance: EnclosingSelf,
        wrapped _: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedBinding<Value>>
    ) -> Value where EnclosingSelf.ObjectWillChangePublisher == ObservableObjectPublisher {
        get {
            let binding = enclosingInstance[keyPath: storageKeyPath]
            binding.connect(to: enclosingInstance)
            return binding.value
        }
        set {
            let binding = enclosingInstance[keyPath: storageKeyPath]
            binding.connect(to: enclosingInstance)
            binding.updateSource(to: newValue)
        }
    }

    // MARK: Private

    private var value: Value
    private let subject: CurrentValueSubject<Value, Never>
    private let setValue: (Value) -> Void
    private var cancellable: AnyCancellable?
    private var notifyObjectWillChange: (() -> Void)?

    private func connect<EnclosingSelf: ObservableObject>(to enclosingInstance: EnclosingSelf)
        where EnclosingSelf.ObjectWillChangePublisher == ObservableObjectPublisher
    {
        guard notifyObjectWillChange == nil else { return }
        notifyObjectWillChange = { [weak enclosingInstance] in
            enclosingInstance?.objectWillChange.send()
        }
    }

    private func updateSource(to newValue: Value) {
        guard newValue != value else { return }
        setValue(newValue)
    }

    private func receive(_ newValue: Value) {
        guard newValue != value else { return }
        notifyObjectWillChange?()
        value = newValue
        subject.send(newValue)
    }
}
