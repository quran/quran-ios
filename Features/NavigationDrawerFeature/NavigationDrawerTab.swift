//
//  NavigationDrawerTab.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import Foundation
import Localization

enum NavigationDrawerTab: Int, CaseIterable, Identifiable {
    case surah
    case juz
    case notes
    case bookmarks

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .surah: return l("navigation_drawer.tab.surah")
        case .juz: return l("navigation_drawer.tab.juz")
        case .notes: return l("navigation_drawer.tab.notes")
        case .bookmarks: return l("navigation_drawer.tab.bookmarks")
        }
    }
}
