#if QURAN_SYNC
//
//  ReadingBookmarkNameAlert.swift
//
//  Created by Mohamed Afifi on 2026-10-29.
//

import Localization
import QuranAnnotations
import SwiftUI

public extension View {
    /// Asks for a new name for the reading bookmark in `slot`.
    ///
    /// The placeholder names the slot's color, which the bookmark goes by when the name is left empty. It's also what
    /// VoiceOver reads for the field, because the alert's text field drops an `accessibilityLabel`.
    /// The name stays outside `slot` because dismissing the alert clears `slot` before `submit` reads the name.
    @MainActor
    func readingBookmarkNameAlert(
        slot: Binding<ReadingBookmarkSlot?>,
        name: Binding<String>,
        submit: @escaping @MainActor (ReadingBookmarkSlot) async -> Void
    ) -> some View {
        alert(
            l("bookmarks.collections.rename"),
            isPresented: Binding(
                get: { slot.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        slot.wrappedValue = nil
                    }
                }
            ),
            presenting: slot.wrappedValue
        ) { slot in
            TextField(lFormat("bookmarks.reading.name.accessibility-label", slot.displayName), text: name)
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(l("bookmarks.collections.rename")) {
                Task { await submit(slot) }
            }
        }
    }
}
#endif
