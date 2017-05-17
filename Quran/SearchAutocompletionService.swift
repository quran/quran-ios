//
//  SearchAutocompletionService.swift
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

protocol SearchAutocompletionService {
    func autocompletes(for term: String) -> Observable<[SearchAutocompletion]>
}

class SQLiteSearchAutocompletionService: SearchAutocompletionService {

    func autocompletes(for term: String) -> Observable<[SearchAutocompletion]> {
        return Observable.create { observer in
            DispatchQueue.default.asyncAfter(deadline: .now() + 0.3) {
                observer.on(.next(
                    [SearchAutocompletion(text: term + "test", highlightedRange: (term.startIndex..<term.endIndex)),
                     SearchAutocompletion(text: term + "popular", highlightedRange: (term.startIndex..<term.endIndex)),
                     SearchAutocompletion(text: term + "something to the other", highlightedRange: (term.startIndex..<term.endIndex))]
                    ))
                observer.on(.completed)
            }
            return Disposables.create()
        }
    }
}
