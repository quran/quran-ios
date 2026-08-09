//
//  CrashContext.swift
//

import Locking

/// A low-cardinality snapshot of application state attached to subsequent crash reports.
///
/// Ordered transitions belong in logs. This type records only the latest committed state.
public final class CrashContext {
    // MARK: Lifecycle

    init(crasher: Crasher) {
        self.crasher = crasher
    }

    // MARK: Public

    public func setApplicationState(_ state: String) {
        set(state, forKey: .appState)
    }

    public func setProtectedDataAvailable(_ available: Bool) {
        set(available, forKey: .protectedDataAvailable)
    }

    public func setStartupPhase(_ phase: String) {
        set(phase, forKey: .startupPhase)
    }

    public func setScreen(_ screen: String) {
        set(screen, forKey: .uiScreen)
    }

    public func setOverlay(_ overlay: String) {
        set(overlay, forKey: .uiOverlay)
    }

    public func setSelectedTab(_ tab: String) {
        set(tab, forKey: .uiSelectedTab)
    }

    public func setNavigationPhase(_ phase: String) {
        set(phase, forKey: .uiNavigationPhase)
    }

    public func setReading(id: String) {
        set(id, forKey: .readingId)
    }

    public func setQuranMode(_ mode: String, selectedTranslationCount: Int) {
        set(mode, forKey: .quranMode)
        set(selectedTranslationCount, forKey: .selectedTranslationCount)
    }

    public func setSyncState(_ state: String) {
        set(state, forKey: .syncState)
    }

    public func setPager(
        generation: Int,
        phase: String,
        source: String,
        visibleItem: String,
        targetItem: String,
        pendingItem: String,
        gestureState: String
    ) {
        set(generation, forKey: .pagerTransitionGeneration)
        set(phase, forKey: .pagerPhase)
        set(source, forKey: .pagerTransitionSource)
        set(visibleItem, forKey: .pagerVisibleItem)
        set(targetItem, forKey: .pagerTargetItem)
        set(pendingItem, forKey: .pagerPendingItem)
        set(gestureState, forKey: .pagerGestureState)
    }

    public func setActiveList(
        owner: String,
        mode: String,
        generation: Int,
        sectionCount: Int,
        rowCount: Int
    ) {
        set(owner, forKey: .activeListOwner)
        set(mode, forKey: .activeListMode)
        set(generation, forKey: .activeListGeneration)
        set(sectionCount, forKey: .activeListSectionCount)
        set(rowCount, forKey: .activeListRowCount)
    }

    public func clearActiveList(owner: String) {
        let currentOwner: String? = value(forKey: .activeListOwner)
        guard currentOwner == owner else { return }
        set("none", forKey: .activeListOwner)
        set("none", forKey: .activeListMode)
        set(0, forKey: .activeListGeneration)
        set(0, forKey: .activeListSectionCount)
        set(0, forKey: .activeListRowCount)
    }

    public func recordListUpdate(
        owner: String,
        reason: String,
        rowsBefore: Int,
        rowsAfter: Int,
        generation: Int
    ) {
        set(owner, forKey: .lastListUpdateOwner)
        set(reason, forKey: .lastListUpdateReason)
        set(rowsBefore, forKey: .lastListRowsBefore)
        set(rowsAfter, forKey: .lastListRowsAfter)
        set(generation, forKey: .lastListUpdateGeneration)
    }

    public func setPresentation(owner: String, kind: String, phase: String, interactive: Bool) {
        set(owner, forKey: .presentationOwner)
        set(kind, forKey: .presentationKind)
        set(phase, forKey: .presentationPhase)
        set(interactive, forKey: .presentationInteractive)
    }

    public func clearPresentation(owner: String) {
        let currentOwner: String? = value(forKey: .presentationOwner)
        guard currentOwner == owner else { return }
        set("none", forKey: .presentationOwner)
        set("none", forKey: .presentationKind)
        set("idle", forKey: .presentationPhase)
        set(false, forKey: .presentationInteractive)
    }

    public func setPersistence(store: String, operation: String, phase: String, retryCount: Int = 0) {
        set(store, forKey: .persistenceStore)
        set(operation, forKey: .persistenceOperation)
        set(phase, forKey: .persistencePhase)
        set(retryCount, forKey: .persistenceRetryCount)
    }

    public func setAudioState(_ state: String) {
        set(state, forKey: .audioState)
    }

    public func setAudioReciter(id: Int?) {
        set(id.map(String.init) ?? "none", forKey: .audioReciterId)
    }

    public func setPlayingAyah(sura: Int, ayah: Int) {
        set(sura, forKey: .audioPlayingSura)
        set(ayah, forKey: .audioPlayingAyah)
    }

    public func clearPlayingAyah() {
        set(0, forKey: .audioPlayingSura)
        set(0, forKey: .audioPlayingAyah)
    }

    public func setVisiblePages(_ pages: [Int]) {
        set(pages.min() ?? 0, forKey: .quranVisiblePageMinimum)
        set(pages.max() ?? 0, forKey: .quranVisiblePageMaximum)
        set(pages.count, forKey: .quranVisiblePageCount)
    }

    public func setAdvancedAudioOptionsPhase(_ phase: String) {
        set(phase, forKey: .advancedAudioOptionsPhase)
    }

    // MARK: Private

    private let crasher: Crasher
    private let values = Protected<[String: AnyHashable]>([:])

    private func set<T: Hashable>(_ value: T, forKey key: CrasherKey<T>) {
        let changed = values.sync { values in
            guard values[key.key] != AnyHashable(value) else { return false }
            values[key.key] = AnyHashable(value)
            return true
        }
        if changed {
            crasher.setValue(value, forKey: key)
        }
    }

    private func value<T: Hashable>(forKey key: CrasherKey<T>) -> T? {
        values.value[key.key]?.base as? T
    }
}

public let crashContext = CrashContext(crasher: crasher)

private extension CrasherKeyBase {
    static let appState = CrasherKey<String>(key: "app_state")
    static let protectedDataAvailable = CrasherKey<Bool>(key: "protected_data_available")
    static let startupPhase = CrasherKey<String>(key: "startup_phase")

    static let uiScreen = CrasherKey<String>(key: "ui_screen")
    static let uiOverlay = CrasherKey<String>(key: "ui_overlay")
    static let uiSelectedTab = CrasherKey<String>(key: "ui_selected_tab")
    static let uiNavigationPhase = CrasherKey<String>(key: "ui_navigation_phase")

    static let readingId = CrasherKey<String>(key: "reading_id")
    static let quranMode = CrasherKey<String>(key: "quran_mode")
    static let selectedTranslationCount = CrasherKey<Int>(key: "selected_translation_count")
    static let syncState = CrasherKey<String>(key: "sync_state")

    static let pagerPhase = CrasherKey<String>(key: "pager_phase")
    static let pagerTransitionGeneration = CrasherKey<Int>(key: "pager_transition_generation")
    static let pagerTransitionSource = CrasherKey<String>(key: "pager_transition_source")
    static let pagerVisibleItem = CrasherKey<String>(key: "pager_visible_item")
    static let pagerTargetItem = CrasherKey<String>(key: "pager_target_item")
    static let pagerPendingItem = CrasherKey<String>(key: "pager_pending_item")
    static let pagerGestureState = CrasherKey<String>(key: "pager_gesture_state")

    static let activeListOwner = CrasherKey<String>(key: "active_list_owner")
    static let activeListMode = CrasherKey<String>(key: "active_list_mode")
    static let activeListGeneration = CrasherKey<Int>(key: "active_list_generation")
    static let activeListSectionCount = CrasherKey<Int>(key: "active_list_section_count")
    static let activeListRowCount = CrasherKey<Int>(key: "active_list_row_count")
    static let lastListUpdateOwner = CrasherKey<String>(key: "last_list_update_owner")
    static let lastListUpdateReason = CrasherKey<String>(key: "last_list_update_reason")
    static let lastListRowsBefore = CrasherKey<Int>(key: "last_list_rows_before")
    static let lastListRowsAfter = CrasherKey<Int>(key: "last_list_rows_after")
    static let lastListUpdateGeneration = CrasherKey<Int>(key: "last_list_update_generation")

    static let presentationOwner = CrasherKey<String>(key: "presentation_owner")
    static let presentationKind = CrasherKey<String>(key: "presentation_kind")
    static let presentationPhase = CrasherKey<String>(key: "presentation_phase")
    static let presentationInteractive = CrasherKey<Bool>(key: "presentation_interactive")

    static let persistenceStore = CrasherKey<String>(key: "persistence_store")
    static let persistenceOperation = CrasherKey<String>(key: "persistence_operation")
    static let persistencePhase = CrasherKey<String>(key: "persistence_phase")
    static let persistenceRetryCount = CrasherKey<Int>(key: "persistence_retry_count")

    static let audioState = CrasherKey<String>(key: "audio_state")
    static let audioReciterId = CrasherKey<String>(key: "audio_reciter_id")
    static let audioPlayingSura = CrasherKey<Int>(key: "audio_playing_sura")
    static let audioPlayingAyah = CrasherKey<Int>(key: "audio_playing_ayah")
    static let advancedAudioOptionsPhase = CrasherKey<String>(key: "advanced_audio_options_phase")

    static let quranVisiblePageMinimum = CrasherKey<Int>(key: "quran_visible_page_minimum")
    static let quranVisiblePageMaximum = CrasherKey<Int>(key: "quran_visible_page_maximum")
    static let quranVisiblePageCount = CrasherKey<Int>(key: "quran_visible_page_count")
}
