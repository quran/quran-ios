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
    associatedtype Output

    var operation: Operation { get }
    var promise: Promise<Output> { get }
}

private class _AnyPreloadingOperationRepresentableBoxBase<Output>: PreloadingOperationRepresentable {

    var operation: Operation { fatalError() }
    var promise: Promise<Output> { fatalError() }
}

private class _AnyPreloadingOperationRepresentableBox<O: PreloadingOperationRepresentable>:
        _AnyPreloadingOperationRepresentableBoxBase<O.Output> {

    private let ds: O
    init(ds: O) {
        self.ds = ds
    }

    override var operation: Operation { return ds.operation }
    override var promise: Promise<O.Output> { return ds.promise }
}

class AnyPreloadingOperationRepresentable<Output>: PreloadingOperationRepresentable {

    private let box: _AnyPreloadingOperationRepresentableBoxBase<Output>

    init<O: PreloadingOperationRepresentable>(_ ds: O) where O.Output == Output {
        box = _AnyPreloadingOperationRepresentableBox(ds: ds)
    }

    var operation: Operation { return box.operation }
    var promise: Promise<Output> { return box.promise }
}

extension PreloadingOperationRepresentable {
    func asPreloadingOperationRepresentable() -> AnyPreloadingOperationRepresentable<Output> {
        return AnyPreloadingOperationRepresentable(self)
    }
}
