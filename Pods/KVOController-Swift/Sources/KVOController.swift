//
//  KVOController.swift
//  KVOController
//
//  Created by mohamede1945 on 6/20/15.
//  Copyright (c) 2015 Varaw. All rights reserved.
//

import Foundation

/// Represents the types of objects that can be observable.
public typealias Observable = NSObject

/// Represents the kvo controller object association key property.
private var KVOControllerObjectAssociationKey : UInt8 = 0

/**
*  An NSObject extension for simplyfing observing/unobserving operations.
*/
public extension NSObject {

    /**
    Start obeserving and retaining retainedObservable for the passed key path, options and observing block.

    - parameter retainedObservable: The retained observable parameter.
    - parameter keyPath:            The key path parameter.
    - parameter options:            The options parameter.
    - parameter block:              The block parameter.

    - returns: The observer controller, you can use it to unobserve.
    */
    @discardableResult
    public func observe<Observable : NSObject, PropertyType>(
        retainedObservable: Observable,
        keyPath: String,
        options: NSKeyValueObservingOptions,
        block: @escaping ClosureObserverWay<Observable, PropertyType>.ObservingBlock) -> Controller<ClosureObserverWay<Observable, PropertyType>> {

            let closure = ClosureObserverWay(block: block)
            let controller = Controller(retainedObservable: retainedObservable, keyPath: keyPath, options: options, observerWay: closure)
            addObserver(controller)
            return controller
    }

    /**
    Start obeserving but don't retain nonretainedObservable object for the passed key path, options and observing block.

    - parameter retainedObservable: The retained observable parameter.
    - parameter keyPath:            The key path parameter.
    - parameter options:            The options parameter.
    - parameter block:              The block parameter.

    - returns: The observer controller, you can use it to unobserve.
    */
    @discardableResult
    public func observe<ObservableType : Observable, PropertyType>(
        nonretainedObservable: ObservableType,
        keyPath: String,
        options: NSKeyValueObservingOptions,
        block: @escaping ClosureObserverWay<ObservableType, PropertyType>.ObservingBlock) -> Controller<ClosureObserverWay<ObservableType, PropertyType>> {

            let closure = ClosureObserverWay(block: block)
            let controller = Controller(nonretainedObservable: nonretainedObservable, keyPath: keyPath, options: options, observerWay: closure)
            addObserver(controller)
            return controller
    }

    /**
    Unobserve the passed observable for the passed key path.

    - parameter observable: The observable parameter.
    - parameter keyPath:    The key path parameter.
    */
    public func unobserve(_ observable: Observable, keyPath: String) {
        var observers = listOfObservers()

        for (index, observer) in observers.enumerated() {
            if observer.isObserving(observable, keyPath: keyPath) {
                // stop observing
                observer.unobserve()

                // remove observer
                observers.remove(at: index)
                break
            }
        }

        if observers.count == 0 {
            removeObjectAssociation()
        }
    }

    /**
    Unobserve all.
    */
    public func unobserveAll() {
        for observer in listOfObservers() {
            observer.unobserve()
        }
        removeObjectAssociation()
    }

    /**
    Remove object association.
    */
    fileprivate func removeObjectAssociation() {
        objc_setAssociatedObject(self, &KVOControllerObjectAssociationKey, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
    List of observers.

    - returns: The list of observers.
    */
    fileprivate func listOfObservers() -> [KVOObserver] {
        let associatedObject : AnyObject? =  objc_getAssociatedObject(self, &KVOControllerObjectAssociationKey) as AnyObject?
        var observers: [KVOObserver]
        if let associatedObject = associatedObject as? ObjectWrapper,
            let observersArray = associatedObject.any as? [KVOObserver] {
            observers = observersArray
        } else {
            observers = [KVOObserver]()
        }
        return observers
    }

    /**
    Add observer.

    - parameter observer: The observer parameter.
    */
    fileprivate func addObserver(_ observer: KVOObserver) {
        var observers = listOfObservers()
        observers.append(observer)

        let wrapper = ObjectWrapper(any: observers)
        objc_setAssociatedObject(self, &KVOControllerObjectAssociationKey, wrapper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
    Represents the object wrapper class.

    @author mohamede1945

    @version 1.0
    */
    fileprivate class ObjectWrapper {
        /// Represents the any property.
        var any: Any
        /**
        Initialize new instance with any.

        - parameter any: The any parameter.

        - returns: The new created instance.
        */
        init(any: Any) {
            self.any = any
        }
    }
}

/**
Represents the change data class.

@author mohamede1945

@version 1.0
*/
public struct ChangeData<T> : CustomStringConvertible {

    /// Represents the kind property.
    public let kind: NSKeyValueChange  // NSKeyValueChangeKindKey

    /// Represents the new value property.
    public let newValue: T?            // NSKeyValueChangeNewKey

    /// Represents the old value property.
    public let oldValue: T?            // NSKeyValueChangeOldKey

    /// Represents the indexes property.
    public let indexes: IndexSet?    // NSKeyValueChangeIndexesKey

    /// Represents the is prior property.
    public let isPrior: Bool           // NSKeyValueChangeNotificationIsPriorKey

    /// Represents the key path property.
    public let keyPath: String

    /**
    Initialize new instance with change and key path.

    - parameter change:  The change parameter.
    - parameter keyPath: The key path parameter.

    - returns: The new created instance.
    */
    init(change: [AnyHashable: Any], keyPath: String) {

        // the key path
        self.keyPath = keyPath

        // mandatory
        kind = NSKeyValueChange(rawValue: (change[NSKeyValueChangeKey.kindKey]! as AnyObject).uintValue)!

        // optional
        newValue = change[NSKeyValueChangeKey.newKey] as? T
        oldValue = change[NSKeyValueChangeKey.oldKey] as? T
        indexes  = change[NSKeyValueChangeKey.indexesKey] as? IndexSet

        if let prior = change[NSKeyValueChangeKey.notificationIsPriorKey] as? Bool {
            isPrior  = prior
        } else {
            isPrior = false
        }
    }

    /// Represents the description property.
    public var description: String {

        var description = "<Change kind: \(kindDescription(kind))"
        if isPrior {
            description += "prior: true"
        }
        if let newValue = newValue {
            description += " new: \(newValue)"
        }
        if let oldValue = oldValue {
            description += " old: \(oldValue)"
        }

        if let indexes = indexes {
            description += " indexes: \(indexes)"
        }
        description += ">"

        return description
    }
}

/**
Represents the observer way protocol.

@author mohamede1945

@version 1.0
*/
public protocol ObserverWay {

    /// Represents the ObservableType as generic type.
    associatedtype ObservableType : Observable
    /// Represents the PropertyType as generic type.
    associatedtype PropertyType

    /**
    Value changed change.

    - parameter observable: The observable parameter.
    - parameter change:     The change parameter.
    */
    func valueChanged(_ observable: ObservableType, change: ChangeData<PropertyType>)
}

/**
Represents the closure observer way class.

@author mohamede1945

@version 1.0
*/
public struct ClosureObserverWay<ObservableType : Observable, PropertyType> : ObserverWay {

    /**
    Represesnts the block signature to call when KVO fires.

    - parameter observable: The observable parameter.
    - parameter change:     The change parameter.
    */
    public typealias ObservingBlock = (_ observable: ObservableType, _ change: ChangeData<PropertyType>) -> ()

    /// Represents the block property.
    public let block: ObservingBlock

    /**
    Initialize new instance with block.

    - parameter block: The block parameter.

    - returns: The new created instance.
    */
    public init(block: @escaping ObservingBlock) {
        self.block = block
    }

    /**
    Value changed change.

    - parameter observable: The observable parameter.
    - parameter change:     The change parameter.
    */
    public func valueChanged(_ observable: ObservableType, change: ChangeData<PropertyType>) {
        block(observable, change)
    }
}

/**
Represents the observable storage enumeration.

- Retained:    The retained parameter.
- Nonretained: The nonretained parameter.

@author mohamede1945

@version 1.0
*/
private enum ObservableStorage {
    case retained
    case nonretained
}

/**
Represents the KVO controller class.

@author mohamede1945

@version 1.0
*/
open class Controller<ObserverCallback : ObserverWay> : _KVOObserver, KVOObserver, CustomStringConvertible {

    /// Represents the key path property.
    open let keyPath: String
    /// Represents the options property.
    open let options: NSKeyValueObservingOptions

    /// Represents the observer way property.
    open let observerWay: ObserverCallback

    /// Represents the store property.
    fileprivate let store: ObservableStore<ObserverCallback.ObservableType>

    /// Represents the observable property.
    open var observable: ObserverCallback.ObservableType? {
        return store.observable
    }

    /// Represents the proxy property.
    fileprivate var proxy: ControllerProxy!

    /// Represents the observing property.
    open fileprivate(set) var observing = true

    /**
    Initialize new instance with observable, observable storage, key path, options, context and observer way.

    - parameter observable:        The observable parameter.
    - parameter observableStorage: The observable storage parameter.
    - parameter keyPath:           The key path parameter.
    - parameter options:           The options parameter.
    - parameter context:           The context parameter.
    - parameter observerWay:       The observer way parameter.

    - returns: The new created instance.
    */
    fileprivate init(
        observable  : ObserverCallback.ObservableType,
        observableStorage: ObservableStorage,
        keyPath : String,
        options : NSKeyValueObservingOptions,
        context : UnsafeMutableRawPointer? = nil,
        observerWay : ObserverCallback) {

            assert(!keyPath.isEmpty, "Keypath shouldn't be empty string")

            self.keyPath = keyPath
            self.options = options
            self.observerWay = observerWay
            self.store = ObservableStore(observable: observable, storage: observableStorage)

            self.proxy = ControllerProxy(self)
            SharedObserverController.shared.observe(observable, observer: self.proxy)
    }

    /**
    Initialize new instance with retained observable, key path, options, context and observer way.

    - parameter retainedObservable: The retained observable parameter.
    - parameter keyPath:            The key path parameter.
    - parameter options:            The options parameter.
    - parameter context:            The context parameter.
    - parameter observerWay:        The observer way parameter.

    - returns: The new created instance.
    */
    public convenience init(retainedObservable: ObserverCallback.ObservableType,
        keyPath : String,
        options : NSKeyValueObservingOptions,
        context : UnsafeMutableRawPointer? = nil,
        observerWay : ObserverCallback) {

            self.init(observable: retainedObservable, observableStorage: .retained, keyPath : keyPath,
                options : options, context : context, observerWay: observerWay)
    }

    /**
    Initialize new instance with nonretained observable, key path, options, context and observer way.

    - parameter nonretainedObservable: The nonretained observable parameter.
    - parameter keyPath:               The key path parameter.
    - parameter options:               The options parameter.
    - parameter context:               The context parameter.
    - parameter observerWay:           The observer way parameter.

    - returns: The new created instance.
    */
    public convenience init(nonretainedObservable: ObserverCallback.ObservableType,
        keyPath : String,
        options : NSKeyValueObservingOptions,
        context : UnsafeMutableRawPointer? = nil,
        observerWay : ObserverCallback) {

            self.init(observable: nonretainedObservable, observableStorage: .nonretained, keyPath : keyPath,
                options : options, context : context, observerWay: observerWay)
    }

    /**
    Deallocate the instance.
    */
    deinit {
        unobserve()
    }

    /**
    Unobserve.
    */
    open func unobserve() {
        if let observable = observable , observing {
            SharedObserverController.shared.unobserve(observable, keyPath: keyPath, observer: self.proxy)
            observing = false
        }
    }

    /**
    Value changed change.

    - parameter observable: The observable parameter.
    - parameter change:     The change parameter.
    */
    fileprivate func valueChanged(_ observable: Observable, change: [AnyHashable: Any]) {
        if let observableObject = self.observable , observing {
            let kvoChange = ChangeData<ObserverCallback.PropertyType>(change: change, keyPath: keyPath)
            observerWay.valueChanged(observableObject, change: kvoChange)
        }
    }

    /**
    Whether or not is observing the passed key path.

    - parameter observable: The observable parameter.
    - parameter keyPath:    The key path parameter.

    - returns: True if observing, otherwise false.
    */
    open func isObserving(_ observable: Observable, keyPath: String) -> Bool {

        if self.observable != nil && observing && keyPath == self.keyPath {
            return true
        }
        return false

    }

    /// Represents the description property.
    open var description: String {
        return "<Controller options: \(optionDescription(options)) keyPath: \(keyPath) observable: \(observable) observing: \(observing)>"
    }
}

// MARK:- Proxy and KVO Controllers

/**
Represents the controller proxy class.

@author mohamede1945

@version 1.0
*/
@objc
private class ControllerProxy: NSObject, _KVOObserver {

    /// Represents the observer property.
    unowned var observer: _KVOObserver

    /**
    Initialize new instance with_.

    - parameter observer: The observer parameter.

    - returns: The new created instance.
    */
    init(_ observer: _KVOObserver) {
        self.observer = observer
    }

    /// Represents the key path property.
    var keyPath: String {
        return observer.keyPath
    }

    /// Represents the options property.
    var options: NSKeyValueObservingOptions {
        return observer.options
    }

    /**
    Value changed change.

    - parameter observable: The observable parameter.
    - parameter change:     The change parameter.
    */
    func valueChanged(_ observable: Observable, change: [AnyHashable: Any]) {
        return observer.valueChanged(observable, change: change)
    }

    /// Represents the pointer property.
    lazy var pointer: UnsafeMutableRawPointer = {
        return UnsafeMutableRawPointer(Unmanaged<ControllerProxy>.passUnretained(self).toOpaque())
        }()

    /**
    From pointer.

    - parameter pointer: The pointer parameter.

    - returns: The controller proxy.
    */
    class func fromPointer(_ pointer: UnsafeMutableRawPointer) -> ControllerProxy {
        return Unmanaged<ControllerProxy>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue()
    }

    /// Represents the description property.
    override var description: String {
        let description = String(format: "<%@:%p observer: \(observer)>", arguments: [NSStringFromClass(type(of: self)), self])
        return description
    }
}

/**
Represents the shared observer controller class.

@author mohamede1945

@version 1.0
*/
private class SharedObserverController : NSObject {
    /// Represents the observers property.
    let observers = NSHashTable<ControllerProxy>.weakObjects()
    /// Represents the lock property.
    var lock = DispatchSemaphore(value: 1)

    /// Represents the shared property.
    static let shared = SharedObserverController()

    /**
    Observe var.

    - parameter observable: The observable parameter.
    - parameter observer:   The observer parameter.
    */
    func observe(_ observable: Observable, observer: ControllerProxy) {

        executeSafely {
            observers.add(observer)
        }

        observable.addObserver(self, forKeyPath: observer.keyPath, options: observer.options, context: observer.pointer)
    }

    /**
    Unobserve key path and var.

    - parameter observable: The observable parameter.
    - parameter keyPath:    The key path parameter.
    - parameter observer:   The observer parameter.
    */
    func unobserve(_ observable: Observable, keyPath: String, observer: ControllerProxy) {
        executeSafely {
            observers.remove(observer)
        }

        observable.removeObserver(self, forKeyPath: keyPath)
    }

    /**
    Observe value for key path of object, change and context.

    - parameter keyPath:    The key path parameter.
    - parameter observable: The observable parameter.
    - parameter change:     The change parameter.
    - parameter context:    The context parameter.
    */
    override func observeValue(forKeyPath keyPath: String?, of observable: Any?,
        change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change else {
            return
        }

        guard let context = context else {
            fatalError("Context is missing for keyPath:'\(keyPath)' of observable:'\(observable)', change:'\(change)'")
        }
        assert(observable is NSObject, "Observable object should be of type NSObject")

        let observableObject = observable as! NSObject

        let contextObserver = ControllerProxy.fromPointer(context)
        var info: ControllerProxy?
        executeSafely {
            info = observers.member(contextObserver)
        }

        if let info = info {
            info.valueChanged(observableObject, change: change)
        }
    }

    /**
    Execute safely@noescape.

    - parameter block: The block parameter.
    */
    fileprivate func executeSafely(_ block: () -> ()) {
        lock.wait()
        block()
        lock.signal()
    }

    /// Represents the description property.
    override var description: String {
        var description = String(format: "<%@:%p", arguments: [NSStringFromClass(type(of: self)), self])
        executeSafely {

            var observersDescriptions = [String]()
            for observer in observers.objectEnumerator() {
                if let proxy = observer as? ControllerProxy {
                    observersDescriptions.append(proxy.description)
                }
            }

            description += " contexts:\(observersDescriptions)>"
        }

        return description
    }
}

/**
Represents the kvo observer protocol.

@author mohamede1945

@version 1.0
*/
public protocol KVOObserver {

    /**
    Unobserve.
    */
    func unobserve()
    /**
    Is observing key path.

    - parameter observable: The observable parameter.
    - parameter keyPath:    The key path parameter.

    - returns: True, if observing.
    */
    func isObserving(_ observable: Observable, keyPath: String) -> Bool
}

/**
Represents the private kvo observer protocol.

@author mohamede1945

@version 1.0
*/
private protocol _KVOObserver : class {
    /// Represents the key path property.
    var keyPath: String { get }
    /// Represents the options property.
    var options: NSKeyValueObservingOptions { get }
    /**
    Value changed change.

    - parameter observable: The observable parameter.
    - parameter change:     The change parameter.
    */
    func valueChanged(_ observable: Observable, change: [AnyHashable: Any])
}

/**
Represents the observable store class.

@author mohamede1945

@version 1.0
*/
private struct ObservableStore<T : Observable> {

    /// Represents the storage property.
    fileprivate (set) var storage: ObservableStorage

    /// Represents the retained observable property.
    fileprivate var retainedObservable: T?
    /// Represents the nonretained observable property.
    fileprivate weak var nonretainedObservable: T?

    /**
    Initialize new instance with observable and storage.

    - parameter observable: The observable parameter.
    - parameter storage:    The storage parameter.

    - returns: The new created instance.
    */
    init(observable: T, storage: ObservableStorage) {
        self.storage = storage

        switch storage {
        case .retained:     retainedObservable = observable
        case .nonretained:  nonretainedObservable = observable
        }
    }

    /// Represents the observable property.
    var observable : T? {
        switch storage {
        case .retained: return retainedObservable
        case .nonretained: return nonretainedObservable
        }
    }
}

/**
Option description.

- parameter option: The option parameter.

- returns: The description of the option.
*/
private func optionDescription(_ option: NSKeyValueObservingOptions) -> String {

    let options = [(option: NSKeyValueObservingOptions.new, "New"),
        (option: NSKeyValueObservingOptions.old, "Old"),
        (option: NSKeyValueObservingOptions.initial, "Initial"),
        (option: NSKeyValueObservingOptions.prior, "Prior")]

    var varOption = option

    var descriptions = [String]()
    while varOption.rawValue > 0 {
        for (targetOption, desc) in options {
            if varOption.contains(targetOption) {
                varOption.remove(targetOption)
                descriptions.append(desc)
            }
        }
    }

    return descriptions.joined(separator: "|")
}

/**
Kind description.

- parameter kind: The kind parameter.
*/
private func kindDescription(_ kind: NSKeyValueChange) -> String {
    let kinds = [NSKeyValueChange.insertion: "Insertion",
        NSKeyValueChange.removal: "Removal", NSKeyValueChange.replacement : "Replacement", NSKeyValueChange.setting : "Setting" ]
    return kinds[kind] ?? "Unknown Value: \(kind)"
}
