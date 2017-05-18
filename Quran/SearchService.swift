//
//  SearchService.swift
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

protocol SearchService {
    func search(for term: String) -> Observable<[SearchResult]>
}

class SQLiteSearchService: SearchService {

    private var counter = Protected(0)

    func search(for term: String) -> Observable<[SearchResult]> {
        return Observable.create { observer in
            DispatchQueue.default.asyncAfter(deadline: .now() + 1) {
                self.counter.value += 1

                if self.counter.value % 3 == 1 {
                    let long = "some search 1, to the end of it, but very long and that is long enough. I don't know let's check it. But we are not sure, let's use 3rd line"
                    observer.on(.next(
                        [
                            SearchResult(text: long, ayah: AyahNumber(sura: 2, ayah: 78), page: 12, highlightedRanges: [long.range(of: "search 1")!, long.range(of: "is long enough")!]),
                            SearchResult(text: "some search 2", ayah: AyahNumber(sura: 1, ayah: 1), page: 1, highlightedRanges: []),
                            SearchResult(text: "some search 3", ayah: AyahNumber(sura: 2, ayah: 6), page: 3, highlightedRanges: [])
                        ]
                        ))
                } else if self.counter.value % 3 == 2 {
                    observer.on(.next([]))
                } else {
                    observer.on(.error(ParsingError.parsing("")))
                }
                observer.on(.completed)
            }
            return Disposables.create()
        }
    }
}
