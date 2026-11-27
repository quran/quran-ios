//
//  Toast+VerseReference.swift
//
//
//  Created by Marouane on 2026-11-19.
//

import Localization
import NoorUI
import QuranKit
import QuranLocalization

extension Toast {
    /// Names the verse that a footnote's reference led to, with a way back to the footnote's verse.
    public static func verseReference(_ reference: AyahNumber, back: @escaping () -> Void) -> Toast {
        Toast(
            .text(lFormat("translation.text.verse-reference.toast", reference.localizedName)),
            action: ToastAction(title: l("translation.text.verse-reference.back"), handler: back),
            // Long enough to read the verse before going back.
            duration: 8
        )
    }
}
