//
//  SelectedTranslationsPreferences.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation
import Preferences

public protocol SelectedTranslationsPreferences {
    var selectedTranslations: [Int] { get }
    func isSelected(_ translationId: Int) -> Bool
}

public protocol WriteableSelectedTranslationsPreferences: AnyObject, SelectedTranslationsPreferences {
    var selectedTranslations: [Int] { get set }
    func toggleSelection(_ translationId: Int)
}

public class DefaultsSelectedTranslationsPreferences: WriteableSelectedTranslationsPreferences {
    private static let selectedTranslations = PreferenceKey<[Int]>(key: "selectedTranslations", defaultValue: [])

    public init() {}

    @Preference(selectedTranslations)
    public var selectedTranslations: [Int]

    public func isSelected(_ translationId: Int) -> Bool {
        selectedTranslations.contains(translationId)
    }

    public func toggleSelection(_ translationId: Int) {
        if let index = selectedTranslations.firstIndex(of: translationId) {
            selectedTranslations.remove(at: index)
        } else {
            selectedTranslations.append(translationId)
        }
    }
}
