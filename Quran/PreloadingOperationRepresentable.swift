//
//  PreloadingOperationRepresentable.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit

protocol PreloadingOperationRepresentable {
    associatedtype Input
    associatedtype Output

    var operation: Operation { get }
    var promise: Promise<Output> { get }

    init(_ input: Input)
}

private class _AnyPreloadingOperationRepresentableBoxBase<Input, Output>: PreloadingOperationRepresentable {

    var operation: Operation { fatalError() }
    var promise: Promise<Output> { fatalError() }

    required init(_ input: Input) {
        fatalError()
    }

    init() {
    }
}

private class _AnyPreloadingOperationRepresentableBox<O: PreloadingOperationRepresentable>:
        _AnyPreloadingOperationRepresentableBoxBase<O.Input, O.Output> {

    private let ds: O
    init(ds: O) {
        self.ds = ds
        super.init()
    }

    required init(_ input: O.Input) {
        fatalError()
    }

    override var operation: Operation { return ds.operation }
    override var promise: Promise<O.Output> { return ds.promise }
}

class AnyPreloadingOperationRepresentable<Input, Output>: PreloadingOperationRepresentable {

    private let box: _AnyPreloadingOperationRepresentableBoxBase<Input, Output>

    required init(_ input: Input) {
        fatalError("AnyPreloadingOperationRepresentable cannot be constructed using `init(_ input: Input)`.")
    }

    init<O: PreloadingOperationRepresentable>(_ ds: O) where O.Input == Input, O.Output == Output {
        box = _AnyPreloadingOperationRepresentableBox(ds: ds)
    }

    var operation: Operation { return box.operation }
    var promise: Promise<Output> { return box.promise }
}

extension PreloadingOperationRepresentable {
    func asPreloadingOperationRepresentable() -> AnyPreloadingOperationRepresentable<Input, Output> {
        return AnyPreloadingOperationRepresentable(self)
    }
}
