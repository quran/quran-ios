//
//  Interactor.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import PromiseKit

public protocol Interactor {
    associatedtype Input
    associatedtype Output

    func execute(_ input: Input) -> Promise<Output>
}

public struct AnyInteractor<Input, Output>: Interactor {

    private let executeClosure: (Input) -> Promise<Output>

    public init<InteractorType: Interactor>(_ interactor: InteractorType)
        where InteractorType.Input == Input, InteractorType.Output == Output {
            executeClosure = interactor.execute
    }

    public func execute(_ input: Input) -> Promise<Output> {
        return executeClosure(input)
    }
}

extension Interactor {
    public func asAnyInteractor() -> AnyInteractor<Input, Output> {
        return AnyInteractor(self)
    }
}

public struct AnyGetInteractor<Output>: Interactor {
    private let executeClosure: (Void) -> Promise<Output>

    public init<InteractorType: Interactor>(_ interactor: InteractorType)
        where InteractorType.Input == Void, InteractorType.Output == Output {
            executeClosure = interactor.execute
    }

    public func execute(_ input: Void) -> Promise<Output> {
        return executeClosure(input)
    }

    public func get() -> Promise<Output> {
        return executeClosure(Void())
    }
}

extension Interactor where Input == Void {
    public func asAnyGetInteractor() -> AnyGetInteractor<Output> {
        return AnyGetInteractor(self)
    }
}
