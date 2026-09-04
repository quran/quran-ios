#if QURAN_SYNC
import Localization
import NoorUI
import QuranAnnotations
import QuranLocalization

enum ReadingBookmarkUndoToast {
    static func saved(_ bookmark: PlacedReadingBookmark) -> Toast {
        Toast(MultipartText.localizedFormat("ayah.menu.reading-bookmark.saved", locationTitle(bookmark.placement)))
    }

    static func moved(
        from previousBookmark: PlacedReadingBookmark,
        to currentBookmark: PlacedReadingBookmark,
        undo: @escaping () -> Void
    ) -> Toast {
        makeToast(
            MultipartText.localizedFormat(
                "ayah.menu.reading-bookmark.moved",
                locationTitle(previousBookmark.placement),
                locationTitle(currentBookmark.placement)
            ),
            undo: undo
        )
    }

    static func removed(
        _ bookmark: PlacedReadingBookmark,
        undo: @escaping () -> Void
    ) -> Toast {
        makeToast(
            MultipartText.localizedFormat("ayah.menu.reading-bookmark.removed", locationTitle(bookmark.placement)),
            undo: undo
        )
    }

    private static func makeToast(_ message: MultipartText, undo: @escaping () -> Void) -> Toast {
        Toast(
            message,
            action: ToastAction(title: lAndroid("undo"), handler: undo)
        )
    }

    private static func locationTitle(_ placement: PlacedReadingBookmark.Placement) -> MultipartText {
        switch placement {
        case .ayah(let ayah):
            return "\(ayah: ayah)"
        case .page(let page):
            return .text(page.localizedName)
        }
    }
}
#endif
