#if QURAN_SYNC
//
//  SafariSheetDelegate.swift
//
//
//  Created by Mohamed Afifi on 2026-10-29.
//

import SafariServices

/// Reports when the user closes a Safari sheet. The sheet holds its delegate weakly, so whoever presents it keeps
/// this alive.
@MainActor
final class SafariSheetDelegate: NSObject, @preconcurrency SFSafariViewControllerDelegate {
    // MARK: Lifecycle

    init(onFinish: @escaping @MainActor () -> Void) {
        self.onFinish = onFinish
    }

    // MARK: Internal

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        onFinish()
    }

    // MARK: Private

    private let onFinish: @MainActor () -> Void
}
#endif
