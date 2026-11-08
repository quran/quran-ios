//
//  ToastQueue.swift
//
//
//  Created by Mohamed Afifi on 2026-11-08.
//

import Foundation

/// The toasts waiting to show, in order, the showing one first, each with the scene it shows in.
struct ToastQueue<Scene> {
    struct Entry {
        let toast: Toast
        let scene: Scene
    }

    /// The entry on screen, from when `showNext()` returns it until `removeShowing()`.
    var showing: Entry? {
        isShowing ? entries.first : nil
    }

    mutating func append(_ toast: Toast, in scene: Scene) {
        entries.append(Entry(toast: toast, scene: scene))
    }

    /// The entry to show next, now showing, or `nil` while one shows or none waits.
    mutating func showNext() -> Entry? {
        guard !isShowing, let next = entries.first else {
            return nil
        }
        isShowing = true
        return next
    }

    /// Removes the showing entry once it's off screen, so the next one can show.
    mutating func removeShowing() {
        guard isShowing else {
            return
        }
        entries.removeFirst()
        isShowing = false
    }

    /// Drops the waiting toast with `id`, and returns whether the showing toast has `id` instead.
    /// The showing toast stays until its presenter dismisses it and calls `removeShowing()`.
    mutating func removeToast(id: UUID) -> Bool {
        let firstWaiting = isShowing ? 1 : 0
        entries[firstWaiting...].removeAll { $0.toast.id == id }
        return showing?.toast.id == id
    }

    // MARK: Private

    private var entries: [Entry] = []
    private var isShowing = false
}
