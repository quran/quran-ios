//
//  EventStream.swift
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

/// EventStream is a wrapper for `PublishSubject`.
///
/// Unlike `PublishSubject` it can't terminate with error, and when event stream is deallocated
/// it will complete its observable sequence (`asObservable`).
public final class EventStream<Event> {

    private let _subject = PublishSubject<Event>()

    public init() {
    }

    public func trigger(_ event: Event) {
        _subject.on(.next(event))
    }

    /// - returns: Canonical interface for push style sequence
    public func asObservable() -> Observable<Event> {
        return _subject
    }

    deinit {
        _subject.on(.completed)
    }
}
