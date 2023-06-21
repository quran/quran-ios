//
//  ThemeSettingsService.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-03-03.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Combine
import Foundation
import NoorUI
import UIx
import VLogging

@MainActor
public final class ThemeSettingsService {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public let theme = ValueViewModel(Theme.dark)

    public func startObserving() {
        theme.value = themeService.theme
        themeService
            .themePublisher
            .receive(on: DispatchQueue.main)
            .sink { newValue in
                self.theme.value = newValue
            }
            .store(in: &cancellables)

        theme.$value
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newValue in
                logger.info("Theme: New theme selected \(newValue)")
                self?.themeService.theme = newValue
            }
            .store(in: &cancellables)
    }

    // MARK: Private

    private let themeService = ThemeService.shared

    private var cancellables: Set<AnyCancellable> = []
}
