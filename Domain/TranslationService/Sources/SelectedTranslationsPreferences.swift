//
//  SelectedTranslationsPreferences.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Preferences
import QuranText

public class SelectedTranslationsPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = SelectedTranslationsPreferences()

    @Preference(selectedTranslations)
    public var selectedTranslationIds: [Translation.ID]

    public func remove(_ translationId: Int) {
        if let index = selectedTranslationIds.firstIndex(of: translationId) {
            selectedTranslationIds.remove(at: index)
        }
    }

    public func isSelected(_ translationId: Translation.ID) -> Bool {
        selectedTranslationIds.contains(translationId)
    }

    public func toggleSelection(_ translationId: Translation.ID) {
        if let index = selectedTranslationIds.firstIndex(of: translationId) {
            selectedTranslationIds.remove(at: index)
        } else {
            selectedTranslationIds.append(translationId)
        }
    }

    public func select(_ id: Translation.ID) {
        if !selectedTranslationIds.contains(id) {
            selectedTranslationIds.append(id)
        }
    }

    public func deselect(_ id: Translation.ID) {
        if let index = selectedTranslationIds.firstIndex(of: id) {
            selectedTranslationIds.remove(at: index)
        }
    }

    public func selectedTranslations(from localTranslations: [Translation]) -> [Translation] {
        let selected = selectedTranslationIds
        let translationsById = Dictionary(uniqueKeysWithValues: localTranslations.map { ($0.id, $0) })
        return selected.compactMap { translationsById[$0] }
    }

    // MARK: Internal

    func reset() {
        Preferences.shared.removeValueForKey(Self.selectedTranslations)
    }

    // MARK: Private

    private static let selectedTranslations = PreferenceKey<[Translation.ID]>(key: "selectedTranslations", defaultValue: [])
}
