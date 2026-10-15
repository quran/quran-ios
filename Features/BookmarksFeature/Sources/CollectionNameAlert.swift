#if QURAN_SYNC
//
//  CollectionNameAlert.swift
//
//  Created by Mohamed Afifi on 2026-10-15.
//

import Localization
import SwiftUI

/// The alert that asks for a collection name, and the reason it rejected the last one.
enum CollectionNameAlert: Equatable {
    case hidden
    case editing
    case rejected(CollectionNameError)

    // MARK: Internal

    var isPresented: Bool {
        self != .hidden
    }

    var error: CollectionNameError? {
        guard case .rejected(let error) = self else {
            return nil
        }
        return error
    }
}

extension View {
    /// Asks for a collection name; the confirm button repeats the title.
    ///
    /// The name stays outside `state` because dismissing the alert hides it before `submit` reads the name.
    @MainActor
    func collectionNameAlert(
        _ title: String,
        state: Binding<CollectionNameAlert>,
        name: Binding<String>,
        submit: @escaping @MainActor () async -> Void
    ) -> some View {
        alert(
            title,
            isPresented: Binding(
                get: { state.wrappedValue.isPresented },
                set: { isPresented in
                    if !isPresented {
                        state.wrappedValue = .hidden
                    }
                }
            )
        ) {
            TextField(l("bookmarks.collections.new.placeholder"), text: name)
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(title) {
                Task { await submit() }
            }
        } message: {
            if let error = state.wrappedValue.error {
                Text(error.localizedMessage)
            }
        }
    }
}
#endif
