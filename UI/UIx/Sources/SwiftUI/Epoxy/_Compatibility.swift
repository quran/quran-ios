//
//  Compatibility.swift
//
//
//  Created by Mohamed Afifi on 2024-01-18.
//

import VLogging
import Logging

struct EpoxyLogger {
    static let shared = EpoxyLogger()

    func warn(_ message: @autoclosure () -> Logger.Message) {
        logger.warning(message())
    }

    @inlinable public func assertionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
        Swift.assertionFailure(message(), file: file, line: line)
    }
}

public protocol EpoxyModeled {
    subscript<Property>(property: EpoxyModelProperty<Property>) -> Property { get set }
    func copy<Value>(updating property: EpoxyModelProperty<Value>, to value: Value) -> Self
}

public struct EpoxyModelProperty<Value> {
    enum UpdateStrategy {
        case replace
    }

    init<Model>(
        keyPath: KeyPath<Model, Value>,
        defaultValue: @escaping @autoclosure () -> Value,
        updateStrategy: UpdateStrategy)
    {
    }
}

protocol EpoxyableView {}

public protocol CallbackContextEpoxyModeled {
    associatedtype CallbackContext: ViewProviding
}

public protocol WillDisplayProviding: CallbackContextEpoxyModeled {
    func willDisplay(_ value: (CallbackContext) -> Void) -> Self
}

public protocol DidEndDisplayingProviding: CallbackContextEpoxyModeled {
    func didEndDisplaying(_ value: (CallbackContext) -> Void) -> Self
}

public protocol ViewProviding {
    associatedtype View
    var view: View { get }
}

public protocol AnimatedProviding {
    var animated: Bool { get }
}
