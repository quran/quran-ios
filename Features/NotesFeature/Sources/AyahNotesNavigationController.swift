#if QURAN_SYNC
//
//  AyahNotesNavigationController.swift
//

import NoorUI
import UIKit

/// Presents the ayah notes sheet with its title, Close, and Edit in a horizontal bar, so the sheet doesn't
/// reserve a side column for iPhone Duo's vertical bar, which left its content off-center. Edit is text, which
/// the vertical bar doesn't show, and the medium detent has no status bar to share a column with.
///
/// The presented controller decides for the whole presentation, so it answers itself rather than forwarding
/// to its top view controller. Without a vertical bar, like on iPhone and iPad, this changes nothing.
final class AyahNotesNavigationController: BaseNavigationController {
    @available(iOS 27.1, *)
    override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        .disabled
    }

    @available(iOS 27.1, *)
    override var childForPreferredVerticalBarBehavior: UIViewController? {
        nil
    }
}
#endif
