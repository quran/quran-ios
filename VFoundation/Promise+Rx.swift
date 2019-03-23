//
//  Promise+Rx.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/17.
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
import RxSwift

extension Promise {
    public func asObservable() -> Observable<T> {
        return Observable.create { observer -> Disposable in
            self.done { value -> Void in
                    observer.on(.next(value))
                    observer.on(.completed)
            }.catch { error in
                    observer.on(.error(error))
            }
            return Disposables.create()
        }
    }
}
