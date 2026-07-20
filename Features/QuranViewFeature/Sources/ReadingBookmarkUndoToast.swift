#if QURAN_SYNC
//
//  ReadingBookmarkUndoToast.swift
//

import Foundation
import Localization
import QuranAnnotations
import QuranTextKit
import UIx

enum ReadingBookmarkUndoToast {
    static func moved(
        from previousBookmark: ReadingPositionBookmark,
        to currentBookmark: ReadingPositionBookmark,
        undo: @escaping () -> Void
    ) -> Toast {
        makeToast(
            lFormat(
                "ayah.menu.reading-bookmark.moved",
                location(of: previousBookmark),
                location(of: currentBookmark)
            ),
            undo: undo
        )
    }

    static func removed(
        _ bookmark: ReadingPositionBookmark,
        undo: @escaping () -> Void
    ) -> Toast {
        makeToast(
            lFormat("ayah.menu.reading-bookmark.removed", location(of: bookmark)),
            undo: undo
        )
    }

    private static func makeToast(_ message: String, undo: @escaping () -> Void) -> Toast {
        Toast(
            message,
            action: ToastAction(title: lAndroid("undo"), handler: undo)
        )
    }

    private static func location(of bookmark: ReadingPositionBookmark) -> String {
        switch bookmark.location {
        case .ayah(let ayah):
            return "\(ayah.sura.localizedName()) \(ayah.sura.localizedSuraNumber):\(NumberFormatter.shared.format(ayah.ayah))"
        case .page(let page):
            return page.localizedName
        }
    }
}
#endif
