#if QURAN_SYNC
//
//  ReadingBookmarkUndoToast.swift
//

import Localization
import NoorUI
import QuranAnnotations
import QuranLocalization

enum ReadingBookmarkUndoToast {
    static func saved(_ bookmark: ReadingPositionBookmark) -> Toast {
        Toast(MultipartText.localizedFormat("ayah.menu.reading-bookmark.saved", location(of: bookmark)))
    }

    static func moved(
        from previousBookmark: ReadingPositionBookmark,
        to currentBookmark: ReadingPositionBookmark,
        undo: @escaping () -> Void
    ) -> Toast {
        makeToast(
            MultipartText.localizedFormat(
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
            MultipartText.localizedFormat("ayah.menu.reading-bookmark.removed", location(of: bookmark)),
            undo: undo
        )
    }

    private static func makeToast(_ message: MultipartText, undo: @escaping () -> Void) -> Toast {
        Toast(
            message,
            action: ToastAction(title: lAndroid("undo"), handler: undo)
        )
    }

    private static func location(of bookmark: ReadingPositionBookmark) -> MultipartText {
        switch bookmark.location {
        case .ayah(let ayah):
            return "\(ayah: ayah, format: .compact)"
        case .page(let page):
            return .text(page.localizedName)
        }
    }
}
#endif
