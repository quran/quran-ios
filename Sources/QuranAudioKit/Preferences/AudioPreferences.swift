//
//  AudioPreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-12-14.
//

import Combine
import Foundation
import Preferences

public protocol SelectedReciterPreferences {
    var lastSelectedReciterId: Int { get }
}

public protocol WriteableSelectedReciterPreferences: AnyObject, SelectedReciterPreferences {
    var lastSelectedReciterId: Int { get set }
}

@available(iOS 13.0, *)
public class AudioPreferences: WriteableSelectedReciterPreferences {
    private static let lastSelectedReciterId = PreferenceKey<Int>(key: "LastSelectedQariId", defaultValue: 41)
    private static let audioEndKey = PreferenceKey<Int>(key: "audioEndKey", defaultValue: AudioEnd.juz.rawValue)

    @TransformedPreference(audioEndKey, transformer: .rawRepresentable(defaultValue: .juz))
    public var audioEnd: AudioEnd

    @Preference(lastSelectedReciterId)
    public var lastSelectedReciterId: Int

    public init() {}
}
