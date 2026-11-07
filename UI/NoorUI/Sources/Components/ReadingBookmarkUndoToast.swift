#if QURAN_SYNC
import Foundation
import Localization
import QuranAnnotations

/// The toasts shown after saving, moving, or removing a reading bookmark.
public enum ReadingBookmarkUndoToast {
    public static func saved(_ bookmark: PlacedReadingBookmark, showsExplanation: Bool) -> Toast {
        Toast(
            MultipartText.localizedFormat("ayah.menu.reading-bookmark.saved", locationTitle(bookmark.placement)),
            subtitle: showsExplanation ? .text(l("ayah.menu.reading-bookmark.saved.explanation")) : nil,
            icon: icon(bookmark, style: .filled),
            duration: showsExplanation ? explanationDuration : Toast.defaultDuration
        )
    }

    public static func moved(
        from previousBookmark: PlacedReadingBookmark,
        to currentBookmark: PlacedReadingBookmark,
        showsExplanation: Bool,
        undo: @escaping () -> Void
    ) -> Toast {
        makeToast(
            MultipartText.localizedFormat(
                "ayah.menu.reading-bookmark.moved",
                locationTitle(previousBookmark.placement),
                locationTitle(currentBookmark.placement)
            ),
            subtitle: showsExplanation ? .text(l("ayah.menu.reading-bookmark.moved.explanation")) : nil,
            icon: icon(currentBookmark, style: .filled),
            duration: showsExplanation ? explanationDuration : Toast.defaultDuration,
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

    private static let explanationDuration: TimeInterval = 6

    private static func makeToast(
        _ message: MultipartText,
        subtitle: MultipartText? = nil,
        icon: Toast.Icon,
        duration: TimeInterval = Toast.defaultDuration,
        undo: @escaping () -> Void
    ) -> Toast {
        Toast(
            message,
            subtitle: subtitle,
            icon: icon,
            action: ToastAction(title: lAndroid("undo"), handler: undo),
            duration: duration
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
