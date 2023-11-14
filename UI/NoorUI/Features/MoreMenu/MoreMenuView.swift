//
//  MoreMenuLandingView.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIKit
import UIx

public struct MoreMenuView: View {
    // MARK: Lifecycle

    public init(store: MoreMenuStore) {
        self.store = store
    }

    // MARK: Public

    public var body: some View {
        CocoaNavigationView(rootConfiguration: .init(navigationBarHidden: true)) {
            MoreMenuRootView(store: store)
        }
    }

    // MARK: Private

    @ObservedObject private var store: MoreMenuStore
}

private struct MoreMenuRootView: View {
    // MARK: Internal

    @ObservedObject var store: MoreMenuStore
    @Environment(\.navigator) var navigator: Navigator?

    var body: some View {
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack(spacing: 0) {
                    viewBasedOn(state.mode) {
                        MoreMenuModeSelector(mode: $store.mode)
                    }

                    viewBasedOn(state.translationsSelection, customCondition: store.mode == .translation) {
                        Button {
                            store.selectTranslation?()
                        } label: {
                            MoreMenuTranslationSelector()
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(BackgroundHighlightingStyle())
                        .background(Color.systemBackground)

                        empty
                    }

                    viewBasedOn(state.wordPointer, customCondition: store.mode == .arabic) {
                        MoreMenuWordPointer(enabled: $store.wordPointerEnabled)
                            .background(Color.systemBackground)
                        if store.wordPointerEnabled {
                            divider
                                .background(Color.systemBackground)
                            Button {
                                showWordPointerSelection()
                            } label: {
                                MoreMenuWordPointerType(type: store.wordPointerType)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(BackgroundHighlightingStyle())
                            .background(Color.systemBackground)
                        }
                        empty
                    }

                    viewBasedOn(state.orientation, customCondition: store.mode == .arabic) {
                        MoreMenuDeviceRotation()
                            .background(Color.systemBackground)
                        empty
                    }

                    viewBasedOn(state.fontSize, customCondition: store.mode == .translation) {
                        MoreMenuFontSize(label: l("menu.arabicFontSize"), fontSize: $store.arabicFontSize)
                            .background(Color.systemBackground)
                        MoreMenuFontSize(label: l("menu.translationFontSize"), fontSize: $store.translationFontSize)
                            .background(Color.systemBackground)

                        // TODO: workaround to remove the empty space in the translation verse view
                        if state.fontSize != .alwaysOn {
                            empty
                        }
                    }

                    viewBasedOn(state.twoPages) {
                        MoreMenuTwoPages(enabled: $store.twoPagesEnabled)
                            .background(Color.systemBackground)
                        empty
                    }

                    viewBasedOn(state.verticalScrolling) {
                        MoreMenuVerticalScrolling(enabled: $store.verticalScrollingEnabled)
                    }

                    viewBasedOn(state.theme) {
                        ThemeSelector(theme: $store.theme)
                            .background(Color.systemBackground)
                    }
                }
            }
        }
    }

    // MARK: Private

    private var state: MoreMenuControlsState {
        store.state
    }

    private var empty: some View {
        VStack {
            MoreMenuEmpty()
        }
    }

    private var divider: some View {
        Divider()
            .padding(.leading)
    }

    @ViewBuilder
    private func viewBasedOn(
        _ state: ConfigState,
        customCondition: Bool = true,
        @ViewBuilder content: () -> some View
    ) -> some View {
        switch state {
        case .alwaysOff:
            EmptyView()
        case .alwaysOn:
            content()
        case .custom:
            if customCondition {
                content()
            }
        }
    }

    private func showWordPointerSelection() {
        navigator?.push(configuration: .init(backgroundColor: .systemBackground)) {
            WordPointerSelection(store: store)
        }
    }
}

private struct WordPointerSelection: View {
    // MARK: Internal

    @ObservedObject var store: MoreMenuStore
    @Environment(\.navigator) var navigator: Navigator?

    var body: some View {
        SingleChoiceSelectorView(
            sections: [SingleChoiceSection(items: [MoreMenu.TranslationPointerType.translation, .transliteration])],
            selected: selected,
            itemText: itemText(of:)
        )
    }

    // MARK: Private

    private var selected: Binding<MoreMenu.TranslationPointerType?> {
        Binding(get: {
            store.wordPointerType
        }, set: { value in
            if let value {
                store.wordPointerType = value
                navigator?.pop()
            }
        })
    }

    private func itemText(of item: MoreMenu.TranslationPointerType) -> String {
        // TODO: This code is repeated.
        switch item {
        case .translation:
            return l("translation.text-type.translation")
        case .transliteration:
            return l("translation.text-type.transliteration")
        }
    }
}
