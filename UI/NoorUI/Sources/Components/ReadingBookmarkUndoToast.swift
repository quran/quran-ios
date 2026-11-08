#if QURAN_SYNC
import Localization
import QuranAnnotations

/// The toasts shown after saving, moving, or removing a reading bookmark.
public enum ReadingBookmarkUndoToast {
    public static func saved(_ bookmark: PlacedReadingBookmark) -> Toast {
        Toast(
            MultipartText.localizedFormat("ayah.menu.reading-bookmark.saved", locationTitle(bookmark.placement)),
            icon: icon(bookmark, style: .filled)
        )
    }

    public static func moved(
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
            icon: icon(currentBookmark, style: .filled),
            undo: undo
        )
    }

    public static func removed(
        _ bookmark: PlacedReadingBookmark,
        undo: @escaping () -> Void
    ) -> Toast {
        makeToast(
            MultipartText.localizedFormat("ayah.menu.reading-bookmark.removed", locationTitle(bookmark.placement)),
            icon: icon(bookmark, style: .outline),
            undo: undo
        )
    }

    private static func makeToast(_ message: MultipartText, icon: Toast.Icon, undo: @escaping () -> Void) -> Toast {
        Toast(
            message,
            icon: icon,
            action: ToastAction(title: lAndroid("undo"), handler: undo)
        )
    }

    private static func icon(_ bookmark: PlacedReadingBookmark, style: ReadingBookmarkIcon.Style) -> Toast.Icon {
        Toast.Icon(style.systemImage, color: bookmark.slot.swiftUIColor)
    }

    private static func locationTitle(_ placement: PlacedReadingBookmark.Placement) -> MultipartText {
        switch placement {
        case .ayah(let ayah):
            return "\(ayah: ayah)"
        case .page(let page):
            return "\(page: page)"
        }
    }
}
#endif
