//
//  MoreMenuView.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import NoorUI
import QuranText
import SwiftUI
import UIKit
import UIx

struct MoreMenuView: View {
    @ObservedObject private var store: MoreMenuViewModel
    init(store: MoreMenuViewModel) {
        self.store = store
    }

    var body: some View {
        CocoaNavigationView(rootConfiguration: .init(navigationBarHidden: true)) {
            MoreMenuRootView(store: store)
        }
    }
}

private struct MoreMenuRootView: View {
    // MARK: Internal

    @ObservedObject var store: MoreMenuViewModel
    @Environment(\.navigator) var navigator: Navigator?

    var body: some View {
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack(spacing: 0) {
                    let groups = visibleGroups
                    ForEach(groups, id: \.self) { group in
                        if group != groups.first {
                            NoorMenuGroupSeparator()
                        }
                        content(of: group)
                    }
                }
            }
        }
    }

    // MARK: Private

    /// Each group is one section of the menu, like the sections of a native menu.
    private enum MenuGroup: CaseIterable {
        case mode
        case translations
        case wordPointer
        case linePageDisplay
        #if QURAN_SYNC
        case ayahIndicators
        #endif
        case orientation
        case twoPages
        case verticalScrolling
        case theme
    }

    private var state: MoreMenuControlsState {
        store.state
    }

    private var visibleGroups: [MenuGroup] {
        MenuGroup.allCases.filter { isVisible($0) }
    }

    private var showsTranslationsSelection: Bool {
        isVisible(state.translationsSelection, customCondition: store.mode == .translation)
    }

    private var showsArabicText: Bool {
        isVisible(state.arabicText, customCondition: store.mode == .translation)
    }

    private var showsFootnotes: Bool {
        isVisible(state.footnotes, customCondition: store.mode == .translation)
    }

    @ViewBuilder
    private func content(of group: MenuGroup) -> some View {
        switch group {
        case .mode:
            MoreMenuModeSelector(mode: $store.mode)

        case .translations:
            if showsTranslationsSelection {
                Button {
                    store.selectTranslations()
                } label: {
                    MoreMenuTranslationSelector()
                        .contentShape(Rectangle())
                }
                .buttonStyle(BackgroundHighlightingStyle())
            }
            if showsArabicText {
                MoreMenuArabicText(enabled: $store.showArabicText)
            }
            if showsFootnotes {
                MoreMenuFootnotes(enabled: $store.showFootnotes)
            }

        case .wordPointer:
            MoreMenuWordPointer(enabled: $store.wordPointerEnabled)
            if store.wordPointerEnabled {
                Button {
                    showWordPointerSelection()
                } label: {
                    MoreMenuWordPointerType(type: store.wordPointerType)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BackgroundHighlightingStyle())
            }

        case .linePageDisplay:
            MoreMenuLinePageDisplay(
                showDividers: $store.showLinePageDividers,
                showSidelines: $store.showLinePageSidelines
            )

        #if QURAN_SYNC
        case .ayahIndicators:
            MoreMenuAyahIndicators(visibility: $store.indicatorVisibility)
        #endif

        case .orientation:
            MoreMenuDeviceRotation()

        case .twoPages:
            MoreMenuTwoPages(enabled: $store.twoPagesEnabled)

        case .verticalScrolling:
            MoreMenuVerticalScrolling(enabled: $store.verticalScrollingEnabled)

        case .theme:
            MoreMenuThemeSettingsMenuItem(
                showFontSize: isVisible(state.fontSize, customCondition: store.mode == .translation),
                showArabicFontSize: store.showArabicText
            )
        }
    }

    private func isVisible(_ group: MenuGroup) -> Bool {
        switch group {
        case .mode: isVisible(state.mode)
        case .translations: showsTranslationsSelection || showsArabicText || showsFootnotes
        case .wordPointer: isVisible(state.wordPointer, customCondition: store.mode == .arabic)
        case .linePageDisplay: isVisible(state.linePageDisplay, customCondition: store.mode == .arabic)
        #if QURAN_SYNC
        case .ayahIndicators: isVisible(state.ayahIndicators)
        #endif
        case .orientation: isVisible(state.orientation, customCondition: store.mode == .arabic)
        case .twoPages: isVisible(state.twoPages)
        case .verticalScrolling: isVisible(state.verticalScrolling)
        case .theme: isVisible(state.theme)
        }
    }

    private func isVisible(_ state: ConfigState, customCondition: Bool = true) -> Bool {
        switch state {
        case .alwaysOff:
            return false
        case .alwaysOn:
            return true
        case .conditional:
            return customCondition
        }
    }

    private func showWordPointerSelection() {
        // From iOS 26, the page is clear so it stays on the popover's glass like the root page.
        // Earlier pushes slide two clear pages over each other, so it stays opaque there.
        let isTransparent = if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
        navigator?.push(configuration: .init(backgroundColor: isTransparent ? .clear : .systemBackground)) {
            WordPointerSelection(store: store, showsBackground: !isTransparent)
        }
    }
}

private struct WordPointerSelection: View {
    // MARK: Internal

    @ObservedObject var store: MoreMenuViewModel
    let showsBackground: Bool
    @Environment(\.navigator) var navigator: Navigator?

    var body: some View {
        SingleChoiceSelectorView(
            sections: [SingleChoiceSection(items: [WordTextType.translation, .transliteration])],
            selected: selected,
            showsBackground: showsBackground,
            itemText: { $0.localizedName }
        )
    }

    // MARK: Private

    private var selected: Binding<WordTextType?> {
        Binding(get: {
            store.wordPointerType
        }, set: { value in
            if let value {
                store.wordPointerType = value
                navigator?.pop()
            }
        })
    }
}
