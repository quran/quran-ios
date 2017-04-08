//
//  QuranDataSourceHandler.swift
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
import GenericDataSources

protocol QuranDataSourceHandler {
    associatedtype Item = QuranPage

    func highlightAyaht(_ ayat: Set<AyahNumber>, isActive: Bool)
    func applicationDidBecomeActive()
    func invalidate()
}

class AnyQuranDataSourceHandler<Item>: QuranDataSourceHandler {

    private let highlightAyatBlock: (Set<AyahNumber>, Bool) -> Void
    private let becomeActiveBlock: () -> Void
    private let invalidateBlock: () -> Void

    init<DS: QuranDataSourceHandler>(_ ds: DS) where DS.Item == Item {
        highlightAyatBlock = ds.highlightAyaht
        becomeActiveBlock = ds.applicationDidBecomeActive
        invalidateBlock = ds.invalidate
    }

    func highlightAyaht(_ ayat: Set<AyahNumber>, isActive: Bool) {
        return highlightAyatBlock(ayat, isActive)
    }

    func applicationDidBecomeActive() {
        return becomeActiveBlock()
    }

    func invalidate() {
        return invalidateBlock()
    }
}

extension QuranDataSourceHandler {
    func asAnyQuranDataSourceHandler() -> AnyQuranDataSourceHandler<Item> {
        return AnyQuranDataSourceHandler(self)
    }
}
