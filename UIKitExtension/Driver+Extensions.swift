//
//  Driver+Extensions.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/17/17.
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
import RxSwift
import RxCocoa
import VFoundation

extension ObservableConvertibleType {

    public func asDriver(onErrorTransform transform: @escaping (Error) -> E) -> Driver<E> {
        return asDriver(onErrorRecover: {
            Driver.just(transform($0))
        })
    }
}

extension EventStream {
    /// Converts `EventStream` to `Driver` unit.
    ///
    /// - returns: Driving observable sequence.
    public func asDriver() -> Driver<Event> {
        return asObservable()
            .asDriver(onErrorRecover: { (error) -> Driver<Event> in
                Swift.fatalError("EventStream shouldn't error!")
        })
    }
}

extension EventStream {
    /// Converts `EventStream` to `SharedSequence` unit.
    ///
    /// - returns: Observable sequence.
    public func asSharedSequence<SharingStrategy: SharingStrategyProtocol>(strategy: SharingStrategy.Type = SharingStrategy.self) -> SharedSequence<SharingStrategy, Event> {
        return asObservable().asSharedSequence(onErrorRecover: { (error) -> SharedSequence<SharingStrategy, Event> in
            Swift.fatalError("EventStream shouldn't error!")
        })
    }
}
