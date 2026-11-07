import Localization
import NoorUI
import QuranAnnotations
import UIKit

@MainActor
enum DeleteAllConfirmation {
    /// An action sheet that confirms Delete All, anchored to the Delete All bar button on iPad.
    static func make(
        message: String,
        sourceBarButtonItem: UIBarButtonItem,
        deleteAll: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: l("bookmarks.delete-all"),
            message: message,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: l("bookmarks.delete-all"), style: .destructive) { _ in
            deleteAll()
        })
        alert.addAction(UIAlertAction(title: lAndroid("cancel"), style: .cancel))
        alert.popoverPresentationController?.barButtonItem = sourceBarButtonItem
        return alert
    }

    /// The message that confirms removing every ayah from the collection named `collectionName`.
    static func message(collectionName: String) -> String {
        lFormat("bookmarks.collections.ayahs.delete-all.confirmation", collectionName)
    }

    /// The message that confirms removing every highlight in `highlightColor`.
    static func message(highlightColor: HighlightColor) -> String {
        lFormat("bookmarks.collections.ayahs.delete-all.colored.confirmation", highlightColor.localizedName)
    }
}
