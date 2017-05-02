//
//  PreloadingOperationRepresentable.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
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

import Foundation
import PromiseKit

public protocol PreloadingOperationRepresentable {
    associatedtype Output

    var operation: Operation { get }
    var promise: Promise<Output> { get }
}

private class _AnyPreloadingOperationRepresentableBoxBase<Output>: PreloadingOperationRepresentable {

    var operation: Operation { expectedToBeSubclassed() }
    var promise: Promise<Output> { expectedToBeSubclassed() }
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

public final class AnyPreloadingOperationRepresentable<Output>: PreloadingOperationRepresentable {

    private let box: _AnyPreloadingOperationRepresentableBoxBase<Output>

    public init<O: PreloadingOperationRepresentable>(_ ds: O) where O.Output == Output {
        box = _AnyPreloadingOperationRepresentableBox(ds: ds)
    }

    public var operation: Operation { return box.operation }
    public var promise: Promise<Output> { return box.promise }
}

extension PreloadingOperationRepresentable {
    public func asPreloadingOperationRepresentable() -> AnyPreloadingOperationRepresentable<Output> {
        return AnyPreloadingOperationRepresentable(self)
    }
}
