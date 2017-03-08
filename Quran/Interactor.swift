//
//  Interactor.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit

protocol Interactor {
    associatedtype Input
    associatedtype Output

    func execute(_ input: Input) -> Promise<Output>
}

struct AnyInteractor<Input, Output>: Interactor {

    let executeClosure: (Input) -> Promise<Output>

    init<InteractorType: Interactor>(_ interactor: InteractorType)
        where InteractorType.Input == Input, InteractorType.Output == Output {
            executeClosure = interactor.execute
    }

    func execute(_ input: Input) -> Promise<Output> {
        return executeClosure(input)
    }
}

extension Interactor {
    func erasedType() -> AnyInteractor<Input, Output> {
        return AnyInteractor(self)
    }
}
