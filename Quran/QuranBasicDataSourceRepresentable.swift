//
//  QuranDataSourceHandler.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
